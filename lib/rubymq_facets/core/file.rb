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


class File
  def self.write filename, content
    File.open(filename, 'wb') do |file|
      file.write content
    end
  end
  def self.append filename, content
    File.open(filename, 'ab') do |file|
      file.write content
    end
  end

  def self.expand_path_restricted(file_name, dir_string, restrict_dir_string = nil)
    dir_string = expand_path(dir_string)
    restrict_dir_string = restrict_dir_string ? expand_path(restrict_dir_string) : dir_string

    expanded = expand_path(file_name, dir_string)

    unless expanded.index(restrict_dir_string) == 0
      raise "Restricted file path #{file_name.inspect} must be inside #{restrict_dir_string.inspect}"
    end
    
    expanded
  end
end