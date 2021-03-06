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


require 'socket'

# TODO: move into TCPSocket
class IOTimeoutError < IOError
end

# Not so nice, but have minimal amount of code to execute.
class TCPSocket
  def read_with_timeout length, timeout
    buffer = ""

    begin
      if IO.select([self], nil, nil, timeout * 0.7)
        buffer << readpartial(length - buffer.length)
      elsif block_given?
        yield
        if IO.select([self], nil, nil, timeout * 0.3)
          buffer << readpartial(length - buffer.length)
        else
          raise(IOTimeoutError, "#{timeout} seconds timeout waiting for all expected data")
        end
      else
        raise(IOTimeoutError, "#{timeout} seconds timeout waiting for all expected data")
      end
    end while buffer.length < length

    return buffer
  end
end
