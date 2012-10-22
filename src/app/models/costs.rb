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

class Costs < ActiveRecord::Base
  attr_accessible :chargeable_id, :chargeable_type, :valid_from, :valid_to
end
