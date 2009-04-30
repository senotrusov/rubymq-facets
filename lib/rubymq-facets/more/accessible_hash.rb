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


class AccessibleHash < Hash
  def initialize obj = nil
    if obj.kind_of? Hash
      self.merge! obj
    else
      super
    end
  end
  
  def method_missing method_name, value = nil
    if method_name.to_s[-1,1] == '='
      self[method_name.to_s[0..-2].to_sym] = value
    else
      self[method_name]
    end
  end
  
  def id
    self[:id]
  end
  
  def id= value
    self[:id] = value
  end
end