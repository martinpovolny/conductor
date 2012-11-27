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
  module Strategies
    module CostOrder

      class Strategy
        include ProviderSelection::ChainableStrategy::InstanceMethods

        @default_options = {
          :impact => 1
        }

        def self.default_options
          @default_options
        end

        def penalty_for_cost(hardware_profile,mode=:linear)
          return 0 if (cost = hardware_profile.cost_now).nil?
          case mode
          when :linear
            cost.price * 1000
          when :logaritmic
            Math.log(cost.price) * 1000
          when :polynomial
            cost.price**2 * 1000
          end
        end

        def calculate
          rank = @strategies.calculate
          Rails.logger.debug( ['CostOrder::Strategy::calculate', rank] )

          rank.priority_groups.each do |priority_group|
            priority_group.matches.each do |match|
              match.penalize_by(penalty_for_cost(match.hardware_profile))
            end
          end

          rank
        end
      end
    end
  end
end
