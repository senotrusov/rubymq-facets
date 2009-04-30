#
# derived from ActiveSupport::BufferedLogger (rubyonrails.org) and exception_logger (techno-weenie.net)
 
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


#  Copyright (c) 2005-2007 David Heinemeier Hansson
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


# Copyright (c) 2005 Rick Olson
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of 
# this software and associated documentation files (the "Software"), to deal in 
# the Software without restriction, including without limitation the rights to 
# use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of 
# the Software, and to permit persons to whom the Software is furnished to do so, 
# subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all 
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS 
# FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR 
# COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER 
# IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN 
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


# TODO: Может быть, стоит сделать объект поддерживающий метод write и его передавать стандартному логгеру?

require 'sqlite3'
require 'socket'
require 'pathname'

class StructuredLogger
  # Inspired by the buffered logger idea by Ezra
  module Severity
    DEBUG   = 0
    INFO    = 1
    WARN    = 2
    ERROR   = 3
    FATAL   = 4
    UNKNOWN = 5
  end
  include Severity

  MAX_BUFFER_SIZE = 1000

  # Silences the logger for the duration of the block.
  def silence(temporary_level = ERROR)
    begin
      old_logger_level, self.level = level, temporary_level
      yield self
    ensure
      self.level = old_logger_level
    end
  end

  attr_accessor :level
  attr_reader :auto_flushing
  attr_reader :buffer

  def self.configure_connection connection
    raw_connection = connection.respond_to?(:raw_connection) ? connection.raw_connection : connection
    
    # 3 minutes
    raw_connection.busy_timeout(3 * 60 * 1000)

    connection.execute("PRAGMA count_changes = 0;")
    connection.execute("PRAGMA synchronous = OFF;")
    
    unless connection.execute("SELECT name FROM sqlite_master WHERE type='table' AND name = 'event_logs'").length == 1
      connection.execute('PRAGMA encoding = "UTF-8";')
      connection.execute "CREATE TABLE event_logs (
        id INTEGER PRIMARY KEY,
        exception_class TEXT, 
        controller_name TEXT, 
        action_name TEXT, 
        message TEXT, 
        backtrace TEXT, 
        environment TEXT, 
        request TEXT, 
        created_at TIMESTAMP, 
        severity INTEGER
        );
      "
    end
  end
  
  def initialize(log, level = DEBUG, default_progname = "unknown")
    @level         = level
    @buffer        = []
    @auto_flushing = 1
    @default_progname = default_progname
    
    @log = SQLite3::Database.new(log)
    @log.results_as_hash = true
    
    self.class.configure_connection @log
    
    @insert = @log.prepare( "INSERT INTO event_logs (exception_class, controller_name, action_name, message, backtrace, environment, request, created_at, severity) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)" )
  end
  
  attr_accessor :show_log_on_stdout

  @@pid = Process.pid
  @@hostname = Socket.gethostname
#  @@rails_root      = Pathname.new(RAILS_ROOT).cleanpath.to_s
#  @@backtrace_regex = /^#{Regexp.escape(@@rails_root)}/

  def sanitize_backtrace(trace)
#    trace.collect { |line| Pathname.new(line.gsub(@@backtrace_regex, "[RAILS_ROOT]")).cleanpath.to_s }
  end
  
  
  # TODO: IS IT THREAD-SAFE???
  def add(severity, message = nil, progname = nil, &block)
    return if @level > severity
    
    record = {
      :controller_name => (progname || @default_progname),
      :severity => severity,
      :environment => "* Process: #{@@pid}\n* Server: #{@@hostname}\n"
      }
    
    if message.kind_of?(Hash)
      if (environment = message.delete(:environment))
        record[:environment] << environment
      end
      
      message = record.merge(message)
      
      if (exception = message.delete(:exception))
        message[:exception_class] = exception.class.name
        message[:message] = exception.message.inspect
        message[:backtrace] = sanitize_backtrace(exception.backtrace) * "\n"        
      end
      
      message[:controller_name] = message[:controller_name].name.underscore if message[:controller_name].kind_of?(Module)
      
      @buffer << message
    else
      record[:message] = (message = (message || (block && block.call) || progname).to_s.strip)
      
      @buffer << record
      
      puts message if @show_log_on_stdout
    end
    
    auto_flush
    message
  end
  
  for severity in Severity.constants
    class_eval <<-EOT, __FILE__, __LINE__
      def #{severity.downcase}(message = nil, progname = nil, &block)
        add(#{severity}, message, progname, &block)
      end

      def #{severity.downcase}?
        #{severity} >= @level
      end
    EOT
  end

  # Set the auto-flush period. Set to true to flush after every log message,
  # to an integer to flush every N messages, or to false, nil, or zero to
  # never auto-flush. If you turn auto-flushing off, be sure to regularly
  # flush the log yourself -- it will eat up memory until you do.
  def auto_flushing=(period)
    @auto_flushing =
      case period
      when true;                1
      when false, nil, 0;       MAX_BUFFER_SIZE
      when Integer;             period
      else raise ArgumentError, "Unrecognized auto_flushing period: #{period.inspect}"
      end
  end

  def flush
    # TODO: IS IT THREAD-SAFE???
    unless @buffer.empty?
      @buffer.slice!(0..-1).each do |record|
        @insert.execute record[:exception_class], record[:controller_name], (record[:action_name] || 'unknown'), record[:message], record[:backtrace], record[:environment], record[:request], Time.now.strftime("%Y-%m-%d %H:%M:%S"), record[:severity]
      end
    end
  end
 
  def close
    flush
    @log.close if @log.respond_to?(:close)
    @log = nil
  end

  protected
    def auto_flush
      flush if @buffer.size >= @auto_flushing
    end
end