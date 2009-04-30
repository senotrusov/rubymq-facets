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


class String
  def to_hex_view
    view = []
    (0...length).each {|i| view << sprintf("%02X", self[i])}
    view.join(' ')
  end

  def to_bin_view
    view = []
    (0...length).each {|i| view << sprintf("%08b", self[i])}
    view.join(' ')
  end
end
