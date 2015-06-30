#!/bin/sh
# By Chloé Tigre Rouge <chloe@tigres-rouges.net>
# MIT License - see LICENSE

# load a bhyve config and start-up the thing
BHYVEMODE=$1
BHYVECONF=$2
IMMEDIATESTART=$3
usage(){
  echo "Usage:"
  echo "$0 -b <bhyve-config> [--nostart]: bootstrap this bhyve config"
  echo "$0 -s <bhyve-config> [--nostart]: prepare starting an already bootstrapped bhyve config"
  echo "$0 --shutdown <bhyve-config>: shutdown a VM"
  echo "$0 --start <bhyve-config>: start a prepared bhyve config"
  echo "[--nostart] for -b and -s prevents the bhyve config from starting immediately. Useful for debugging only."
  echo "--start can only be run after either -b or -s have been called."
}

do_startup()
{
  pre_start_checks
  RES=$?
  if [ $RES -ne 0 ]; then
    echo "pre_start_checks failed"
    exit 1
  fi

  bhyve -c $CORES -m ${RAM}M -P -A \
  	-s 15,lpc -l com1,${NMDMDEVICE} \
  	-s 0,hostbridge \
  	-s 1,virtio-blk,/dev/zvol/${ZVOL} \
  	-s 2,virtio-net,${INTERNAL_IFACE} \
  	-s 3,virtio-net,${EXTERNAL_IFACE} \
  	-s 4,ahci-cd,${ISO} \
  	${VMNAME} &
  BHYVEPID=$$
  echo "[bhyve PID: $BHYVEPID]"
  echo "[You will connect.]"
  echo "cu -l $(echo ${NMDMDEVICE} | sed s/A/B/) -s 19200" > /tmp/$VMNAME.go-console
  sh /tmp/$VMNAME.go-console
}
# parse parameters

# check if conf exists
if [ ! -f $BHYVECONF ]; then
  echo "File not found $BHYVECONF" >&2
  return 1
fi

# check bhyvemode
if [ ! -n "$BHYVEMODE" ]; then
  usage;
  exit 1;
fi
if [ -n "$BHYVEMODE" ]; then
  if [ "-b" = "$BHYVEMODE" ]; then
    MODE="bootstrap"
  elif [ "-s" = "$BHYVEMODE" ]; then
    MODE="start"
  elif [ "--start" = "$BHYVEMODE" ]; then
    MODE="fire"
  elif [ "--shutdown" = "$BHYVEMODE" ]; then
    MODE="shutdown"
  else 
    usage;
    exit 1
  fi
fi
echo "Mode: $MODE"

SCRIPTS_DIR=/home/chloe/bhyvelib
. ${SCRIPTS_DIR}/lib-preflight.sh

# load bhyve config
. $BHYVECONF

# perform
if [ $MODE = "start" ]; then
  echo "Boot preflight"
  pre_load_checks
  if [ $? -ne 0 ]; then
    echo "pre_load_checks failed. Exiting"
    exit 1
  fi

  bhyvectl --vm=$VMNAME --destroy || echo "VM was not already started"
  echo "OS type: $OS_TYPE"
  read fu
  if [ "$OS_TYPE" = "native" ]; then
    bhyveload -d /dev/zvol/$ZVOL -m $RAM $VMNAME
  else
    grub-bhyve -r $BOOTDEVICE -m /tmp/${VMNAME}.device.map -M $RAM $VMNAME
  fi
elif [ $MODE = "bootstrap" ]; then
  set -x
  echo "Bootstrap preflight"
  pre_load_checks
  bhyvectl --vm=$VMNAME --destroy || echo "VM was not already started"
  if [ "$OS_TYPE" = "native"]; then
    bhyveload -m $RAM -d $ISO $VMNAME
  else
    grub-bhyve -r cd0 -m /tmp/${VMNAME}.device.map -M $RAM $VMNAME
  fi
elif [ $MODE = "shutdown" ]; then
  echo "Shutting down"
  bhyvectl --vm=$VMNAME --force-poweroff
  IMMEDIATESTART="--nostart"
fi
if [ $MODE = "fire" -o "--nostart" != "$IMMEDIATESTART" ]; then
  echo "Starting up";
  do_startup;
fi

