# Read about factories at http://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :costs do
    chargeable_id 1
    chargeable_type 1
    valid_from "2012-10-19 11:26:25"
    valid_to "2012-10-19 11:26:25"
  end
end
