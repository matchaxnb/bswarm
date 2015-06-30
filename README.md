BSwarm
======

BSwarm is a wrapper for bhyve, the FreeBSD hypervisor. It is still very early
stage and the UX is not the best in the world. Yet, it works and makes stuff
a little bit easier when it comes to starting plain VMs.

It can run Linux or native (i.e. FreeBSD) guests. It has tools to generate
ISC-DHCPD config files that will allocate an IP for each VM. It will not take
complete care of routing and stuff, this is left as an exercise to the user. 
However feel free to send a pull-request if you want to do so.

The current implementation uses OpenVswitch and zvols. Feel free to fork it to
use standard bridging or other networking options, block devices or image files.

Dependencies
============

* bhyve
* OpenvSwitch
* ZFS

How to use ?
============

Read the script files :-)

Write configuration files for your VMs or take one from the examples/ directory 
and tweak it. 

Networking
==========

If you want to generate a network configuration
Generate a DHCPD config using the provided script if you want to 
use this feature. Call the bhyve-load.sh script 

History
=======
BSwarm is a recreation of a project in a company I used to work for. It 
never came into production because this did not match this employer's strategy.

Still I find it useful and want to give it to the community as the FreeBSD
hypervisor is still very much of an unexplored field.

Authors
=======

Chloé "Tigre Rouge" Desoutter <chloe@tigres-rouges.net>

License
=======

MIT license
