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


class PrioritizedQueue
  def initialize
    @mutex = Mutex.new
    @arrived = ConditionVariable.new
    
    @regular = []
    @priority = []
  end
  
  def push message
    @mutex.synchronize do
      @regular.push message
      @arrived.signal
    end
  end
  
  def priority_push message
    @mutex.synchronize do
      @priority.push message
      @arrived.signal
    end
  end
  
  def shift
    @mutex.synchronize do
      @arrived.wait(@mutex) if @priority.empty? && @regular.empty?
      
      @priority.empty? ? @regular.shift : @priority.shift
    end
  end
end
