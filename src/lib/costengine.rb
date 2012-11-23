require "costengine/version"
require "costengine/billingmodel"
require "costengine/mixins"
require "costengine/loaders"

module CostEngine
  def self.infect_models
    InstanceMatch.send(:include, CostEngine::Mixins::InstanceMatch)
    InstanceHwp.send(:include, CostEngine::Mixins::InstanceHwp)
    Instance.send(:include, CostEngine::Mixins::Instance)
    Deployment.send(:include, CostEngine::Mixins::Deployment)
    HardwareProfile.send(:include, CostEngine::Mixins::HardwareProfile)
    HardwareProfile.extend(CostEngine::Mixins::HardwareProfileClass)
    HardwareProfileProperty.send(:include, CostEngine::Mixins::HardwareProfileProperty)
  end
  
  CHARGEABLE_TYPES = { 
    :hardware_profile => 1,
    :hw_cpu           => 2,
    :hw_memory        => 3,
    :hw_storage       => 4,
  }
end
