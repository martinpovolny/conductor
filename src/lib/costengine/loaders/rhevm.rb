module CostEngine
  module Loaders
    class RHEVM
      def self.init_profiles
        ProviderType.find_by_deltacloud_driver('rhevm').providers.each do |provider|
          provider.hardware_profiles.each_with_index do |profile,i|
            cost = Cost.create!(
              :chargeable_id   => profile.id,
              :chargeable_type => CHARGEABLE_TYPES[:hardware_profile],
              :price           => 0,
              :valid_from      => Time.now() - 100.days,
              :valid_to        => nil,
              :billing_model   => 'per_property'
            )
            # create cost for mem, cpu, storage 
            
            Cost.create!(
              :chargeable_id   => profile.memory_id,
              :chargeable_type => CHARGEABLE_TYPES[:hw_memory],
              :price           => 0.2,
              :valid_from      => Time.now() - 100.days,
              :valid_to        => nil,
              :billing_model   => 'hour'
            )

            Cost.create!(
              :chargeable_id   => profile.cpu_id,
              :chargeable_type => CHARGEABLE_TYPES[:hw_cpu],
              :price           => 0.3,
              :valid_from      => Time.now() - 100.days,
              :valid_to        => nil,
              :billing_model   => 'hour'
            )

            Cost.create!(
              :chargeable_id   => profile.storage_id,
              :chargeable_type => CHARGEABLE_TYPES[:hw_storage],
              :price           => 0.5,
              :valid_from      => Time.now() - 100.days,
              :valid_to        => nil,
              :billing_model   => 'hour'
            )
          end
        end
      end
    end
  end
end
