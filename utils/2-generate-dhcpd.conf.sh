#!/bin/sh
# by Chloé Tigre Rouge <chloe@tigres-rouges.net>
# MIT License - see LICENSE
# generates an isc dhcpd config to allocate IPs to VMs.

# usage: cat generated-map-file | $0

#config 
DNS_SERVERS="4.2.2.1, 4.2.2.2"


#perform
EXT_IP=$(ifconfig $(/sbin/route -n get 4.2.2.1 | grep 'interface:' | awk '{print $2}') | grep -v inet6 | grep inet | awk '{print $2}')
IFS=. read a b c d <<IP
$EXT_IP
IP
export a b c d 
cat <<EOF 
shared-network VMS {
  option domain-search "your.vm.domain";
  option domain-name-servers $DNS_SERVERS;
# subnet 0.0.0.0 netmask 0.0.0.0 {
# range start end;
# }
  subnet $EXT_IP netmask 255.255.255.255 {}

EOF
while read VMMAC VMIP VMNAME; do
  IFS=. read e f g h <<IP2
$VMIP
IP2
  cat <<EOL
  host $VMNAME {
    hardware ethernet $VMMAC;
    fixed-address $VMIP;
    option routers $EXT_IP;
    option rfc-routes 32, $a, $b, $c, $d, $e, $f, $g, $h, 0, $a, $b, $c, $d;
    option no-rfc-routes 32, $a, $b, $c, $d, $e, $f, $g, $h, 0, $a, $b, $c, $d;
  }
  subnet $VMIP netmask 255.255.255.255 { range $VMIP $VMIP; }

EOL
done 
echo '}'
