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


# Эта штука корректно отрабатывает переподключения к базе, но зависит в этом вопросе от поведения ActiveRecord
# Неплохо бы для этого сделать unit test
# Not thread safe, but works in one connection per thread env

class ActiveRecord::ConnectionAdapters::NotListeningForEvent < StandardError; end

class ActiveRecord::ConnectionAdapters::PostgreSQLAdapter
  
  def configure_connection_with_listening
    configure_connection_without_listening

    @listening_for = {}
    @notifications = {}
    @notification_mutex = Mutex.new
  end
  
  alias_method_chain :configure_connection, :listening

  def was_happen? event
    @notification_mutex.synchronize do 
      begin
        return notified?(event)
      rescue ActiveRecord::ConnectionAdapters::NotListeningForEvent
        listen event
        return true
      end
    end
  end

  private

    def listen event
      @listening_for[event] = true
      execute("LISTEN \"#{event}\"")
    end
    
    def listening? event
      @listening_for[event]
    end
    
    def notified? event
      raise ActiveRecord::ConnectionAdapters::NotListeningForEvent unless listening?(event)
      
      while incoming = raw_connection.get_notify do
        @notifications[incoming[0]] = incoming[1]   
      end
      
      return @notifications.delete(event)
    end

end
