#!/bin/bash

# Firstly i am generating a system report.
 
# System Information
system_info=$(cat <<EOF
---------------------
System Information
---------------------

Hostname: $(hostname)
Operating System: $(source /etc/os-release && echo \$PRETTY_NAME)
Uptime: $(uptime -p)
---------------------
EOF
)
echo "$system_info"

#Hardware Information
# Here I gathered the required information for hardware section.
cpu_model=$(hwinfo --cpu | grep "Model" | awk -F': ' '{print $2}')
cpu_speed=$(hwinfo --cpu | grep "Speed" | awk -F': ' '{print $2}')
cpu_max_speed=$(hwinfo --cpu | grep "Max" | awk -F': ' '{print $2}')
ram=$(hwinfo --memory | grep "Size" | awk -F': ' '{print $2}')
disks=$(hwinfo --block --short | grep "Model" | awk -F': ' '{print $2}')
video_card=$(hwinfo --gfxcard | grep "Model" | awk -F': ' '{print $2}')

# Now, assembling the information 
hardware_info=$(cat <<EOF
Hardware Information
---------------------
CPU: $cpu_model
Speed: $cpu_speed
MAX Speed: $cpu_max_speed
RAM: $ram
Disks: $disks
Video card: $video_card
---------------------
EOF
)
echo "$hardware_info"


# Network Information
echo "Network Information"
echo "---------------------"

# FQDN (Fully Qualified Domain Name)
fqdn=$(hostname -f)
echo "FQDN: $fqdn"

interface=$(ip r | awk '/default/ {print $5}')
host_address=$(ip a show dev "$interface" | awk '/inet / {print $2}')
echo "Host Address: $host_address"

gateway_ip=$(ip r | awk '/default/ {print $3}')
echo "Gateway IP: $gateway_ip"

dns_server=$(grep -E '^nameserver' /etc/resolv.conf | awk '{print $2}')
echo "DNS Server: $dns_server"

echo "Network Interface Information:"
sudo lshw -class network | grep E 'description|product|vendor|physical id|ogical name' | awk -F ':' '{print $1 ": " $2}'

echo "IP Address: $host_address"
echo "---------------------"




# System Status
echo "System Status"
echo "---------------------"

users_logged_in=$(who | awk '{print $1}' | sort | uniq | paste -s -d ',')
echo "Users Logged In: $users_logged_in"

echo "Disk Space:"
df -h

process_count=$(ps -e | wc -l)
echo "Process Count: $process_count"

load_averages=$(uptime | awk -F'[a-z]:' '{print $2}')
echo "Load Averages: $load_averages"
echo "Memory Allocation:"
free -h | awk '/^Mem:/ {print "Type\tTotal\tAvailable"; print $1 "\t" $2 "\t" $7}'
echo "Listening Network Ports:"
ss -tuln | awk 'BEGIN {print "State\tRecv-Q\Send-Q\tLocal Address:Port\tPeer Address:Port"} /LISTEN/ {print $1 "\t" $2 "\t" $3 "\t" $4 "\t\" $5}'

ufw_rules=$(sudo ufw status numbered | grep -v 'Status: active')
echo "UFW Rules: $ufw_rules"

echo "---------------------"


