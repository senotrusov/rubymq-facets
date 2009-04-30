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
 

class ThreadWaiter
  def initialize
    @mutex = Mutex.new
    @condition = ConditionVariable.new
  end
  
  def wait
    @mutex.synchronize do
      @condition.wait(@mutex)
    end
  end
  
  def signal
    @mutex.synchronize do
      @condition.signal
    end
  end

  def broadcast
    @mutex.synchronize do
      @condition.broadcast
    end
  end
end
