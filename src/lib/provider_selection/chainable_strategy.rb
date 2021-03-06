#
#   Copyright 2012 Red Hat, Inc.
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#

module ProviderSelection
  module ChainableStrategy

    module InstanceMethods

      def initialize(strategies, options = {})
        @strategies = strategies
        options ||= {}

        if self.class.methods.map(&:to_s).include?('default_options')
          @options = self.class.default_options.with_indifferent_access.merge(options)
        else
          @options = options
        end
      end

      def method_missing(method, *args)
        args.empty? ? @strategies.send(method) : @strategies.send(method, args)
      end

    end

  end
end
