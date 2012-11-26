# Read about factories at http://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :cost do
    chargeable_id 1
    chargeable_type 1
    price 0.1
    valid_from Time.now
    valid_to Time.now + 1.day
    billing_model 1
  end

end
