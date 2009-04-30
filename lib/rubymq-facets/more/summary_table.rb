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


class SummaryTable
  def initialize
    @column_defs = []
    @row_defs = []
  end
  
  def push_column_definitions name, list
    @column_defs << {:name => name, :list => list}
  end
  
  def push_row_definitions name, list
    @row_defs << {:name => name, :list => list}
  end
  
  def data= dta
    @data = dta
  end
  
  def render
    @rendered = '<table class="data">'
    
    @rendered << "<tr>"
      @rendered << "<th></th>"
  
      for column_def in @column_defs.first[:list] do
        @rendered << "<th>#{column_def.title}</th>"
      end
    @rendered << "</tr>"
    
    for row_def in @row_defs.first[:list] do
      @rendered << "<tr><td>#{row_def.title}</td>"
        for column_def in @column_defs.first[:list] do
          found = @data.detect {|item| item.send(@row_defs.first[:name]) == row_def && item.send(@column_defs.first[:name]) == column_def}
          @rendered << "<td class=\"#{found ? "ok" : ""}\">#{found ? found.title : "&nbsp;"}</td>"
        end
      @rendered << "</tr>"
    end
    
    @rendered << "</table>"
    
    return @rendered
  end
end