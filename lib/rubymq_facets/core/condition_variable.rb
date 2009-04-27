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


require 'thread'

class ConditionVariable
  def wait_until(mutex)
    begin
      wait(mutex)
    end until yield
  end
  
  def wait_while(mutex)
    begin
      wait(mutex)
    end while yield
  end

  def wait_and_broadcast_on_timeout(mutex, timeout)
    broadcaster = Thread.new do
      sleep timeout
      broadcast
    end
    wait(mutex)
    broadcaster.terminate
  end
end
