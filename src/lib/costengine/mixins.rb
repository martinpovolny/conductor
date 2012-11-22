module CostEngine
  module Mixins
    module HardwareProfileClass
      def chargeables
        [:memory, :cpu, :storage]
      end
    end
    module HardwareProfile
      # calculate expected cost of run of this frontend hardware_profile
      # at given provider
      def cost_at_provider( provider )

        # check if match exists
        
        # get matching 
        # 1) frontend hardware provider and 
        # 2) instance_hwp

        # calculate price given backend hwp and instance_hwp
      end

      # lookup __today's__ cost or this __backend__ profile
      def price
        # FIXME: what about units?
        ( Cost.find_by_chargeable_and_time_range(1, id, t=Time.now, t).price rescue nil )
      end

      def cost_now(t=Time.now)
        Cost.find_by_chargeable_and_time_range(1, id, t, t)
      end

      # 'close' associated set of cost
      # that is set the time_to to now
      def close_costs(all=true)
        hwp_cost = cost_now(t=Time.now)
        #Rails.logger.error(['hwp_cost', hwp_cost].inspect)
        hwp_cost.close unless hwp_cost.nil?

        if all
          @hwp_prop_costs = {}
          ::HardwareProfile::chargeables.each { |what| 
            hwp_prop_cost = send(what).cost_now(t)
            #Rails.logger.error(['hwp_prop_cost', hwp_prop_cost].inspect)
            hwp_prop_cost.close unless hwp_prop_cost.nil?
          }
        end
      end

    end

    module HardwareProfileProperty
      def chargeable_type 
        CostEngine::CHARGEABLE_TYPES[('hw_'+name).intern]
      end

      # lookup __today's__ cost or this __backend__ profile property
      def price
        Cost.find_by_chargeable_and_time_range(chargeable_type, id, t=Time.now, t).price rescue nil
      end

      def cost_now(t=Time.now)
        Cost.find_by_chargeable_and_time_range(chargeable_type, id, t, t)
      end
    end

    module InstanceMatch
      def price
        hardware_profile.price
      end
    end

    module InstanceHwp
      def cost
        start = instance[:time_last_running]
        return -1 if start.nil?
        stop  = instance[:time_last_stopped] || Time.now
    
        p ['searching cost for', hardware_profile.external_key, hardware_profile.id]
        p ['instance_hwp', self]
        cost = Cost.find_by_chargeable_and_time_range( 1, hardware_profile.id, start, stop )
        return -1 if cost.nil?

        price = cost.calculate( start, stop )
        price += cost_per_partes if cost.billing_model == 3 
        price
      end

     private
      def cost_per_partes
        start = instance[:time_last_running]
        stop  = instance[:time_last_stopped] || Time.now

        # pro pamet, cpu a memory musime najit 
        costs = [ 
         Cost.find_by_chargeable_type_and_chargeable_id(CHARGEABLE_TYPES[:hw_memory],  hardware_profile.memory_id,  start, stop),
         Cost.find_by_chargeable_type_and_chargeable_id(CHARGEABLE_TYPES[:hw_cpu],     hardware_profile.cpu_id,     start, stop),
         Cost.find_by_chargeable_type_and_chargeable_id(CHARGEABLE_TYPES[:hw_storage], hardware_profile.storage_id, start, stop)
        ]

        costs.inject(0) { |sum,acost| 
          p [sum, acost]
          sum + acost.calculate(start, stop) 
        }
      end
    end
        
    module Instance
      def cost
        #valid_match.cost
        instance_hwp.cost rescue 0 # in the pasw instance_hwp was not set, so we rescue from that
      end

      #def valid_match
      #  # FIXME: assume that the instance_match, that got executed is the latest one
      #  instance_matches.order(:created_at).reverse_order[0]
      #end
    end
    
    module Deployment
      def cost
        instances.inject(0) { |sum, instance| 
          sum + instance.cost
        }
      end
    end
  end
end
