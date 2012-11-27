#
#   copyright 2012 red hat, inc.
#
#   licensed under the apache license, version 2.0 (the "license");
#   you may not use this file except in compliance with the license.
#   you may obtain a copy of the license at
#
#       http://www.apache.org/licenses/license-2.0
#
#   unless required by applicable law or agreed to in writing, software
#   distributed under the license is distributed on an "as is" basis,
#   without warranties or conditions of any kind, either express or implied.
#   see the license for the specific language governing permissions and
#   limitations under the license.
#

module CostEngine
  module Mixins
    module HardwareProfileClass
      def chargeables
        [:memory, :cpu, :storage]
      end
    end

    module HardwareProfile
      # lookup __today's__ cost or this __backend__ profile
      def unit_price
        # FIXME: what about units?
        (Cost.for_chargeable_and_period(1, id, t=Time.now, t).price rescue nil)
      end

      def cost_now(t=Time.now)
        Cost.for_chargeable_and_period(1, id, t, t)
      end

      # 'close' associated set of cost
      # that is set the time_to to now
      def close_costs(all=true)
        hwp_cost = cost_now(t=Time.now)
        hwp_cost.close unless hwp_cost.nil?

        if all
          ::HardwareProfile::chargeables.each do |what| 
            hwp_prop_cost = send(what).cost_now(t)
            hwp_prop_cost.close unless hwp_prop_cost.nil?
          end
        end
      end
    end

    module HardwareProfileProperty
      def chargeable_type 
        CostEngine::CHARGEABLE_TYPES[('hw_'+name).intern]
      end

      # lookup __today's__ cost or this __backend__ profile property
      def unit_price
        Cost.for_chargeable_and_period(chargeable_type, id, t=Time.now, t).price rescue nil
      end

      def cost_now(t=Time.now)
        Cost.for_chargeable_and_period(chargeable_type, id, t, t)
      end
    end

    module InstanceMatch
      def price
        hardware_profile.price
      end
    end

    module InstanceHwp

      # calculate cost estimate for an instance that was previously running or
      # is running now
      #
      def cost
        start = instance[:time_last_running]
        return nil if start.nil?
        stop = instance[:time_last_stopped] || Time.now
    
        Rails.logger.debug('search cost for hwp: '+hardware_profile.inspect)
        Rails.logger.debug('instance_hwp:'+self.inspect)
        cost = Cost.for_chargeable_and_period(1, hardware_profile.id, start, stop)
        return nil if cost.nil?

        price = cost.calculate(start, stop)
        price += cost_per_partes if cost.billing_model == 'per_property' 
        price
      end

     private
      def cost_per_partes
        start = instance[:time_last_running]
        stop  = instance[:time_last_stopped] || Time.now

        # search costs for memory, cpu and storage
        costs = [ 
          Cost.for_chargeable_and_period(CHARGEABLE_TYPES[:hw_memory],  
            hardware_profile.memory_id,  start, stop),
          Cost.for_chargeable_and_period(CHARGEABLE_TYPES[:hw_cpu],
            hardware_profile.cpu_id,     start, stop),
          Cost.for_chargeable_and_period(CHARGEABLE_TYPES[:hw_storage], 
            hardware_profile.storage_id, start, stop)
        ]

        costs.inject(0) { |sum,acost| sum + acost.calculate(start, stop) }
      end
    end
        
    module Instance
      def cost
        # NONE: due to a bug (fixed) previously instances did not have instance_hwp
        # so we need to rescue from that
        instance_hwp.cost rescue nil
      end
    end
    
    module Deployment
      def cost
        instances.inject(0) do |sum, instance| 
          return nil if instance.cost.nil? 
          sum + instance.cost
        end
      end
    end
  end
end
