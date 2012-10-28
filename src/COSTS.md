Costs Engine
============

Summary
-------
This document proposes the design of a cost estimation engine for Aeolus Conductor.

Owner
-----
Martin Povolny

Current Status
--------------

Design.

Some Use Cases
--------------

* As an administrator, I want to assign costs to a provider's hardware profiles
* As a user, I want to see costs for my running instances and deployables, and for instances and deployables which have run previously.
* As a manager, I want to see costs for all users' running instances and deployables, and for instances and deployables which have run previously
* As an administrator, I want to see costs of running a deployable on available providers


Future usecases: 
* As a manager I want Conductor to select providers based on cost estimates.
* As an administrator I want Conductor to automaticaly download costs from providers.

Design
------

Costs will be associated with various 'chargeables'. 

Chargeables include in the first run only:
  * a hour of run of given backend hardware profile.

Chargeables could include in the future:
  * unit of usage of bandwidth,
  * unit of usage of storage,
  * unit of usage of IP assignment,
  * backups, load balancers, dababase access,
  * etc.

A module (rails engine or library) will be created with a model called 'costs'. 

Each cost is associated with a chargeable (chargeable_id) of certain type (chargeable_type).

And is valid at a certain time (valid_from, valid_to). 

Unlimited validity is expressed by assiging NULL to valid_to.

Through the chargeable each cost is attached to a certain provider.

at given time:
provider <--- 1:n ---> chargeable (backend hw_profile) <--- 1:1 ----> cost

generally:
provider <--- 1:n ---> chargeable (backend hw_profile) <--- 1:n ----> cost

 Changes in Conductor data model:
 --------------------------------

  investigate history! -- 
	where is the run history stored?
		instance( time_last_running, time_last_stopped ) -- the instance remains the same, the 
		instance_match gets created new, but missing the atributes

	probably have to add start/stop time to InstanceMatch model

  
 Integrating Costs into Conductor routines
 -----------------------------------------
 
 a) via Decorator pattern

	instance_match = CostEngine::Decorators::InstanceMatch.new( InstanceMatch.find(:all)[0] )
	p instance_match.cost
 
 b) extend class with Mixin
	
	class InstanceMatch
	  extend CostEngine::Mixins::InstanceMatch
	end

	instance_match.cost

 c) more ways to do that...

 both a) b) introduce dependance Conductor ==> CostEngine thank to late binding 
 b) requires less change do Conductor to use the cost (mostly you can just change Views wheres with 
	

Placement in the UI
-------------------

* newly created portlets could include some cost information
  * total costs in given interval (today, this week, per provider, environment, etc.)

* url /deployments/#{id} in "Instances" -- estimate
* url /deployments/#{id} in "Properties", "History" -- current and past costs

* /catalogs/1/deployables/2 could display information for the deployable in whole and 
  for individual images for each possible provider


Tech Notes
----------

 costs
   cost_id
   chargeable_type  ( hardware_profile | bandwidth | storage ... )
   chargeable_id    link to hw_profile or other resource representation
   unit?	    hour, GB
   billing_strategy per_hour, per_minute, per_wall_clk_hour ? (to support EC2 at least per_wall_clk_hour is needed)
	
   valid_from
   valid_to
   currency?
   price

 constraints:
   chargeable_id, chargeable_type is unique in given range (valid_from, valid_to)
   chargeable_id is a partial foreign key for entity determined by chargeable_type


API
---

 Standalone: 
  get_cost_for_unit( chargeable_type, chargeable_id, when=now() ) 
    get cost of an chargeable (hardware profile) at given time

 Conductor integration:
  hardware_profile.cost
    hom much does a unit of run of this hardware_profile cost?

  instance_match.cost / instance.cost
    how much did this instance cost?
  
  get_cost_history( deployable )
    how much did individual runs of this deployable cost in the past?

  and more...

Notes and further work
----------------------

The entering of cost estimates for chargeables in Conductor has to be detailed. 

In the first iteration we care only about backend hardware profile so we have
to provide a list of available hardware profiles per cloud provider with the
cost and provide a form to enter the costs.

There's no official API for getting cost information.

EC2 has an unofficial page that serves basic cost information in JSON. EC2 also
provides billing information in form of CSV files. Further means of retrieving
cost and billing information have to be researched.

We probably should include some values from the most popular providers in the
instalation packages.

