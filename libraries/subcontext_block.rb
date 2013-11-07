#
# Author:: Noah Kantrowitz <noah@coderanger.net>
#
# Copyright 2013, Noah Kantrowitz
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

module Poise
  class SubContextResourceCollection < Chef::ResourceCollection
    def initialize(parent)
      @parent = parent
      super()
    end

    def lookup(resource)
      super
    rescue Chef::Exceptions::ResourceNotFound
      @parent.lookup(resource)
    end
  end

  module SubContextBlock
    private
    def subcontext_block(parent_context=nil, &block)
      # Setup a sub-run-context.
      parent_context ||= @run_context
      sub_run_context = parent_context.dup
      sub_run_context.resource_collection = SubContextResourceCollection.new(parent_context.resource_collection)

      # Declare sub-resources within the sub-run-context. Since they
      # are declared here, they do not pollute the parent run-context.
      begin
        outer_run_context, @run_context = @run_context, sub_run_context
        instance_eval(&block)
      ensure
        @run_context = outer_run_context
      end

      # Return the inner context to do other things with
      sub_run_context
    end

    def global_run_context
      context = @run_context
      while context.respond_to?(:parent) && context.parent
        context = context.parent
      end
      context
    end
  end
end
