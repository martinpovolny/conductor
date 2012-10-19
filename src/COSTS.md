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

* As a user I want to see cost estimates of deployables to run on matching providers.
* As a manager I want Conductor to select providers based on cost estimates.
* As a manager I want so see how much did the running of each deployable and instance cost and how it was estimated. 
* As an administrator I want to assign costs to each hw profile at given provider.

Design
------

A rails engine will be created with a model called 'costs'. Cost assing costs to various assets(accountables?) like hardware profiles, bandwidth, ip address etc.

	* The cost is attached to an asset (asset_id) of certain type (asset_type).
	* The cost is valid in certain time (valid_from, valid_to).
	* Through the asset cost is attached to a certain provider.

provider <--- 1:n ---> backend hw_profile <--- 1:1 ----> cost


Notes
-----

no API for billing?

in future: 
* As a user I want Conductor to automaticaly download costs from providers.

Tech Notes
----------

 costs
   cost_id
   asset_type	{ :hardware_profile, :bandwidth, :storage ... }
   asset_id		link to hw_profile or other resource representation
   unit?
   valid_from
   valid_to

   asset_id, asset_type is unique in giver range (valid_from, valid_to)

 get_cost_for_unit( asset_type, asset_id when=now() ) 
		get cost of an asset (hardware profile) at given time

-----------

 get_cost_for_instance( instance_id )
		how much did this instance cost?

 get_cost_history( deployable )
		how much did individual runs of this deployable cost in the past?
   
   
 calculate cost of given instance (running at given time with given resources {hwprofile, bandwidth, storage...})
