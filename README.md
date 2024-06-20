# Enable_Linux_as_Router
Shell scripts to enable Linux to forward packets, do Port-Address NAT, and Address Static NAT

## enable_as_nat_router.sh
execute without arguments on linux machine, to enable routing and NAT capability
assume wlan0 is WAN interface
assume eth00 is LAN interface
DOES NOT SAVE iptables changes
BUT ip_forwarding is saved

## enable_static_nat.sh
execute to enable static NAT on Linux
arg1: last octet of device on LAN to create a SNAT for
arg2: (optional)last octet of new IP address to be created on this Linux machine acting as router
assume wlan0 is WAN interface
assume eth00 is LAN interface
DOES NOT SAVE iptables changes

