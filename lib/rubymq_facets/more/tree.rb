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


class Tree < Array
  def initialize(array, parent = nil)
    @node = parent
    array.each do |item|
      if (parent == nil && item.parent_id == nil) || (parent != nil && item.parent_id == parent.id)
        leaf = Tree.new(array, item)
        push leaf.empty? ? item : leaf
      end
    end
  end
  attr_reader :node
end