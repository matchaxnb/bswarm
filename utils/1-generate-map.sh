#!/bin/sh
# by Chloé Tigre Rouge <chloe@tigres-rouges.net>
# MIT License - see LICENSE
# generate a mac => wanted IP mapping file from the bswarm configuration files.

VM_PATH="~/bswarm/vms/"

find $VM_PATH -name *.conf | while read conf; do
  unset EXTERNAL_IFACE
  unset WANTED_IP
  unset VMNAME
  . $conf || continue
  EXT_MAC=$(echo $EXTERNAL_IFACE | cut -d, -f2 | cut -d= -f2)
  echo $EXT_MAC  $WANTED_IP $VMNAME
done 
