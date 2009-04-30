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


# Usage:
#   ProcessController.process(FooProcess.new)
# 
# FooProcess MUST implements:
# 
#   start()
#   
# FooDaemon MAY implements:
# 
#   name() -- returning string which is used as pidfile name and log prefix
#   
#   define_options(options)
#   apply_options(options)
#   
#   stop() -- called on each received INT, TERM, ABRT or HUP
#     If not implemented, signals behaves as in original ruby (SignalException raised for main thread)
#
#     Note what in case when termination_signal call is still working and the next signal is arrived, 
#     first termination_signal processing stops and seconds starts.
#     I'm not sure how to make only one termination_signal call.
#     So, make termination_signal idempotent.
#     
#   stopper_thread() -- Behave like stop() but spawn a thread
#     
#   cleanup_before_exit() -- cleanup_before_exit will be called after run(), even if run() raised an exception
#

require 'etc'
require 'rubymq-facets'
require 'rubymq-facets/externals/logger' unless defined?(Merb::Logger)
require 'rubymq-facets/core_ext'
require 'rubymq-facets/thread'
require 'rubymq-facets/more/argv_parser'

class ProcessController
  class TestDaemon
    def define_options(options)
      options.header << "Test Daemon"
      options.option "--foo FOO", "Foo option"
    end

    def apply_options(options)
      puts options.inspect
    end

    def start
      puts "#{self.class.inspect} STARTED"
      sleep 100
    end
    
    def stop
      puts "#{self.class.inspect} STOP method"
    end
  end
  
  cattr_accessor :logger, :environment
  
  COMMANDS = %w(start stop restart run)
  LOG_STORAGES = %w(stdout file sqlite)
  LOG_LEVELS = %w(debug info warn error fatal)
  
  def self.process(options = nil, &block)
    new(&block).process(options)
  end
  
  def initialize &block
    @daemon_initializer = block
  end

  def process(options)
    begin
      options ||= ArgvParser.new ARGV
      options = initialize_options_parser(options)
      options.parse!
      apply_initial_options options
      set_logger
    rescue Exception => exception
      exception_complex_handling(exception, 10) do
        options.errors << exception.inspect_with_backtrace
        options.show_options_and_errors
      end
    end
    
    begin
      @daemon = @daemon_initializer.call(options, logger)
      
      @daemon.define_options(options) if @daemon.respond_to?(:define_options)
        
      options.parse!
      
      @daemon.apply_options(options) if @daemon.respond_to?(:apply_options) && options.complete?

      unless options["help"]
        if options.complete?
          apply_daemon_affected_options options
          set_logger
          execute_cmd options["COMMAND"]
        else
          options.show_errors logger
          options.show_options_and_errors
        end
      else
        options.show_options
        Process.exit!(11)
      end
      
    rescue Exception => exception
      exception_complex_handling(exception, 12) do
        logger.fatal("#{@name}#process: #{exception.inspect_with_backtrace}")
        options.errors << exception.inspect_with_backtrace
        options.show_options_and_errors
      end
    end
  end

  private
  
  def exception_complex_handling(exception, exit_code)
    yield
  rescue Exception => another_exception
    STDERR.puts "\n#{exception.inspect_with_backtrace}"
    STDERR.puts "\nWhile handling previous exception another error was occured:\n#{another_exception.inspect_with_backtrace}"
  ensure
    Process.exit!(exit_code)
  end
  

  def initialize_options_parser(options)
    options.heading_option "[COMMAND]", "ProcessController command (#{COMMANDS * "/"})"

    options.option "-e, --environment NAME", "Run in environment (development/production/testing)"
    options.option "--name NAME", "Daemon's name"
    options.option "--working-dir DIRECTORY", "Working directory, defaults to ."

    options.option "--pid-dir DIRECTORY", "PID directory, relative to working-dir, defaults to 'log', fallbacks to '.', may be absolute"
    options.option "--pid-file FILE", "PID file, defaults to [name].pid, may be absolute path"

    options.option "--user USER", "Run as user"
    options.option "--group GROUP", "Run as group"

    options.option "--log-to STORAGE", "Logger storage (#{LOG_STORAGES * "/"})"
    options.option "--log-level LEVEL", "Log level (#{LOG_LEVELS * "/"})"
    options.option "--log-dir DIRECTORY", "Log directory, relative to working-dir, default to 'log', fallbacks to '.', may be absolute"
    options.option "--log-file FILE", "Logfile, default to [name].log or [envoronment].log.db (--log-to sqlite), may be absolute path"

    options.option "--term-timeout SECONDS", "Termination timeout, default to 30 seconds"
    options.option "-?, --help", "Show this help message"
    
    return options
  end
  
  def apply_initial_options options
    change_process_privileges(options) if options["user"] || options["group"]
    
    Dir.chdir options["working-dir"] if options["working-dir"] # Release old working directory.
    
    options["COMMAND"] ||= "run"
    
    self.environment = (options["environment"] ||= ((options["COMMAND"] == "run") ? "development" : "production"))
    
    @name = options["name"] || "process_controller"
    
    @log_to    = options["log-to"] || (options["COMMAND"] == "run") ? "stdout" : ((self.environment == "production") ? "sqlite" : "file") # TODO: sqlite
    @log_level = (options["log-level"] || ((self.environment == "production") ? "warn" : "debug")).to_sym
    
    options["log-dir"] ||= 'log'
    options["log-dir"] = '.' unless File.directory?(options["log-dir"])
    
    options['pid-dir'] ||= 'log'
    options['pid-dir'] = '.' unless File.directory?(options['pid-dir'])
    
    @term_timeout = options['term-timeout'] = options['term-timeout'] && options['term-timeout'].to_i || 30
    
    apply_log_file_options options
  end
  
  def change_process_privileges(options)
    uid = options["user"] && Etc.getpwnam(options["user"]).uid || Process.euid
    gid = options["group"] && Etc.getgrnam(options["group"]).gid || Process.egid
    
    # http://www.ruby-forum.com/topic/110492
    Process.initgroups(options["user"], gid)
    
    Process::GID.change_privilege(uid)
    Process::UID.change_privilege(gid)
  end

  def apply_daemon_affected_options options
    @name = options["name"] || ((@daemon.respond_to?(:name) && @daemon.name) ? @daemon.name : @daemon.class.to_s.snake_case)
    
    apply_log_file_options options
    apply_pid_file_options options
  end

  def apply_log_file_options options
    @log_file = if options["COMMAND"] == "run"
        STDOUT
      elsif options["log-file"]
        (options["log-file"] =~ /^\//) ? options["log-file"] : "#{options["log-dir"]}/#{options["log-file"]}"
      else
        "#{options["log-dir"]}/" + if @log_to == 'sqlite' && respond_to?("create_#{@log_to}_logger")
            "#{self.environment}.log.db"
          else
            "#{@name}.log"
          end
      end
  end
  
  def apply_pid_file_options options
    @pid_file = if options['pid-file']
        (options['pid-file'] =~ /^\//) ? options['pid-file'] : "#{options['pid-dir']}/#{options['pid-file']}"
      else
         "#{options['pid-dir']}/#{@name}.pid"
      end
  end
  
  
  def set_logger
    if self.logger
      self.logger.set_log(@log_file, @log_level, " ~ ", true)
    else
      self.logger = Merb::Logger.new(@log_file, @log_level, " ~ ", true)
    end
  end
  
  def execute_cmd command
    handle_exception("#{@name}##{command}", :fatal) {send("#{command}_command")}

    logger.flush if logger.respond_to?(:flush)
  end

  def start_command
    detach
    run_command
  end
  
  def run_command
    logger.info "#{@name}: Starting daemon"
    
    create_pid
    
    begin
      trap_signals if @daemon.respond_to?(:stop) || @daemon.respond_to?(:stopper_thread)
      
      @stopper_thread = stopper_thread if @daemon.respond_to?(:stopper_thread)
      @termination_watchdog = termination_watchdog if @term_timeout
      
      handle_exception("#{@name}#start", :fatal) {@daemon.start}
      handle_exception("#{@name}#cleanup_before_exit", :error) {@daemon.cleanup_before_exit} if @daemon.respond_to?(:cleanup_before_exit)
    ensure
      untrap_signals if @daemon.respond_to?(:stop) || @daemon.respond_to?(:stopper_thread)
      delete_pid
      logger.info "#{@name}: daemon exited"
    end
  end
  
  
  def handle_exception(message, severity)
    yield
  rescue Exception => exception
    logger.send(severity, "#{message}: #{exception.inspect_with_backtrace}")
  end
  
  
  # based on Reimer Behrends notes http://blade.nagaokaut.ac.jp/cgi-bin/scat.rb/ruby/ruby-talk/87467
  
  def detach
    Process.exit!(0) if fork        # Parent exits, child continues.
    Process.setsid                  # Become session leader.
    Process.exit!(0) if fork        # Zap session leader. See http://www.erlenstar.demon.co.uk/unix/faq_2.html#SEC16
    
    File.umask 022                  # Ensure sensible umask. Adjust as needed.
    
    STDIN.reopen "/dev/null" # Free file descriptors and
    STDOUT.reopen(@log_file.gsub(/\.(db|log)$/, '.output'), "a") # point them somewhere sensible.
    STDERR.reopen STDOUT                                  # STDOUT/ERR should better go to a logfile.
  end
  
  
  # SIGNAL HANDLING
  
  def termination_watchdog
    Thread.new_with_exception_handling(logger, lambda {|exception| Process.exit!(20) unless exception.kind_of?(ThreadTerminatedError)}) do
      Thread.stop
      Thread.main.join_and_terminate(@term_timeout)
    end
  end
  
  def stopper_thread
    Thread.new_with_exception_handling(logger, lambda { Process.exit!(21) }) do
      Thread.stop
      @daemon.stopper_thread
    end
  end

  def dispatch_termination_signal
    @stopper_thread.run if @stopper_thread
    @termination_watchdog.run if @termination_watchdog

    @daemon.stop if @daemon.respond_to?(:stop)
    
  rescue Exception => exception
    begin
      logger.fatal "#{@name}: error while stopping: #{exception.inspect_with_backtrace}"
    ensure
      Process.exit!(22)
    end
  end
  
  def trap_signals
    Signal.trap('INT')  {dispatch_termination_signal} # Ctrl+C
    Signal.trap('TERM') {dispatch_termination_signal} # kill
    Signal.trap('ABRT') {dispatch_termination_signal} # Ctrl-\
    Signal.trap('HUP')  {dispatch_termination_signal} # terminal line hand-up
  end
  
  def untrap_signals
    Signal.trap 'INT',  'DEFAULT'
    Signal.trap 'TERM', 'DEFAULT'
    Signal.trap 'ABRT', 'DEFAULT'
    Signal.trap 'HUP',  'DEFAULT'
  end


  # PID FILE

  def stop_command
    if File.exists?(@pid_file)
      if is_running?(pid = File.read(@pid_file))
        Process.kill("TERM", pid.to_i)
      else
        raise "#{@name} daemon with pid #{pid} is not running."
      end
    else
      raise "#{@name} daemon pidfile (#{@pid_file}) not found."
    end
  end
  
  def create_pid
    if File.exists?(@pid_file)
      raise "Daemon #{@name} already running with pid:#{File.read(@pid_file)}" if is_running?(File.read(@pid_file))

      logger.warn "Found #{@name} daemon pidfile (#{@pid_file}), it may be result of an unclean shutdown."
    end

    File.write @pid_file, Process.pid
  end

  def delete_pid
    File.delete @pid_file
  end
  
  def is_running? pid
    begin
      return Process.getpgid(pid.to_i) && true
    rescue Errno::ESRCH
      return false
    end
  end
end
