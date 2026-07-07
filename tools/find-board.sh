#!/bin/bash
# Discover the EVM board IP by scanning the ARP cache for a host
# running the webserver-oob demo on port 3000.
# Prints: root@<ip>   on success
# Exits 1 if no board found.

USB_FALLBACK="192.168.7.2"

check_ip() {
    local ip="$1"
    result=$(curl -sf --connect-timeout 1 --max-time 2 --noproxy "$ip" \
        "http://$ip:3000/device-info" 2>/dev/null)
    echo "$result" | grep -q '"id"'
}

# Collect candidate IPs from ARP cache (skip broadcast/multicast/loopback)
CANDIDATES=$(arp -a 2>/dev/null \
    | grep -oE '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' \
    | grep -Ev '^(255|224|239|127)\.' \
    | sort -u)

for ip in $CANDIDATES; do
    if check_ip "$ip"; then
        echo "root@$ip"
        exit 0
    fi
done

# Fallback: USB RNDIS default IP
if check_ip "$USB_FALLBACK"; then
    echo "root@$USB_FALLBACK"
    exit 0
fi

echo "ERROR: EVM board not found on network (scanned: $CANDIDATES $USB_FALLBACK)" >&2
exit 1
