#
# derived from merbivore.com

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


require 'rubymq-facets/more/logger_accessor'
require 'rubymq-facets/core_ext'

class GreedyLoader
  LOADED_CLASSES = {}
  MTIMES = {}
  LOAD_PATHS = {}
  

  class << self
    # This is the core mechanism for setting up your application layout.
    # There are three application layouts in Merb:
    #
    # Regular app/:type layout of Ruby on Rails fame:
    #
    # app/models      for models
    # app/mailers     for mailers (special type of controllers)
    # app/parts       for parts, Merb components
    # app/views       for templates
    # app/controllers for controller
    # lib             for libraries
    #
    # Flat application layout:
    #
    # application.rb       for models, controllers, mailers, etc
    # config/init.rb       for initialization and router configuration
    # config/framework.rb  for framework and dependencies configuration
    # views                for views
    #
    # and Camping-style "very flat" application layout, where the whole Merb
    # application and configs fit into a single file.
    #
    # ==== Notes
    # Autoloading for lib uses empty glob by default. If you
    # want to have your libraries under lib use autoload, add
    # the following to Merb init file:
    #
    # Merb.push_path(:lib, Merb.root / "lib", "**/*.rb") # glob set explicity.
    #
    # Then lib/magicwand/lib/magicwand.rb with MagicWand module will
    # be autoloaded when you first access that constant.
    #
    # ==== Examples
    # This method gives you a way to build up your own application
    # structure, for instance, to reflect the structure Rails
    # uses to simplify transition of legacy application, you can
    # set it up like this:
    #
    # Merb.push_path(:models,      Merb.root / "app" / "models",      "**/*.rb")
    # Merb.push_path(:mailers,     Merb.root / "app" / "models",      "**/*.rb")
    # Merb.push_path(:controllers, Merb.root / "app" / "controllers", "**/*.rb")
    # Merb.push_path(:views,       Merb.root / "app" / "views",       "**/*.rb")
    #
    # ==== Parameters
    # type<Symbol>:: The type of path being registered (i.e. :view)
    # path<String>:: The full path
    # file_glob<String>::
    #   A glob that will be used to autoload files under the path. Defaults to
    #   "**/*.rb".

    def push_path(type, path, file_glob = "**/*.rb")
      enforce!(type => Symbol)
      LOAD_PATHS[type] = [path, file_glob]
    end
    
    def run(logger = LoggerAccessor.find)
      load_classes(LOAD_PATHS, logger)
    end
    
    # Load all classes inside the load paths.
    def load_classes load_paths, logger
      orphaned_classes = []
      # Add models, controllers, and lib to the load path

      # Require all the files in the registered load paths
      load_paths.each do |name, path|
        next if !path.first || !path.last
        Dir[path.first / path.last].each do |file|

          begin
            load_file file
          rescue NameError => ne
            orphaned_classes.unshift(file)
          end
        end
      end

      load_classes_with_requirements(orphaned_classes, logger)
    end

    # ==== Parameters
    # file<String>:: The file to load.
    def load_file(file)
      klasses = ObjectSpace.classes.dup
      load file
      LOADED_CLASSES[file] = ObjectSpace.classes - klasses
      MTIMES[file] = File.mtime(file)
    end

    # "Better loading" of classes.  If a class fails to load due to a NameError
    # it will be added to the failed_classs stack.
    #
    # ==== Parameters
    # klasses<Array[Class]>:: Classes to load.
    def load_classes_with_requirements(klasses, logger)
      klasses.uniq!

      while klasses.size > 0
        # Note size to make sure things are loading
        size_at_start = klasses.size

        # List of failed classes
        failed_classes = []
        # Map classes to exceptions
        error_map = {}

        klasses.each do |klass|
          klasses.delete(klass)
          begin
            load_file klass
          rescue NameError => ne
            error_map[klass] = ne
            failed_classes.push(klass)
          end
        end

        # Keep list of classes unique
        failed_classes.each { |k| klasses.push(k) unless klasses.include?(k) }

        # Stop processing if nothing loads or if everything has loaded
        if klasses.size == size_at_start && klasses.size != 0
          # Write all remaining failed classes and their exceptions to the log
          error_map.only(*failed_classes).each do |klass, e|
            logger.fatal("Could not load #{klass}:\n\n#{e.message} - (#{e.class})\n\n#{(e.backtrace || []).join("\n")}") if logger
          end
          raise LoadError, "Could not load #{failed_classes.inspect} (see log for details)."
        end
        break if(klasses.size == size_at_start || klasses.size == 0)
      end
    end
  end
end
