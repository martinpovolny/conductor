module CostEngine
  module Loaders
    class EC2
      def self.init_profiles
        inputs = ActiveSupport::JSON.decode(`~/ec2instancespricing/ec2instancespricing.py --type ondemand --filter-os-type linux --format json`)
        
        regions = inputs['regions'].collect {|r| r['region'] }
        ec2_profiles = inputs['regions'].find {|r| r['region']=='us-east-1' }
        
        profile2price = {}
        ec2_profiles['instanceTypes'].each { |p| profile2price[p['type']] = p }
        
        profiles = HardwareProfile.where("external_key is not NULL")
        
        profiles.each { |profile|
          ek = profile.external_key
          ec2prof = profile2price[ek]

          unless ec2prof.nil?
            cost = Cost.create!(
              :chargeable_id   => profile.id,
              :chargeable_type => 1, #:hardware_profile,
              # currency        => 'USD',
              :price             => BigDecimal( ec2prof['price'].to_s ),
              :valid_from        => Time.now() - 100.days, # FIXME
              :valid_to          => nil,
              :billing_model     => 1
            )
          end
        }
        
        #p Cost.find(:all)
      end
    end
  end
end
