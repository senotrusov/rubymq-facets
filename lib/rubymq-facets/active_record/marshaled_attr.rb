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


require 'rubymq-facets/more/accessors_generator'

module MarshaledAttr
  include AccessorsGenerator
  
  def marshaled_attr(*args)
    generate_accessors(args) do |attr, default_class|
      marshaled_attrs << attr if respond_to? :marshaled_attrs
      
      {:line => (__LINE__+1), :file => __FILE__, :code => <<-EOS
          def #{attr}
            @#{attr} ||= (#{attr}_marshaled ? Marshal.restore(#{attr}_marshaled) : #{default_class ? "#{default_class}.new" : "nil"})

          rescue ArgumentError => argument_error
            if argument_error.message =~ /undefined class\\\/module ([\\\w:]*\\\w)/
              $1.constantize
              retry
            else
              raise argument_error
            end
          end
          
          def #{attr}= value
            @#{attr}= value
          end

          def drop_restored_#{attr}
            remove_instance_variable(:@#{attr}) if defined? @#{attr}
          end
          
          def #{attr}_restored?
            defined? @#{attr}
          end
          
          def #{attr}_marshaled_with_drop_restored= value
            #{attr}_drop_restored
            self.#{attr}_marshaled = value
          end

          def marshal_#{attr}
            self.#{attr}_marshaled = Marshal.dump(@#{attr}) if defined? @#{attr}
          end
          before_save :marshal_#{attr} if respond_to? :before_save
        EOS
      }
    end
  end
end

ActiveRecord::Base.extend MarshaledAttr

class ActiveRecord::Base
  class_inheritable_accessor :marshaled_attrs

  self.marshaled_attrs = []
  
  def reload_with_drop_restored(*options)
    reload_without_drop_restored(*options)
    marshaled_attrs.each {|attr| send "drop_restored_#{attr}"}
  end
  
  alias_method_chain :reload, :drop_restored
end
