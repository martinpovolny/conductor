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

require 'spec_helper'

describe ProviderSelection::Strategies::CostOrder::Strategy do
  before(:each) do
    @account1 = FactoryGirl.create(:mock_provider_account, :label => "test_account1")
    @account2 = FactoryGirl.create(:mock_provider_account, :label => "test_account2")

    hwp1 = FactoryGirl.create(:hardware_profile)
    hwp2 = FactoryGirl.create(:hardware_profile)

    cost1 = FactoryGirl.create(:cost, :chargeable_id => hwp1.id, :price => 0.1)
    cost2 = FactoryGirl.create(:cost, :chargeable_id => hwp2.id, :price => 0.01)

    possible1 = FactoryGirl.build(:instance_match, :provider_account => @account1, :hardware_profile => hwp1)
    possible2 = FactoryGirl.build(:instance_match, :provider_account => @account2, :hardware_profile => hwp2)

    instance = Factory.build(:instance)
    instance.stub!(:matches).and_return([[possible1, possible2], []])

    @provider_selection = ProviderSelection::Base.new([instance])
  end
end
