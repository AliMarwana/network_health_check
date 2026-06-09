#!/bin/bash
declare -a network_health_check=()

#info of server information
server_info=()
server_info+=("=== Server Information ===")
server_info+=("Hostname: $(hostname)")
server_info+=("Current User: $(whoami)")
server_info+=("Date and Time: $(date)")
network_health_check+=(server_info)
for info in "${server_info[@]}"; do
    echo "• $info"
done

#info of network information
network_info=()
network_info+=("=== Network Information ===")
# IP Address (primary interface)
IP_ADDRESS=$(hostname -I | awk '{print $1}')
network_info+=("IP Address:    $IP_ADDRESS")


# Default Gateway
DEFAULT_GATEWAY=$(ip route | grep default | awk '{print $3}')
network_info+=("Default Gateway: $DEFAULT_GATEWAY")

# DNS Servers
DNS_SERVERS=$(grep -v '^#' /etc/resolv.conf | grep nameserver | awk '{print $2}' | tr '\n' ' ')
network_info+=("DNS Server(s): $DNS_SERVERS\n")
network_health_check+=(network_info)
for info in "${network_info[@]}"; do
    echo "• $info"
done
#info of internet connectivity
ping -c 1 8.8.8.8 > /dev/null 2>&1
internet_connectivity=("=== Check Internet Connectivity ===")
if [ $? -eq 0 ]; then
    internet_connectivity+=("Internet Connectivity: UP")
else
    internet_connectivity+=("Internet Connectivity: DOWN")
fi
network_health_check+=(internet_connectivity)
for info in "${internet_connectivity[@]}"; do
    echo "• $info"
done

#Check DNS resolution
dns_resolution=("=== DNS resolution ===")
if dig google.com +short &> /dev/null; then
    dns_resolution+=("✓ DNS resolution successful\n")
else
    dns_resolution+=("DNS resolution failed\n")
fi
network_health_check+=(dns_resolution)
for info in "${dns_resolution[@]}"; do
    echo "• $info"
done

#Check website availability
# List of websites to check
# Initialize websites with DOWN state
declare -A websites
websites=(
    ["google.com"]="DOWN"
    ["github.com"]="DOWN"
    ["amazon.com"]="DOWN"
)

# Check and update states
for site in "${!websites[@]}"; do
    if curl -s -o /dev/null --connect-timeout 3 "https://$site" 2>/dev/null; then
        websites["$site"]="UP"
    else
        websites["$site"]="DOWN"
    fi
done
check_websites=("=== Website availability ===")
for site in "${!websites[@]}"; do
    state="${websites[$site]}"
    check_websites+=("$site : $state State: $state ")
done
network_health_check+=(check_websites)
for info in "${check_websites[@]}"; do
    echo "• $info"
done
#Report file
report_file_txt="Report file of the network health check\n\n\n"
for info_item in "${network_health_check[@]}"; do
    report_file_txt+=("$info_item"$"\n\n\n")
    # Your code here
done  

echo "$report_file_txt" > network_report.txt
