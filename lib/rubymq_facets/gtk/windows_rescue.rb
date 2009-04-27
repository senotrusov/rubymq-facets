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
 

def windows_rescue(on_error = nil)
  begin
    yield
  rescue Exception => exception
    begin
      require 'rubymq_facets/gtk/windows_message_box'
      RubyMQ.logger.error(exception.inspect_with_backtrace)
      WindowsMessageBox.alert("Unhandled exception: #{exception.inspect_with_backtrace}")
    rescue Exception => nested_exception
      WindowsMessageBox.alert("Unhandled exception: #{exception.message}\n#{exception.backtrace.join("\n")}\n\nHandling exception: #{nested_exception.message}\n#{nested_exception.backtrace.join("\n")}")
    ensure
      begin
        sleep 0.5 # To give a some time for last look on interface state.
        on_error.call if on_error
        Process.exit!(1)
      rescue Exception => exception
        WindowsMessageBox.alert("On error exception: #{exception.message}")
      end
    end
  end
end

