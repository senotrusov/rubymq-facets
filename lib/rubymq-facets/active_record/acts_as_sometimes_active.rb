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


require 'rubymq-facets/more/check_is_active'

module ActiveRecord
  module Acts
    module SometimesActive
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        def acts_as_sometimes_active
          class_eval <<-END
            include CheckIsActive
          END
        end
      end
    end
  end
end

ActiveRecord::Base.class_eval do
  include ActiveRecord::Acts::SometimesActive
end
