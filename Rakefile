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


require 'rubygems'
require 'rake/gempackagetask'
require 'rubygems/specification'

spec = Gem::Specification.new do |s|
  s.name          = "rubymq-facets"
  s.version       = "3.0.0"
  
  s.platform      = Gem::Platform::RUBY
  s.has_rdoc      = true
  s.extra_rdoc_files  = %w(README LICENSE)
  
  s.summary       = "RubyMQ Facets (helper library)"
  s.description   = s.summary
  s.author        = "Stanislav Senotrusov"
  s.email         = "senotrusov@gmail.com"
  s.homepage      = "http://rubymq.rubyforge.org/"
  s.rubyforge_project = 'rubymq'
  
  s.require_path  = 'lib'
  s.files         = %w(README LICENSE Rakefile) + Dir.glob("{lib,spec,test}/**/*")
  
#  s.bindir        = "bin"
#  s.executables   = %w()
end

Rake::GemPackageTask.new(spec) do |pkg|
  pkg.gem_spec = spec
end
