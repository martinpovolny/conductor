require 'spec_helper'

describe Cost do
  #pending "add some examples to (or delete) #{__FILE__}"

  before(:each) do
    @cost = Factory.create(:cost)
  end

  describe "calculate" do
    it "should return a number" do
      @cost.calculate(t=Time.now, t=Time.now+1.hour).should be_a_kind_of(Numeric)
    end
  end

  describe "close" do
    it "should end the validity" do
      @cost.close
      @cost.valid_to.should <= Time.now
    end
  end
end
