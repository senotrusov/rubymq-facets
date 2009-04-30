# 
#  Copyright 2006-2008 Stanislav Senotrusov <senotrusov@gmail.com>
# 
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
# 
#      http://www.apache.org/licenses/LICENSE-2.0
# 
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.


# TODO: cache purging
# TODO: thread safe (need use cases and solutions)
#       Postgresql sequence to increment on each change, so threads may coordinate their reloadings to not multiple reload the same data.
#       Each thread must have a personal copy of cache to be sure it won't magically changed in the middle of work.   

# Надо помнить, что в ActiveRecord загрузка ассоциций lazy настолько, что просто тыкнув в has_many или habtm ассоциацию
# вы её не подгрузите. Надо делать ей (true), first, [] или что-то подобное, чтобы она действительно подгрузилась. 


module CachedConfig
  STORAGES = {}
  MUTEX = Mutex.new

  class NotLoaded < StandardError; end

  class Storage < Array
    attr_reader :lock, :mutex

    def initialize model, event_name
      @model = model
      @event_name = event_name
      
      @lock = ThreadLock.new
      @mutex = Mutex.new
      
      @need_reload = false
    end
    
    def need_reload!
      @need_reload = true
    end

    def need_reload?
      noticed = @model.connection.respond_to?(:was_happen?) && @model.connection.was_happen?(@event_name)
      need_reload = @need_reload ? (@need_reload = false; true) : false

      return noticed || need_reload
    end

    def reload
      @model.transaction do
        @model.connection.execute('SET TRANSACTION ISOLATION LEVEL SERIALIZABLE') # This statement may lead to error in some if databases what fall behind standarts. Uncomment this line if needed. if @model.connection.kind_of?(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter)
  
        self.each { |cache| cache.call_reload }
      end
    end
  end

  def self.register_config config_object 
    model, event_name = config_object.listening_for_event
    
    MUTEX.synchronize do
      STORAGES[event_name] ||= Storage.new(model, event_name)
      STORAGES[event_name].push config_object
      STORAGES[event_name].need_reload!
      STORAGES[event_name]
    end
  end
  
  def self.unregister_config config_object
    model, event_name = config_object.listening_for_event
    
    MUTEX.synchronize do
      STORAGES[event_name].delete config_object
      STORAGES.delete(event_name) if STORAGES[event_name].empty?
    end
  end
  
  class Cache
    include DefaultLoggerAccessor
    
    class_inheritable_accessor :listening_for_event
    
    def self.listen_for_event model, event_name
      self.listening_for_event = model, event_name
    end
    
    def initialize args = {}
      @after_reload = args[:after_reload]
      @storage = CachedConfig.register_config(self)
      @data = nil
      @mutex = Mutex.new
    end
    
    def stop_listening
      CachedConfig.unregister_config(self)
    end
  
    # You can call "use" again inside the block. In that case nested config.use will never asquire exclusive lock, thus never reloads.
    def use
      reload_if_needed
      
      raise(@exception) if @exception
      
      @storage.lock.shared {yield}
    end
    
    def reload_if_needed
      begin
        if @storage.mutex.synchronize { @storage.need_reload? }
          @storage.lock.exclusive do
            @storage.reload
          end
        end
      rescue NestingThreadLockError
        @storage.mutex.synchronize { @storage.need_reload! }
      end
    end
    
    def exclusive(&block)
      @storage.lock.exclusive(&block)
    end

    def exclusive?
      @storage.lock.exclusive?
    end

    def call_reload
      begin
        logger.debug "#{self.class}#call_reload: Reloading..."

        reload
        
        @after_reload.call(*[self][0,@after_reload.arity]) if @after_reload
        
        logger.debug "#{self.class}#call_reload: Reloaded."

        @exception = nil

      rescue Exception => exception
        begin
          @exception = exception
        ensure
          raise exception unless exception.kind_of?(StandardError) || exception.kind_of?(ScriptError)
        end
      end
      true
    end

    def [] key
      @mutex.synchronize do
        raise CachedConfig::NotLoaded unless @data
        @data[key]
      end
    end
  
    def []= key, value
      @mutex.synchronize do
        raise CachedConfig::NotLoaded unless @data
        @data[key] = value
      end
    end
  end  
end