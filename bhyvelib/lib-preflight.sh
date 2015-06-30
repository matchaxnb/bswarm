#!/bin/sh
# by Chloé Tigre Rouge <chloe@tigres-rouges.net>
# MIT License - see LICENSE

# This is all the pre-flight checks 
# and generations before running a bhyve VM

# create the bridges with
#    ovs-vsctl add-br vmexternal -- set bridge vmexternal datapath_type=netdev
#    ovs-vsctl add-br vminternal -- set bridge vminternal datapath_type=netdev
check_zvol()
{
  if [ ! -c /dev/zvol/${ZVOL} ]; then
    echo "zvol ${ZVOL} does not exist. Please provision it using"
    echo "zfs create -V SIZE_IN_G ${ZVOL}"
    return 1
  fi
  return 0
}

generate_device_map()
{
  cat > /tmp/${VMNAME}.device.map <<EOF
(hd0) /dev/zvol/${ZVOL}
(cd0) ${ISO}
EOF
  return $?
}

_provision_iface()
{
  IFNAME=$1
  
  echo "Provisioning $IFNAME"
  IFCREATED=$(ifconfig tap create)
  echo "Created $IFCREATED"
  ifconfig $IFCREATED name $IFNAME
  echo "Renamed $IFCREATED to $IFNAME"
  ln -sf /dev/$IFCREATED /dev/$IFNAME
}

_assign_network_tag()
{
  PORT=$1
  VLAN=$2
  echo "Assigning port $PORT to vlan $VLAN"
  ovs-vsctl set port $PORT tag=$VLAN
}

_add_to_bridge()
{
  BR=$1
  PORT=$2
  echo -n "Removing port if exists..."
  ovs-vsctl del-port $PORT
  echo "[DONE]"
  OUTPUT=$(ovs-vsctl add-port $BR $PORT 2>&1)
  ERRCODE=$?
  echo "Added port $PORT to bridge $BR: $OUTPUT"
  if [ $ERRCODE -ne 0 ]; then
    echo $OUTPUT
    return 1
  fi
  return 0
}

check_and_make_interfaces()
{
  EXTIF=$(echo $EXTERNAL_IFACE | cut -d, -f1)
  INTIF=$(echo $INTERNAL_IFACE | cut -d, -f1)
  if [ -n "$EXTIF" ]; then
    ifconfig $EXTIF 2>/dev/null
    if [ $? = 1 ]; then
      echo "Provisioning $EXTIF"
      _provision_iface $EXTIF
    fi
    _add_to_bridge vmexternal $EXTIF
    if [ -n "$EXT_VLANTAG" ]; then
      _assign_network_tag $EXTIF $EXT_VLANTAG
    fi
  fi

  if [ -n "$INTIF" ]; then
    ifconfig $INTIF 2>/dev/null
    if [ $? = 1 ]; then
      echo "Provisioning $INTIF"
      _provision_iface $INTIF
    fi
    _add_to_bridge vminternal $INTIF
    if [ -n "$INT_VLANTAG" ]; then
      _assign_network_tag $INTIF $INT_VLANTAG
    fi
  fi
}

# nmdm devices are automatically allocated
allocate_console()
{
  NEXT_NMDM=$(( $(ls /dev/nmdm*A | sed s@/dev/nmdm@@g | sed s/A//g | sort -n | tail -n 1 ) + 1))
  echo "NMDM:$NEXT_NMDM" >&2
  ls /dev/nmdm${NEXT_NMDM}A
}

# before grubbing the OS
pre_load_checks()
{
  check_zvol
  ZV=$?
  if [ $ZV -eq 0 ]; then
    generate_device_map
    return $?
  else
    exit 1
  fi

}

# before actually starting the OS
pre_start_checks()
{
  if [ ! -n "$NMDMDEVICE" ]; then
    NMDMDEVICE=$(allocate_console)
  fi
  check_and_make_interfaces
  
  # now check all mandatory variables
  if [ ! -n "$CORES" -a -n "$RAM" -a -n "$INTERNAL_IFACE" -a -n "$EXTERNAL_IFACE" -a -n "$ZVOL" -a -n "$VMNAME" ]; then
    printf "Mandatory variables missing:\nCORES:\t\t$CORES\nRAM:\t\t$RAM\nINTERNAL_IFACE:\t$INTERNAL_IFACE\
    \nEXTERNAL_IFACE:\t$EXTERNAL_IFACE\nZVOL:\t\t$ZVOL\nVMNAME:\t\t$VMNAME\n"
    exit 1
  fi

  return 0
}
