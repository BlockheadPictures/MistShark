#!/bin/bash

# Set your Prometheus Pushgateway URL
PUSHGATEWAY_URL="http://your-pushgateway.example.com:9091/metrics/job/speedtest"

# Pick a random interface: eth0 or wlan0
INTERFACE=$(shuf -n1 -e eth0 wlan0)

# Run speedtest using the selected interface
SPEEDTEST_OUTPUT=$(timeout 40s speedtest-cli --source=$(ip -4 addr show $INTERFACE | grep -oP '(?<=inet\s)\d+(\.\d+){3}') --json 2>/dev/null)

# Check if the test ran successfully
if [[ -z "$SPEEDTEST_OUTPUT" ]]; then
    echo "Speedtest failed on interface $INTERFACE"
    exit 1
fi

# Parse values
DOWNLOAD=$(echo "$SPEEDTEST_OUTPUT" | jq '.download // 0')
UPLOAD=$(echo "$SPEEDTEST_OUTPUT" | jq '.upload // 0')
PING=$(echo "$SPEEDTEST_OUTPUT" | jq '.ping // 0')

# Convert to Mbps
DOWNLOAD_MBPS=$(awk "BEGIN {print $DOWNLOAD/1000000}")
UPLOAD_MBPS=$(awk "BEGIN {print $UPLOAD/1000000}")

# Create metrics payload
cat <<EOF | curl --data-binary @- "$PUSHGATEWAY_URL"
# TYPE speedtest_download gauge
speedtest_download{interface="$INTERFACE"} $DOWNLOAD_MBPS
# TYPE speedtest_upload gauge
speedtest_upload{interface="$INTERFACE"} $UPLOAD_MBPS
# TYPE speedtest_ping gauge
speedtest_ping{interface="$INTERFACE"} $PING
EOF
