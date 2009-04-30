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


module LambdaFilters
  include AccessorsGenerator
  
  def lambda_filter(*args)
    generate_accessors(args) do |attr, default_class|
      attr = attr.to_s
      {:line => (__LINE__+1), :file => __FILE__, :code => <<-EOS
          def register_#{attr} &#{attr}
            @#{attr.tableize} ||= []
            @#{attr.tableize} << #{attr}
          end
          
          def apply_#{attr.tableize} *values
            if defined? @#{attr.tableize}
              @#{attr.tableize}.each do |#{attr}|
                #{attr}.call(*values)
              end
            end
          end
        EOS
      }
    end
  end
end
