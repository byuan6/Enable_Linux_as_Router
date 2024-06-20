#!/bin/bash
# this creates what cisco calls static NAT

# this script was meant to be able to add static NAT associations,
# and remove them dynamically, as scheduled job in linux.  When
# the script realizes it connects w a "friendly wifi", it will enable
# the SNAT relationship.  When it realizes it has connected with
# a wifi, that frowns upon static addresses in it's network, it will
# remove the SNAT relationship

# this script only processes /24 or mask of 255.255.255.0.  Any others
# and it cannot process it correctly.  
date

INSIDE_OCTET=$1
OUTSIDE_OCTET=$2
if [ "$OUTSIDE_OCTET" == "" ]; then
  OUTSIDE_OCTET=$INSIDE_OCTET
fi

if [ "$OUTSIDE_OCTET" == "" ]; then
  echo "Usage: enable_static_nat.sh [device's ipv4 last octet] [SNAT ipv4 last octet]"
  echo "ie. enable_static_nat.sh 50"
  echo "ie. enable_static_nat.sh 50 2"
  echo ""
  echo "this script assumes the inside subnet is on eth0"
  echo "and assumes the outside subnet is on wlan0"
  echo "and you need to change it, if it is different"
  echo "change OUTSIDE=wlan0 to OUTSIDE=[your outside interface]"
  echo "change INSIDE=wlan0 to OUTSIDE=[your outside interface]"
  echo ""
  echo "The reason it doesnt ask for the full IP address as argument"
  echo "...is that it assume the first 3 number of IP4 address is same"
  echo "...as it's own INSIDE address.  If you don't specify a SNAT last octet"
  echo "...in 2nd argument, it will assume you want the last octet to be same"
  echo "...and create IP address of OUTSIDE subnet, with same octet"

  exit 1
fi

# below is only relevant, when routing when using Linux as wifi bridge endpoint
#wlan0     unassociated  ESSID:""  Nickname:"<WIFI@REALTEK>"
#          Mode:Managed  Frequency=2.442 GHz  Access Point: Not-Associated
#          Sensitivity:0/0
#          Retry:off   RTS thr:off   Fragment thr:off
#          Power Management:off
#          Link Quality:0  Signal level:0  Noise level:0
#          Rx invalid nwid:0  Rx invalid crypt:0  Rx invalid frag:0
#          Tx excessive retries:0  Invalid misc:0   Missed beacon:0
# above explains the next line
iwconfig wlan0 | grep 'Not-Associated'
if [ $? -eq 0 ]; then
  # we wait until we know the external subnet, before creating static IP address
  echo wireless is not associated
  exit 1
fi

# below assumes outside interface is WLAN0.  You may change this if you need to
OUTSIDE="wlan0"
OUTSIDE_IP=$(ifconfig $OUTSIDE  | grep -oE 'inet [0-9]+\.[0-9]+\.[0-9]+\.[0-9]+ ' | cut -d' ' -f2)
OUTSIDE_SUBNET=$(ifconfig $OUTSIDE  | grep -oE 'inet [0-9]+\.[0-9]+\.[0-9]+' | cut -d' ' -f2)
# OUTSIDE_SUBNET="192.168.1."
echo "outside interface is $OUTSIDE and uses subnet $OUTSIDE_SUBNET.0/24"

# how to undo static NAT when AP changes, stored in undo file
# executed by this script, when it detects subnet change
UNDO_FILES=$(ls /run/shm/wlan0.*.undo)
if [ "$UNDO_FILES" != "" ]; then
  if  [ -f /run/shm/wlan0.$OUTSIDE_IP.undo ]; then
    echo "subnet unchanged \[/run/shm/wlan0.$OUTSIDE_IP.undo\].  keeping settings"
#    /sbin/ifconfig wlan0
#    /sbin/ifconfig wlan0  | grep -oE 'inet [0-9]+\.[0-9]+\.[0-9]+\.[0-9]+ ' | cut -d' ' -f2
#    /sbin/ifconfig wlan0  | grep -oE 'inet [0-9]+\.[0-9]+\.[0-9]+' | cut -d' ' -f2
    exit 0
  fi
  for f in $UNDO_FILES; do
    echo executing $f
    source /run/shm/$f
    rm /run/shm/$f
  done
fi

# above destroys DNAT, if subnet changed
# after this section, it creates DNAT
# just below,checks if DNAT is allowed in new subnet
#VALID_SUBNET="192.168.1"
VALID_SUBNET="10.0.0"
if [ "$OUTSIDE_SUBNET" != "$VALID_SUBNET" ]; then
  echo "$OUTSIDE_SUBNET is not an allowed subnet for DNAT"
  exit 0
fi
# the above, really should search for the SSID name of iwconfig
# and only when it matches acceptable ssid, allow it to pass here.


#create undo file, for current set of static addresses
UNDO_FILE=/run/shm/wlan0.$OUTSIDE_IP.undo


# what below does, is create static address on this linux machine
# this linux machine should be essentially a router
# another script turns on NAT (port overloading source from eth0, WLAN0 is external)
# this script gives itself several static addresses on wlan0
# when it receives packets on these static addresses on wlan0,
# or receives packets on eth0 whom these static addrc addresses are mapped to
# it should be filtered for processing by /sbin/iptables
# receiving packet w destination to one of the static IP, /sbin/iptables replaces packet's destination to device's real IP
# receiving source w source from device, /sbin/iptables replaces packet source IP with this the static IP on this machine (that corresponds w device).

INSIDE="eth0"
INSIDE_SUBNET=$(ifconfig $INSIDE  | grep -oE 'inet [0-9]+\.[0-9]+\.[0-9]+' | cut -d' ' -f2)
#INSIDE_SUBNET="192.168.255"
echo "inside interface is $INSIDE and uses subnet $INSIDE_SUBNET.0/24"


#next router, (there are 2, this router is not this linux machine, but the soho wifi router)
REAL_INSIDE_IP=$INSIDE_SUBNET.$INSIDE_OCTET
FAKE_DEVICE_IP=$OUTSIDE_SUBNET.$OUTSIDE_OCTET
ping -I wlan0 -c 2 -i 0.3 $FAKE_DEVICE_IP
if [ $? -ne 0 ]; then
  # new static address on this Linux machine
  ifconfig $OUTSIDE add $FAKE_DEVICE_IP
  # DNAT to and from the static machine, to the "internal" device
  /sbin/iptables -t nat -A PREROUTING -i $OUTSIDE -d $FAKE_DEVICE_IP -j DNAT --to-destination $REAL_INSIDE_IP
  /sbin/iptables -t nat -A POSTROUTING -s $REAL_INSIDE_IP -j SNAT --to-source $FAKE_DEVICE_IP
  # creating the entries in undo file to undo this configuration
  printf "/sbin/ifconfig $OUTSIDE del $FAKE_DEVICE_IP\n" >> $UNDO_FILE
  printf "/sbin/iptables -t nat -A PREROUTING -i $OUTSIDE -d $FAKE_DEVICE_IP -j DNAT --to-destination $REAL_INSIDE_IP\n" >> $UNDO_FILE
  printf "/sbin/iptables -t nat -A POSTROUTING -s $REAL_INSIDE_IP -j SNAT --to-source $FAKE_DEVICE_IP\n" >> $UNDO_FILE
else
  echo $FAKE_DEVICE_IP is being used
fi


echo script finshed

