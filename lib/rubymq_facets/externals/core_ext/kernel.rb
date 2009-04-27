#
# derived from merbivore.com
# The only modification is stripping of Merb-specific methods.

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

#
#  Copyright (c) 2008 Ezra Zygmuntowicz
#
#  Permission is hereby granted, free of charge, to any person obtaining
#  a copy of this software and associated documentation files (the
#  "Software"), to deal in the Software without restriction, including
#  without limitation the rights to use, copy, modify, merge, publish,
#  distribute, sublicense, and/or sell copies of the Software, and to
#  permit persons to whom the Software is furnished to do so, subject to
#  the following conditions:
#
#  The above copyright notice and this permission notice shall be
#  included in all copies or substantial portions of the Software.
#
#  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
#  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
#  MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
#  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
#  LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
#  OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
#  WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


module Kernel
  # ==== Parameters
  # i<Fixnum>:: The caller number. Defaults to 1.
  #
  # ==== Returns
  # Array[Array]:: The file, line and method of the caller.
  #
  # ==== Examples
  #   __caller_info__(1)
  #     # => ['/usr/lib/ruby/1.8/irb/workspace.rb', '52', 'irb_binding']
  def __caller_info__(i = 1)
    file, line, meth = caller[i].scan(/(.*?):(\d+):in `(.*?)'/).first
  end

  # ==== Parameters
  # file<String>:: The file to read.
  # line<Fixnum>:: The line number to look for.
  # size<Fixnum>::
  #   Number of lines to include above and below the the line to look for.
  #   Defaults to 4.
  #
  # ==== Returns
  # Array[Array]::
  #   Triplets containing the line number, the line and whether this was the
  #   searched line.
  #
  # ==== Examples
  #  __caller_lines__('/usr/lib/ruby/1.8/debug.rb', 122, 2) # =>
  #   [
  #     [ 120, "  def check_suspend",                               false ],
  #     [ 121, "    return if Thread.critical",                     false ],
  #     [ 122, "    while (Thread.critical = true; @suspend_next)", true  ],
  #     [ 123, "      DEBUGGER__.waiting.push Thread.current",      false ],
  #     [ 124, "      @suspend_next = false",                       false ]
  #   ]
  def __caller_lines__(file, line, size = 4)
    return [['Template Error!', "problem while rendering", false]] if file =~ /\(erubis\)/
    lines = File.readlines(file)
    current = line.to_i - 1

    first = current - size
    first = first < 0 ? 0 : first

    last = current + size
    last = last > lines.size ? lines.size : last

    log = lines[first..last]

    area = []

    log.each_with_index do |line, index|
      index = index + first + 1
      area << [index, line.chomp, index == current + 1]
    end

    area
  end

  # Takes a block, profiles the results of running the block
  # specified number of times and generates HTML report.
  #
  # ==== Parameters
  # name<~to_s>::
  #   The file name. The result will be written out to
  #   Merb.root/"log/#{name}.html".
  # min<Fixnum>::
  #   Minimum percentage of the total time a method must take for it to be
  #   included in the result. Defaults to 1.
  #
  # ==== Returns
  # String:: The result of the profiling.
  #
  # ==== Notes
  # Requires ruby-prof (<tt>sudo gem install ruby-prof</tt>)
  #
  # ==== Examples
  #   __profile__("MyProfile", 5, 30) do
  #     rand(10)**rand(10)
  #     puts "Profile run"
  #   end
  #
  # Assuming that the total time taken for #puts calls was less than 5% of the
  # total time to run, #puts won't appear in the profile report.
  # The code block will be run 30 times in the example above.
  def __profile__(name, min=1, iter=100)
    require 'ruby-prof' unless defined?(RubyProf)
    return_result = ''
    result = RubyProf.profile do
      iter.times{return_result = yield}
    end
    printer = RubyProf::GraphHtmlPrinter.new(result)
    path = File.join(Merb.root, 'log', "#{name}.html")
    File.open(path, 'w') do |file|
     printer.print(file, {:min_percent => min,
                          :print_file => true})
    end
    return_result
  end

  # Extracts an options hash if it is the last item in the args array. Used
  # internally in methods that take *args.
  #
  # ==== Parameters
  # args<Array>:: The arguments to extract the hash from.
  #
  # ==== Examples
  #   def render(*args,&blk)
  #     opts = extract_options_from_args!(args) || {}
  #     # [...]
  #   end
  def extract_options_from_args!(args)
    args.pop if Hash === args.last
  end

  # Checks that the given objects quack like the given conditions.
  #
  # ==== Parameters
  # opts<Hash>::
  #   Conditions to enforce. Each key will receive a quacks_like? call with the
  #   value (see Object#quacks_like? for details).
  #
  # ==== Raises
  # ArgumentError:: An object failed to quack like a condition.
  def enforce!(opts = {})
    opts.each do |k,v|
      raise ArgumentError, "#{k.inspect} doesn't quack like #{v.inspect}" unless k.quacks_like?(v)
    end
  end
end
