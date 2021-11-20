#!/usr/bin/nft -f

flush ruleset

table inet filter {
  chain input {
    type filter hook input priority 0; policy drop;

    # allow established/related connections
    ct state {established, related} accept

    # early drop of invalid connections
    ct state invalid drop

    # allow from loopback
    iifname lo accept

    # Allow from internal network
    iifname lan accept

    # allow icmp
    ip protocol icmp accept

    # allow ssh
    tcp dport 22 accept comment "SSH in"

    reject
  }

  chain forward {
    type filter hook forward priority 0;

    # Allow outgoing via wan0
    oifname wan accept

    # Allow incoming on wan0 for related & established connections
    iifname wan ct state related, established accept

    # Drop any other incoming traffic on wan0
    iifname wan drop
  }

  chain output {
    type filter hook output priority 0;
  }

}

table ip nat {
  chain prerouting {
    type nat hook prerouting priority 0;

    # Forward traffic from wan0 to a LAN server
    iifname wan tcp dport 80 dnat 192.168.5.200 comment "Port forwarding to web server"
  }

  chain postrouting {
    type nat hook postrouting priority 0;

    # Masquerade outgoing traffic
    oifname wan masquerade
  }
}
