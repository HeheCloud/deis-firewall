#!/bin/env bash

iptables -A INPUT -s 10.0.0.0/8 -p tcp -m multiport --dports 2379,4001 -j ACCEPT
iptables -A INPUT -s 172.16.0.0/12 -p tcp -m multiport --dports 2379,4001 -j ACCEPT
iptables -A INPUT -s 192.168.0.0/16 -p tcp -m multiport --dports 2379,4001 -j ACCEPT
iptables -A INPUT -s 240.0.0.0/5 -p tcp -m multiport --dports 2379,4001 -j ACCEPT
iptables -A INPUT -s 224.0.0.0/4 -p tcp -m multiport --dports 2379,4001 -j ACCEPT
iptables -A INPUT -p tcp -m multiport --dports 2379,4001 -j DROP
