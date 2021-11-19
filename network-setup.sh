#!/bin/sh
#####################################
# EPJ - SystemD Network SETUP       #
#     - version 0.1                 #
#     - Date 19 November 2021       #
##############################################################################
# SETTING - INTERFACE MAC           (Enter the physical Hardware MAC address)#
#                     NAME          (Define the name Interface)              #
#                     IPv4          (Enter IPv4)                             #
#                     NETMASK       (Enter the Netmask  slash notation CIDR) #
#                     GATEWAY       (Enter the Gateway default route)        #
##############################################################################
### ETHERNET CARDS ASSIGNATIONS ##############################################
eth1-mac=""
eth1-name="wan"
eth1-ip=""
eth1-mask="32"
eth1-gw=""

eth2-mac=""
eth2-name="lan"
eth2-ip=""
eth2-mask="24"
eth2-gw=""
##############################################################################
### REMOVE Autoname ethernet configuration
rmautoname=/etc/udev/rules.d/80-net-name-slot.rules
touch $rmautoname
ln -s /dev/null $rmautoname

### CREATE udev rules and define interface name manually
echo "\
SUBSYSTEM=="net", ATTRS{address}=="$eth1-mac", NAME="$eth1-name" \
SUBSYSTEM=="net", ATTRS{address}=="$eth2-mac", NAME="$eth2-name" \
" > /etc/udev/rules.d/10-network.rules


### CREATE SYSTEMD Network Service
echo "\
[Unit]
Description=Network Connectivity
Wants=network.target
Before=network.target
BindsTo=sys-subsystem-net-devices-network.device
After=sys-subsystem-net-devices-network.device

[Service]
Type=oneshot
RemainAfterExit=yes

# Fixed IP address for $eth1-name + $eth2-name
ExecStart=/sbin/ip link set dev $eth1-name up
ExecStart=/sbin/ip link set dev $eth2-name up
ExecStart=/sbin/ip addr add $eth1-name-ip/$eth1-name-mask dev $eth1-name
ExecStart=/sbin/ip addr add $eth2-name-ip/$eth2-name-mask dev $eth2-name

# Define DEFAULT Gateway for $eth1-name
ExecStart=/sbin/ip route add default via $eth1-name-gw dev $eth1-name onlink

# Flush and Interface down AFTER SystemD service STOP
ExecStop=/sbin/ip addr flush dev $eth1-name
ExecStop=/sbin/ip addr flush dev $eth2-name
ExecStop=/sbin/ip link set dev $eth1-name down
ExecStop=/sbin/ip link set dev $eth2-name down

[Install]
WantedBy=multi-user.target
" > /etc/systemd/system/network.service
systemctl enable network.service
reboot
