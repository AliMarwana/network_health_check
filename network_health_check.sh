#!/bin/bash
declare -a network_health_check=()

#information of server information 
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

# Get primary IP
my_ip=$(hostname -I | awk '{print $1}')
network_info+=("IP Address:    $(my_ip)")


# Default Gateway
DEFAULT_GATEWAY=$(ip route | grep default | awk '{print $3}')
# DEFAULT_GATEWAY=$(powershell.exe -Command "Get-NetIPConfiguration | select -ExpandProperty IPv4DefaultGateway | select -ExpandProperty NextHop" 2>/dev/null | head -n 1 | tr -d '\r')
#     DEFAULT_GATEWAY=$(route -n 2>/dev/null | awk '/^0.0.0.0/ {print $2; exit}')
# fi
# # Fallback 2: Try legacy netstat command
# if [ -z "$DEFAULT_GATEWAY" ] && command -v netstat >/dev/null 2>&1; then
#     DEFAULT_GATEWAY=$(netstat -rn 2>/dev/null | awk '/^0.0.0.0|^default/ {print $2; exit}')
# fi

network_info+=("Default Gateway: $(DEFAULT_GATEWAY)")

# DNS Servers
if [ -f /etc/resolv.conf ]; then
    DNS_SERVER=$(awk '/nameserver/ {print $2; exit}' /etc/resolv.conf)
elif command -v resolvectl >/dev/null 2>&1; then
    DNS_SERVER=$(resolvectl status 2>/dev/null | awk '/DNS Servers/ {print $3; exit}')
elif command -v nmcli >/dev/null 2>&1; then
    DNS_SERVER=$(nmcli dev show 2>/dev/null | awk '/IP4.DNS/ {print $2; exit}')
elif command -v powershell.exe >/dev/null 2>&1; then
    DNS_SERVER=$(powershell.exe -Command "(Get-NetIPConfiguration | Where-Object {\$_.IPv4Address -ne \$null}).DNSServer.ServerAddresses[0]" 2>/dev/null | tr -d '\r')
else
    DNS_SERVER="Unknown"
fi
network_info+=("DNS Server(s): $DNS_SERVER")
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
if dig https://www.google.com +short &> /dev/null; then
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
    check_websites+=("$site : $state ")
done
network_health_check+=(check_websites)
for info in "${check_websites[@]}"; do
    echo "• $info"
done

#Report file
report_file_txt="Report file of the network health check\n\n\n"
for inner_list in "${network_health_check[@]}"; do
    declare -n current_list="$inner_list"
    # Split and show individual items
    for item in "${current_list[@]}"; do
         report_file_txt+="$item\n"
    done
    report_file_txt+="\n\n"
done


echo -e "$report_file_txt" > network_report.txt
