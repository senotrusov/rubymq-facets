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

module ConstantAccessor
  include AccessorsGenerator
  
  def constant_attr(*args)
    generate_accessors(args) do |attr, value|
      {:line => (__LINE__+1), :file => __FILE__, :code => <<-EOS
          def #{attr}
            begin
              @#{attr} ||= #{value} ? #{value}.constantize : #{value}
            rescue NameError => exception
              raise(NameError, "Cant load class '\#{#{value}}' used in \#{respond_to?(:technical_title) ? technical_title : "\#{self.class}\#{self.id}"}")
            end
          end
        EOS
      }
    end
  end
end

ActiveRecord::Base.extend ConstantAccessor
