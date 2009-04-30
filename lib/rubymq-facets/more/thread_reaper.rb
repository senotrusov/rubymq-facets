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
 
require 'rubymq-facets/core/thread'

class ThreadReaper
  def initialize(logger, exit_status = 1)
    @logger = logger
    @queue = Queue.new
    @thread = Thread.new_with_exception_handling(@logger, lambda { Process.exit!(exit_status) }) {thread}
  end
  
  def terminate
    @queue.push nil
  end
  
  def join
    @thread.join
  end
  
  def push victim, reason
    @queue.push [victim, reason]
  end
  
  private

  def thread
    while (duty = @queue.shift)
      victim, reason = duty
      
      if victim.respond_to?(:reaped)
        if victim.reaped
          next
        else
          victim.reaped = true
        end
      end
      
      victim.terminate
      victim.join
      
      @logger.debug "#{victim.respond_to?(:name) ? victim.name : victim.inspect} reaped for #{reason}"
    end
  end
end
