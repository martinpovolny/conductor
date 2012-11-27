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

require "costengine/version"
require "costengine/billingmodel"
require "costengine/mixins"

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
