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


module ActiveRecord
  module Acts
    module ScopeRestricted
      def self.included(base)
        base.extend(ActsAs)
      end

      module ActsAs
        def acts_as_scope_restricted name, scope_field = nil
          scope_field = name unless scope_field
          class_eval <<-END
            include ActiveRecord::Acts::ScopeRestricted::InstanceMethods
            extend ActiveRecord::Acts::ScopeRestricted::ClassMethods

            def self.find_#{name} restriction, *args
              find_scope_restricted(:#{scope_field}, restriction, *args)
            end
          END
        end
      end
      
      module ClassMethods
        def find_scope_restricted scope_field, restriction, *args
          found = find(*args)
          restriction = restriction.kind_of?(ActiveRecord::Base) ? restriction.id : restriction

          if found.kind_of?(Array)
            found.each {|item| item.check_scope_restricted(scope_field, restriction, args)}
          else
            found.check_scope_restricted(scope_field, restriction, args)
          end

          return found
        end
      end

      module InstanceMethods
        def check_scope_restricted(scope_field, restriction, args)
          raise(SecurityError, "Access denied to #{self.class.to_s} with conditions #{args.inspect}") if self.send(scope_field) != restriction
        end
        
      end 
    end
  end
end

ActiveRecord::Base.class_eval do
  include ActiveRecord::Acts::ScopeRestricted
end
