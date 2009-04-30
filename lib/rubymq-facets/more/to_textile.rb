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


class Hash
  def to_textile_recursively(level = 1)
    inject("") do |string, (key, value)|
      string += "#{"*" * level} *#{key}:* #{value.respond_to?(:to_textile_recursively) ? "\n" + value.to_textile_recursively(level + 1) : value.inspect + "\n"}"
    end
  end
end

class Array
  def to_textile_recursively(level = 1)
    inject("") do |string, value|
      string += "#{"#" * level} #{value.respond_to?(:to_textile_recursively) ? "\n" + value.to_textile_recursively(level + 1) : value.inspect + "\n"}"
    end
  end
end

# puts ({:A => "HELLO", :B => 123123123, :CCC => {:R1 => "RRRRR1", :R2 => "RRRRR2", :ARR => ["1A", "2B", "3C"]}}.to_textile_recursively)