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
* As a manager I want so see how much did the running of each deployable and instance cost and how it was estimated. 
* As an administrator I want to assign costs to each hw profile at given provider.

Future usecases: 
* As a manager I want Conductor to select providers based on cost estimates.
* As a user I want Conductor to automaticaly download costs from providers.

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
   chargeable_type  { :hardware_profile, :bandwidth, :storage ... }
   chargeable_id    link to hw_profile or other resource representation
   unit?
   valid_from
   valid_to

 constraints:
   chargeable_id, chargeable_type is unique in given range (valid_from, valid_to)
   chargeable_id is a partial foreign key for entity determined by chargeable_type


API
---

 Standalone: 
  get_cost_for_unit( chargeable_type, chargeable_id, when=now() ) 
    get cost of an chargeable (hardware profile) at given time

 Conductor integration:

  get_cost_for_instance( instance_id )
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
provide billing information in form of CSV files. Further means of retrieving
cost and billing information have to be researched.

We probably should include some values from the most popular providers in the
instalation packages.

