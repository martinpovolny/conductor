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
  attr_accessible :chargeable_id, :chargeable_type, :valid_from, :valid_to, :price, :billing_model

  def self.find_by_chargeable_and_time_range( ch_type, ch_id, from, to )
    #p ['find_by_chargeable_and_time_range', ch_type, ch_id, from, to ]
    # FIXME: can rewrite to SQL
    cost_candidates = Cost.find_all_by_chargeable_type_and_chargeable_id( ch_type, ch_id )
    #p ['cost_candidates', cost_candidates]
    cost_candidates = cost_candidates.find_all { |candidate| candidate.valid_from <= from and ( candidate.valid_to.nil? or candidate.valid_to >= to ) }
    #p ['cost_candidates 2', cost_candidates]
    # assert( cost_candidates.length <= 1 )
    cost_candidates[0]
  end
end
