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
eth1mac=""
eth1name="wan"
eth1ip=""
eth1mask="32"
eth1gw=""

eth2mac=""
eth2name="lan"
eth2ip=""
eth2mask="24"
eth2gw=""
##############################################################################
### REMOVE Autoname ethernet configuration
rmautoname=/etc/udev/rules.d/80-net-name-slot.rules
touch $rmautoname
ln -s /dev/null $rmautoname

### CREATE udev rules and define interface name manually
echo "\
SUBSYSTEM=="net", ATTRS{address}=="$eth1mac", NAME="$eth1name" \
SUBSYSTEM=="net", ATTRS{address}=="$eth2mac", NAME="$eth2name" \
" > /etc/udev/rules.d/10-network.rules

### CREATE SYSTEMD Network Service
echo "\
[Unit]
Description=Network Connectivity
Wants=network.target
Before=network.target

[Service]
Type=oneshot
RemainAfterExit=yes

# Fixed IP address for $eth1name + $eth2name
ExecStart=/sbin/ip link set dev $eth1name up
ExecStart=/sbin/ip link set dev $eth2name up
ExecStart=/sbin/ip addr add $eth1ip/$eth1mask dev $eth1name
ExecStart=/sbin/ip addr add $eth2ip/$eth2mask dev $eth2name

# Define DEFAULT Gateway for $eth1name
ExecStart=/sbin/ip route add default via $eth1gw dev $eth1name onlink

# Flush and Interface down AFTER SystemD service STOP
ExecStop=/sbin/ip addr flush dev $eth1name
ExecStop=/sbin/ip addr flush dev $eth2name
ExecStop=/sbin/ip link set dev $eth1name down
ExecStop=/sbin/ip link set dev $eth2name down

[Install]
WantedBy=multi-user.target
" > /etc/systemd/system/network.service
systemctl enable network.service
reboot
