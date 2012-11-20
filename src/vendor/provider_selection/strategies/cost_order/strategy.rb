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
          Rails.logger.error( ['CostOrder::Strategy::calculate', rank] )

          # matching:
          #   lib/provider_selection/base.rb calls:
          #     ProviderAccount::instance_matches calls: 
          #       !(hwp = HardwareProfile.match_provider_hardware_profile(provider, instance.hardware_profile))
          #             ---> creates InstanceMatch
          #                       InstanceMatch has cost again
          #                         --> use thin cost HERE in the strategy
          #
          # 

          # ProviderSelection::Rank
          #   @priority_groups --> [
          #     -> ProviderSelection::PriorityGroup
          #           @matches --> [
          #             --> ProviderSelection::Match defined in: lib/provider_selection/match.rb
          #                 @provider_account
          #                 @score
          #
          #                 # have only provider_account, no hardware profile :-(
          #
          #   @default_priority_group --> ProviderSelection::PriorityGroup
          #
          #["CostOrder::Strategy::calculate", #<ProviderSelection::Rank:0x00000007182188 @priority_groups=[#<ProviderSelection::PriorityGroup:0x0000000779a908 
          # @matches=[
          # #<ProviderSelection::Match:0x0000000779a868 @provider_account=#<ProviderAccount id: 2, label: "mock add", provider_id: 2, quota_id: 8, lock_version: 0, created_at: "2012-10-29 14:49:02", updated_at: "2012-10-29 14:49:02", priority: nil>, @score=nil>, 
          # #<ProviderSelection::Match:0x0000000779a548 @provider_account=#<ProviderAccount id: 4, label: "mock acc 2", provider_id: 4, quota_id: 13, lock_version: 0, created_at: "2012-11-16 17:57:38", updated_at: "2012-11-16 17:57:38", priority: nil>, @score=nil>], 
          # @score=100000>], @pool=#<Pool id: 2, name: "mock me running", exported_as: nil, quota_id: 9, pool_family_id: 2, lock_version: 0, created_at: "2012-10-29 14:50:54", updated_at: "2012-10-29 14:50:54", enabled: true>, @default_priority_group=#<ProviderSelection::PriorityGroup:0x0000000779a908 
          # @matches=[
          #   #<ProviderSelection::Match:0x0000000779a868 @provider_account=#<ProviderAccount id: 2, label: "mock add", provider_id: 2, quota_id: 8, lock_version: 0, created_at: "2012-10-29 14:49:02", updated_at: "2012-10-29 14:49:02", priority: nil>, @score=nil>, 
          #   #<ProviderSelection::Match:0x0000000779a548 @provider_account=#<ProviderAccount id: 4, label: "mock acc 2", provider_id: 4, quota_id: 13, lock_version: 0, created_at: "2012-11-16 17:57:38", updated_at: "2012-11-16 17:57:38", priority: nil>, @score=nil>], @score=100000>>]
          #  SQL (0.3ms)  INSERT INTO "events" ("created_at", "deleted_at", "description", "event_time", "source_id", "source_type", "status_code", "summary", "updated_at") VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9) RETURNING "id"  [["created_at", Sun, 18 Nov 2012 18:49:19 UTC +00:00], ["deleted_at", nil], ["description", nil], ["event_time", Sun, 18 Nov 2012 18:49:19 UTC +00:00], ["source_id", 23], ["source_type", "Deployment"], ["status_code", "deployment_launch_match"], ["summary", "Attempting to launch this deployment on provider account mock acc 2"], ["updated_at", Sun, 18 Nov 2012 18:49:19 UTC +00:00]]
          #
          #

          rank.priority_groups.each do |priority_group|
            priority_group.matches.each do |match|
              match.penalize_by(penalty_for_cost(match.hardware_profile))
            end
          end

          #return rank unless @options.has_key?(:failure_count_hard_limit)

          # # Create priority group for failing provider accounts with higher
          # # score than the default one
          # failing_provider_accounts = failures_count.inject([]) do |result, (provider_account, failure_count)|
          #   if failure_count >= @options[:failure_count_hard_limit]
          #     result << provider_account
          #   end

          #   result
          # end.uniq

          # rank.priority_groups.each do |priority_group|
          #   priority_group.delete_matches(:provider_account, failing_provider_accounts)
          # end

          #failing_priority_group = ProviderSelection::PriorityGroup.new(rank.default_priority_group.score * 100)
          #failing_provider_accounts.each do |provider_account|
          #  failing_priority_group.matches << Match.new(:provider_account => provider_account)
          #end

          #rank.priority_groups << failing_priority_group

          rank
        end

      end

    end
  end
end
