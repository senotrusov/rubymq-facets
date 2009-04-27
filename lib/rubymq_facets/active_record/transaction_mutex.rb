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

# TODO Разобраться, что теперь с этим в AR
#
#class ActiveRecord::Base
#  TRANSACTION_MUTEX = Mutex.new
#
#  class << self
#    def transaction_with_mutex(&block)
#      if ActiveRecord::Base.allow_concurrency
#        transaction_without_mutex(&block)
#      else
#        if Thread.current['open_transactions'] && Thread.current['open_transactions'] > 0
#          transaction_without_mutex(&block)
#        else
#          TRANSACTION_MUTEX.synchronize { transaction_without_mutex(&block)}
#        end
#      end
#    end
#
#    alias_method_chain :transaction, :mutex
#  end
#end

# TODO Сделать включаемым эту функциональность.