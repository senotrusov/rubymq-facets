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


class Integer
  BASE_62_SYMBOLS = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789".split('')
  
  def to_s_base62
    return BASE_62_SYMBOLS.first if self == 0
    
    i = self
    result = ''
    
    while i > 0
      result = BASE_62_SYMBOLS[i.modulo(62)] + result
      i = i / 62
    end
    
    return result
  end
end

# 10000.times {|i| puts i.to_s_base62}
