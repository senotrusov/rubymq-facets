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
 

class GladeSplashLoader
  def initialize glade_file
    Gtk.queue do
      @splash = GladeXML.new(glade_file, nil, nil, nil, GladeXML::FILE) {|handler| method(handler)}
      @message = @splash["message"]
      @destroy_signal_handler = @splash["splash"].signal_connect("destroy") {on_window_destroy}
    end
  end
  
  def load(message)
    Gtk.queue do
      @message.text = message
    end
    yield
  end
  
  def done
    Gtk.queue do
      @splash["splash"].signal_handler_block @destroy_signal_handler
      @splash["splash"].destroy
    end
  end
  
  def on_window_destroy
    windows_rescue do
      Gtk.main_quit
    end
  end
end