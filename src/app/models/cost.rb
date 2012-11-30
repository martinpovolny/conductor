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

class Cost < ActiveRecord::Base
  attr_accessible :chargeable_id, :chargeable_type, :valid_from, :valid_to,
                  :price, :billing_model

  validates_presence_of :chargeable_id, :chargeable_type, :billing_model,
                        :valid_from
  # valid_to might be null resulting in unlimited validity
  # price might be null for PER_PART billing model

  validate :validate_by_billing_model

  def validate_by_billing_model
    if billing_model != 'per_property' and price.blank?
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
