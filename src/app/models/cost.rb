# conductor_development=# \d costs
#                                         Table "public.costs"
#      Column      |            Type             |                     Modifiers                      
# -----------------+-----------------------------+----------------------------------------------------
#  id              | integer                     | not null default nextval('costs_id_seq'::regclass)
#  chargeable_id   | integer                     | 
#  chargeable_type | integer                     | 
#  valid_from      | timestamp without time zone | 
#  valid_to        | timestamp without time zone | 
#  created_at      | timestamp without time zone | not null
#  updated_at      | timestamp without time zone | not null
# Indexes:
#     "costs_pkey" PRIMARY KEY, btree (id)

class Cost < ActiveRecord::Base
  attr_accessible :chargeable_id, :chargeable_type, :valid_from, :valid_to, 
                  :price, :billing_model

  validates_presence_of :chargeable_id, :chargeable_type, :billing_model, 
                        :valid_from
  # valid_to might be null resulting in unlimited validity
  # price might be null for PER_PART billing model
  
  validate :validate_by_billing_model

  def validate_by_billing_model
    if billing_model == 'per_property' and price.blank?
      errors.add(:base, "price cannot be blank")
    end
  end

  def self.for_chargeable_and_period(chargeable_type, chargeable_id, from, to)
    Cost.where(:chargeable_type=>chargeable_type, :chargeable_id=>chargeable_id).
      where('valid_from<=? and (valid_to is null or valid_to>=?)', from, to).first
  end

  def calculate(start, stop)
    CostEngine::BillingModel::find(billing_model).calculate(price, start, stop)
  end

  def close
    self.valid_to = Time.now
    save!
  end
end
