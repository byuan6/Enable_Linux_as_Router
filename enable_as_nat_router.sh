#!/bin/bash

# forwarding packets from 1 to another is controlled by uncommenting the configuraton below
# this really only needs to done done once, but there is no harm checking
# this line essentially controls if routing is turned on or off,
# when receiving packets, not intended for itself
sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g' /etc/sysctl.conf

# below implements what cisco calls (Port overloading, Source NAT)
# using iptables, the any packet's source IP address and port
# entering eth0 AND exiting WLAN0, is replaced with
# this Linux machine's WLAN0 address, and a port# re-assigned
# and any packets set to this WLAN0 address, with above port#
# is sent out eth0 with original IP and port, again. What everyone calls NAT.
# change the interfaces, in the direction you want to do NAT.
EXTERNAL=wlan0
INTERNAL=eth0

iptables -t nat -A POSTROUTING -o $EXTERNAL -j MASQUERADE
iptables -A FORWARD -i $EXTERNAL -o $INTERNAL -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i $INTERNAL -o $EXTERNAL -j ACCEPT

#uncomment below to save the rule changes
#otherwise, you need to keep running the script after each reboot, to reapply the changes
# iptables-save

#uncomment the 2x ip route lines below, if you know how routing works
#and want linux to divide your network into subnets
#the two lines below, read "any packets sent to 10.0.1.0/24, send out eth0, and direct at 192.168.1.50's MAC address"
# ip route add to 10.0.1.0/24 nexthop via 192.168.1.50
# ip route add to 10.0.1.0/24 nexthop dev eth0

# route add -net <ip_address> netmask <netmask_address_here> gw <gw_address_here>

