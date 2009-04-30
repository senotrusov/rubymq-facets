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


# TODO: separator between options

class ArgvParser

  class UnnamedOption
    def initialize option_name, value_is_optional, value_may_be_array, comment, conditions, block
      @option_name = option_name
      @value_is_optional = value_is_optional
      @value_may_be_array = value_may_be_array
      @comment = comment
      @conditions = conditions
      @block = block
    end
    
    attr_accessor :option_name, :value_is_optional, :value_may_be_array, :comment, :conditions, :block
    attr_accessor :short_option_name, :option_is_boolean, :value_name
    
    def display
      "#{"[" if value_is_optional}#{option_name}#{"]" if value_is_optional}#{"..." if value_may_be_array}"
    end

    def columnized_display
      [display, comment]
    end
  end
  
  
  class Option < UnnamedOption
    def initialize short_option_name, option_name, option_is_boolean, value_is_optional, value_may_be_array, value_name, comment, conditions, block
      super option_name, value_is_optional, value_may_be_array, comment, conditions, block
      
      @short_option_name = short_option_name
      @option_is_boolean = option_is_boolean
      @value_name = value_name
    end
    
    def display_names
      [display_short_name, display_name].compact * "/"
    end
    
    def display_name
      "--#{"[no-]" if option_is_boolean}#{option_name}" if option_name
    end
    
    def display_short_name
      "-#{short_option_name}" if short_option_name
    end
    
    def display_value
      "#{"[" if value_is_optional}#{value_name}#{"]" if value_is_optional}#{"..." if value_may_be_array}"
    end
    
    def columnized_display
      [display_short_name, display_name, display_value, comment]
    end
  end
  

  class IteratableArray < Array
    def initialize *args, &block
      @position = 0
      super(*args, &block)
    end
    
    attr_accessor :position

    def each_with_iterator
      while @position < length
        result = yield(current)

        if result.kind_of?(Array)
          if result.first == :and_crop
            slice!(@position, result.last)
          elsif result.first == :after_slice_until!
            
          else
            step
          end
        else
          step
        end
      end
    end
    
    def slice_until!
      slice_from = @position
      step
      
      while @position < length
        break if yield(current)
        step
      end
      
      result = slice!(slice_from, @position - slice_from)
      
      @position = slice_from
      
      return result
    end
    
    def current
      self[@position]
    end

    def look_ahead(offset = 1)
      self[@position + offset]
    end
    
    def remains
      slice(@position..-1)
    end
    
    def step
      @position += 1
    end
    
    def end?
      @position >= length
    end
  end
  

  def initialize argv
    # TODO ! Normalisation of "=" and ",". Remove "=", join comma separated arrays to arrays.

    @argv = IteratableArray.new(argv)
    @values = {}

    @header = []
    @footer = []
    
    @errors = []
    
    @heading_opts  = IteratableArray.new
    @tailing_opts  = IteratableArray.new
    @floating_opts = IteratableArray.new
    
    @opts = {}
    @opts_list = []

    @tailing_start_position = 0
    
    yield(self) if block_given?
  end

  def [] option
    if @values.has_key?(option)
      @values[option]
      
    elsif @values.has_key?(key = option.to_s)
      @values[key]
      
    elsif @values.has_key?(key = option.to_s.gsub(/_/, '-'))
      @values[key]

    elsif @values.has_key?(key = option.to_s.gsub(/_/, '-').upcase)
      @values[key]
    
    else
      nil
    end
  end
  
  def []= option, value
    @values[option] = value
  end

  def to_hash
    @values
  end

  def merge hash
    to_hash.merge hash
  end
  
  def inspect
    @values.inspect
  end
  
  attr_reader :header, :footer, :errors
  
  def errors?
    !@errors.empty?
  end
  
  def complete?
    (errors? || 
     !@argv.empty? ||
      unnamed_opts_incomplete?(@heading_opts) ||
      unnamed_opts_incomplete?(@tailing_opts) ||
      unnamed_opts_incomplete?(@floating_opts)) ? false : true
  end
  
  private
  
  def unnamed_opts_incomplete? collection
    !collection.remains.select{|item| !item.value_is_optional && !@values[item.option_name]}.empty?
  end
  
  def display_incomplete_required_unnamed_opts collection
    collection.remains.select{|item| !item.value_is_optional}.collect{|item|item.display}
  end
  
  public
  
  def show_options_and_errors_on_incomplete
    unless complete?
      show_options_and_errors
      true
    else
      false
    end
  end

  def show_options_and_errors
    show_options
    show_errors
  end
  
  def show_errors_and_options
    show_errors
    show_options
  end
  
  def show_errors output = STDERR
    output << ("!!! *** " * 10 + "\n\n")
    output << (@errors * "\n" +  "\n") unless @errors.empty?
    output << ("Can't parse options: " + @argv * " " +  "\n") unless @argv.empty?
    output << ("Incomplete heading options: " + display_incomplete_required_unnamed_opts(@heading_opts) * " " + "\n") if unnamed_opts_incomplete?(@heading_opts)
    output << ("Incomplete tailing options: " + display_incomplete_required_unnamed_opts(@tailing_opts) * " " + "\n") if unnamed_opts_incomplete?(@tailing_opts)
    output << ("Incomplete floating options: " + display_incomplete_required_unnamed_opts(@floating_opts) * " " + "\n") if unnamed_opts_incomplete?(@floating_opts)
    output << ("\n" + ("!!! *** " * 10) + "\n\n")
    
    output.flush if output.respond_to?(:flush)
  end
  
  def show_options output = STDOUT
    output << (@header * "\n" + "\n\n") unless @header.empty?
    
    overview = @heading_opts.collect{|option| option.display}
    overview += [("[Options]..." unless @opts_list.empty?)]
      
    unless @floating_opts.empty?
      overview += @floating_opts.collect{|option| option.display}
      overview += [("[Options]..." unless @opts_list.empty?)]
    end
    
    overview += @tailing_opts.collect{|option| option.display}

    output << "Usage:\n  " + ("#{$0} " + (overview * " ") + "\n\n")
    
    options = @opts_list.collect {|option| option.columnized_display }
    unnamed_opts = (@heading_opts + @tailing_opts + @floating_opts).collect{|option| option.columnized_display}

    first_column = options.collect{|option| "#{option[0]},".length}.max
    second_column = (unnamed_opts.collect{|option| "#{option[0]}".length} + options.collect{|option| option[1] ? "#{option[1]} #{option[2]}".length : ("#{option[2]}".length - 1)}).max

    lines = unnamed_opts.collect do |option|
      sprintf("  %#{first_column}s %#{0 - second_column}s %s", nil, option[0], option[1])
    end
    
    lines.push ""
    lines.push "Options:"

    lines += options.collect do |option|
      if option[1]
        sprintf("  %#{first_column}s %#{0 - second_column}s %s", ("#{option[0]}," if option[0]), "#{option[1]} #{option[2]}", option[3])
      else
        sprintf("  %#{first_column - 1}s %#{-1-second_column}s %s", option[0], option[2], option[3])
      end
    end

    output << (lines * "\n" + "\n\n")
    
    output << (@footer * "\n" + "\n\n")
    
    output.flush if output.respond_to?(:flush)
  end

  private

  VALUE_NAME = /[\w\d\-\/\\\:]+/
  
  def parse_option(option, comment, conditions, &block)
    unless (matchdata = option.match(/^\s*(-([\w\d\?]+)\s*((\[?)(#{VALUE_NAME})(\]?)(\.{0,3}))?\s*(,*)\s*)?(--(\[no-\])?([\w\d\-\?]+)\s*((\[?)(#{VALUE_NAME})(\]?)(\.{0,3}))?\s*(,*)\s*)?$/))
      raise "Can not recognize option declaration '#{option}'" 
    end

    return Option.new(
      matchdata[2],  #  short_option_name
      matchdata[11], #  option_name
      matchdata[10] == "[no-]" || (!matchdata[14] && !matchdata[5]) ? true : false, #  option_is_boolean
      matchdata[13] == "["   || matchdata[4] == "["   ? true : false, #  value_is_optional
      matchdata[16] == "..." || matchdata[7] == "..." ? true : false, #  value_may_be_array
      matchdata[14] || matchdata[5], #  value_name
      comment,
      conditions,
      block
    )
  end
  
  def parse_unnamed_option(option, comment, conditions, &block)
    unless (matchdata = option.match(/^\s*(\[?)(#{VALUE_NAME})(\]?)(\.{0,3}?)\s*$/))
      raise "Can not recognize option declaration '#{option}'" 
    end
    
    return UnnamedOption.new(
      matchdata[2], #  option_name
      matchdata[1] == "[" ? true : false,   #  value_is_optional
      matchdata[4] == "..." ? true : false, #  value_may_be_array
      comment,
      conditions,
      block
    )
  end
  
  def push_unnamed_option(collection, option)
    raise("There are no text left for #{option.option_name} after a greedy array '#{collection.last.option_name}'") if collection.last && collection.last.value_may_be_array
    raise("Strictly required text #{option.option_name} can't be after a optional text '#{collection.last.option_name}'") if !option.value_is_optional && collection.last && collection.last.value_is_optional
    
    collection.push option    
  end
  
  public

  # "--option-foo [VALUE]"
  # "--option [VALUE]..." (zero or more comma separated values)
  # "--option VALUE"
  # "--option VALUE..." (one or more comma separated values)
  # "--option"
  # "--[no-]option"
  # 
  # "-ooo [VALUE]"
  # "-o [VALUE]..." (zero or more comma separated values)
  # "-o VALUE"
  # "-o VALUE..." (one or more comma separated values)
  # "-o"
  # 
  # "-o, --option [VALUE]"
  # "-o, --option [VALUE]..." (zero or more comma separated values)
  # "-o, --option VALUE"
  # "-o, --option VALUE..." (one or more comma separated values)
  # "-o, --option"
  # "-o, --[no-]option"
  def option(option, comment = nil, conditions = nil, &block)
    option = parse_option(option, comment, conditions, &block)
    
    @opts_list.push option
    @opts[option.short_option_name] = option if option.short_option_name
    @opts[option.option_name] = option if option.option_name
  end
  
  # "[VALUE]"
  # "VALUE"
  # "[VALUE]..." (zero or more space separated values)
  # "VALUE..."  (one or more space separated values)
  def heading_option(option, comment = nil, conditions = nil, &block)
    push_unnamed_option(@heading_opts, parse_unnamed_option(option, comment, conditions, &block))
  end
  
  # "[VALUE]"
  # "VALUE"
  # "[VALUE]..." (zero or more space separated values)
  # "VALUE..."  (one or more space separated values)
  def tailing_option(option, comment = nil, conditions = nil, &block)
    push_unnamed_option(@tailing_opts, parse_unnamed_option(option, comment, conditions, &block))
  end
  
  # "[VALUE]"
  # "VALUE"
  # "[VALUE]..." (zero or more space separated values)
  # "VALUE..."  (one or more space separated values)
  def floating_option(option, comment = nil, conditions = nil, &block)
    push_unnamed_option(@floating_opts, parse_unnamed_option(option, comment, conditions, &block))
  end
  

  private
  
  def check_and_assign_value option, value
    value = value.split(",") if option.value_may_be_array
    
    if option.option_is_boolean
      option.block.call if value && option.block
    else
      begin
        value = option.block.call(value) if option.block
      rescue ArgumentError => exception
        @errors << "#{option.display_names}: #{exception.message}"
        
      rescue Exception => exception
        @errors << "#{option.display_names}: #{exception.inspect_with_backtrace}"
        
        raise exception unless exception.kind_of?(StandardError) || exception.kind_of?(ScriptError)
      end
    end
    
    # TODO: conditions
    
    @values[option.option_name || option.short_option_name] = value
  end
  
  def parse_unnamed_opts collection
    @argv.each_with_iterator do |item|
      break if collection.end? || item =~ /^-/
      
      if collection.current.value_may_be_array
        check_and_assign_value(collection.current, @argv.slice_until!{|item| item =~ /^-/})
        collection.step
        break
      else
        check_and_assign_value(collection.current, item)
        collection.step
        next :and_crop, 1
      end
    end
  end
  
  public
  
  # TODO: "tar -czf file.tgz dir", "tar czf file.tgz dir"

  def parse!
    @argv.position = 0
    
    parse_unnamed_opts @heading_opts
    
    @argv.each_with_iterator do |item|
      next unless (matchdata = item.match(/^--?(no-)?([\w\d\-\?]+)$/))
      next unless (option = @opts[matchdata[2]])
      
      @tailing_start_position = @argv.position
      
      if option.option_is_boolean
        check_and_assign_value(option, (matchdata[1].nil? ? true : false))
        next :and_crop, 1
        
      elsif @argv.look_ahead =~ /^-/ || !@argv.look_ahead
        if option.value_is_optional
          check_and_assign_value(option, true)
        else
          errors << "#{option.display_names} must have a value"
        end
        next :and_crop, 1
      else
        check_and_assign_value(option, @argv.look_ahead)
        next :and_crop, 2
      end
    end
    
    unless @argv.detect{|item| item =~ /^-/}
      @argv.position = @tailing_start_position
      parse_unnamed_opts @tailing_opts
      
      @argv.position = 0
      parse_unnamed_opts @floating_opts
    end
  end
end