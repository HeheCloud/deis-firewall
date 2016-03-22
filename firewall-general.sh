#!/bin/env bash

# exit 0
echo "Creating firewall Rules..."
# Firewall Template
template=$(cat <<EOF
*filter


:INPUT DROP [0:0]
:FORWARD ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
:Firewall-INPUT - [0:0]
-A INPUT -j Firewall-INPUT
-A FORWARD -j Firewall-INPUT
-A Firewall-INPUT -i lo -j ACCEPT
-A Firewall-INPUT -p icmp --icmp-type echo-reply -j ACCEPT
-A Firewall-INPUT -p icmp --icmp-type destination-unreachable -j ACCEPT
-A Firewall-INPUT -p icmp --icmp-type time-exceeded -j ACCEPT

# Ping
-A Firewall-INPUT -p icmp --icmp-type echo-request -j ACCEPT

# Accept any established connections
-A Firewall-INPUT -m conntrack --ctstate  ESTABLISHED,RELATED -j ACCEPT

# Enable the traffic between the nodes of the cluster
-A Firewall-INPUT -s 10.0.0.0/8 -j ACCEPT
-A Firewall-INPUT -s 172.16.0.0/12 -j ACCEPT
-A Firewall-INPUT -s 192.168.0.0/16 -j ACCEPT
-A Firewall-INPUT -s 240.0.0.0/5 -j ACCEPT
-A Firewall-INPUT -s 224.0.0.0/4 -j ACCEPT

# Allow connections from docker container
-A Firewall-INPUT -i docker0 -j ACCEPT
-A Firewall-INPUT -o docker0 -j ACCEPT
# -A Firewall-INPUT -i eth+ -j ACCEPT
# -A Firewall-INPUT -i veth+ -j ACCEPT
# -A Firewall-INPUT -i flannel+ -j ACCEPT

# Accept ssh, http, https and git
-A Firewall-INPUT -m conntrack --ctstate NEW -m multiport -p tcp --dports 22,2222,80,443,8080,10080 -j ACCEPT

# Log and drop everything else
-A Firewall-INPUT -j LOG
-A Firewall-INPUT -j REJECT


:DOCKER - [0:0]
-A FORWARD -o docker0 -j DOCKER
-A FORWARD -o docker0 -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
-A FORWARD -i docker0 ! -o docker0 -j ACCEPT
-A FORWARD -i docker0 -o docker0 -j ACCEPT

COMMIT
EOF
)

if [[ -z "$DEBUG" ]]; then
  echo "$template"
fi

echo "Saving firewall Rules"
echo "$template" | sudo tee /var/lib/iptables/rules-save > /dev/null

echo "Enabling iptables service"
sudo systemctl enable iptables-restore.service

# Flush custom rules before the restore (so this script is idempotent)
sudo /usr/sbin/iptables -F DOCKER 2> /dev/null
sudo /usr/sbin/iptables -F Firewall-INPUT 2> /dev/null

echo "Loading custom iptables firewall"
sudo /sbin/iptables-restore --noflush /var/lib/iptables/rules-save

echo "Done"
