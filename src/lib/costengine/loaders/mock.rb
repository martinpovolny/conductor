module CostEngine
  module Loaders
    class Mock
      def self.init_profiles
        ProviderType.find_by_deltacloud_driver('mock').providers.each do |provider|
          provider.hardware_profiles.each_with_index do |profile,i|
            cost = Cost.create!(
              :chargeable_id   => profile.id,
              :chargeable_type => 1, #:hardware_profile,
              :price             => 0.5+i, #BigDecimal( i.to_f+0.5 ),
              :valid_from        => Time.now() - 100.days, # FIXME
              :valid_to          => nil,
              :billing_model     => 'hour'
            )
          end
        end
      end
    end
  end
end
