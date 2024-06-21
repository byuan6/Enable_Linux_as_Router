# Enable_Linux_as_Router
Shell scripts to enable Linux to forward packets, do Port-Address NAT, and Address Static NAT

## Please enable the shell scripts to be executed
```
chmod +x enable_as_nat_router.sh
chmod +x enable_static_nat.sh
```

## enable_as_nat_router.sh
execute without arguments on linux machine, to enable routing and NAT capability
assume wlan0 is WAN interface
assume eth00 is LAN interface
DOES NOT SAVE iptables changes
BUT ip_forwarding is saved
**Usage:** To turn on routing, activate NAT with wlan0 as WAN, and eth0 as LAN
```
sudo ./enable_as_nat_router.sh
```

**Usage:** To change script with different interfaces for WAN and LAN.  Replace WAN and LAN with interface names, obtained with *ifconfig* or *ip addr* 
```
sed -i 's/wlan0/WAN/g;s/eth0/LAN/g' enable_as_nat_router.sh
```
```
sudo ./enable_as_nat_router.sh
```

## enable_static_nat.sh
execute to enable static NAT on Linux
arg1: last octet of device on LAN to create a SNAT for
arg2: (optional)last octet of new IP address to be created on this Linux machine acting as router
assume wlan0 is WAN interface
assume eth00 is LAN interface
DOES NOT SAVE iptables changes

**Usage:** To give a static NAT to device with IP address <LAN_subnet>.2, by adding IP Address <WAN_subnet>.2 to router and configuring for SNAT
```
sudo ./enable_static_nat.sh 2
```

**Usage:** To give a static NAT to device with IP address <LAN_subnet>.2, by adding IP Address <WAN_subnet>.3 to router and configuring for SNAT
```
sudo ./enable_static_nat.sh 2 3
```


**Usage:** To change script with different interfaces for WAN and LAN.  Replace WAN and LAN with interface names, obtained with *ifconfig* or *ip addr* 
```
sed -i 's/wlan0/WAN/g;s/eth0/LAN/g' enable_static_nat.sh
```
```
sudo ./enable_static_nat.sh 2
```

### Will reassign static NAT, if it detects WAN subnet changes, upon next execution
if WAN was 192.168.1.0/24, and changes to 172.16.16/0/24, because wifi was connect to different AP, this script will drop or re-create the WAN IP addresses to fit new subnet.  This script was built to be run by crontab, to execute every 5min, to check for WAN subnet changes.
