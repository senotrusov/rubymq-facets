# 
#  Copyright 2007-2008 Stanislav Senotrusov <senotrusov@gmail.com>
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
 

module ArGtkBindings
  class ComboBox
    def initialize args = {}
      @data = args[:data]
      @allow_nil = args[:allow_nil] ? true : false

      @widget = Gtk::ComboBox.new(true)
      @widget.append_text(args[:allow_nil]) if args[:allow_nil]
      
      @data.each {|item| @widget.append_text(item.summary)}
      @widget.show_all

      if @container = args[:container]
        @container.add @widget
      end
    end
    
    def active
      if @allow_nil
        @widget.active < 1 ? nil : @data[@widget.active - 1]
      else
        @widget.active == -1 ? nil : @data[@widget.active]
      end
    end
  end
  
  class PredefinedComboBox
    def initialize widget
      @widget = widget
    end

    def active
      @widget.active == -1 ? nil : self.class::VALUES[@widget.active]
    end
  end
  
  class CheckboxArray
    def initialize args = {}
      @data = args[:data]
      @widgets = []
      
      @widget = Gtk::VBox.new(false, 2)

      @data.each do |item|
        item_widget = Gtk::CheckButton.new(item.summary)
        @widgets.push item_widget
        @widget.add item_widget
      end
        
      @widget.show_all

      if @container = args[:container]
        @container.add @widget
      end
    end

    def active
      result = []
      @widgets.each_with_index {|item, index| result.push(@data[index]) if item.active?}
      return result
    end
  end
end
