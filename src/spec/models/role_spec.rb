require 'spec_helper'

describe Role do

  it "should not be valid if name is too long" do
    u = FactoryGirl.create(:role)
    u.name = ('a' * 256)
    u.valid?.should be_false
    u.errors[:name].should_not be_nil
    u.errors[:name][0].should =~ /^is too long.*/
  end
end
