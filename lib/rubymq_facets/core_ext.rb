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


require 'rubymq_facets/externals/core_ext/class' unless Class.respond_to?(:class_inheritable_accessor)
require 'rubymq_facets/externals/core_ext/hash' unless Hash.method_defined?(:to_mash)
require 'rubymq_facets/externals/core_ext/kernel' unless Kernel.respond_to?(:enforce!)
require 'rubymq_facets/externals/core_ext/mash' unless defined?(Mash)
require 'rubymq_facets/externals/core_ext/object' unless Object.method_defined?(:full_const_get)
require 'rubymq_facets/externals/core_ext/object_space' unless ObjectSpace.respond_to?(:classes)
require 'rubymq_facets/externals/core_ext/string' unless String.method_defined?(:snake_case)
require 'rubymq_facets/externals/core_ext/time' unless Time.method_defined?(:to_json)
