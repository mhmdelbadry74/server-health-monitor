#!/bin/bash

# Slack Webhook (add your webhook URL below)
SLACK_WEBHOOK_URL="https://hooks.slack.com/services/your/webhook/url"

# Ports to monitor
PORTS=(3000 3030 8000 8080)
CRITICAL_PORTS=(3000 3030)

# Info
HOSTNAME=$(hostname)
DATE=$(date '+%Y-%m-%d %H:%M:%S')
CPU_LOAD=$(top -bn1 | grep "Cpu(s)" | awk '{print 100 - $8"%"}')
MEMORY_USAGE=$(free | awk '/Mem/{printf("%.2f", $3/$2 * 100)}')
DISK_USAGE=$(df -h / | awk 'NR==2 {print $5}')
SWAP_USAGE=$(free | awk '/Swap:/ { if ($2 == 0) print "0"; else printf("%.2f", $3/$2 * 100) }')
LOAD_AVG=$(uptime | awk -F'load average:' '{ print $2 }' | xargs)
UPTIME=$(uptime -p)
RX=$(cat /sys/class/net/eth0/statistics/rx_bytes)
TX=$(cat /sys/class/net/eth0/statistics/tx_bytes)
RX_HR=$(numfmt --to=iec --suffix=B $RX)
TX_HR=$(numfmt --to=iec --suffix=B $TX)
CONNECTIONS=$(ss -tun | grep ESTAB | wc -l)

# Port status report
PORT_TABLE=""
ALERTS=""

for PORT in "${PORTS[@]}"; do
    RESULT=$(sudo lsof -i :$PORT -P -n | grep LISTEN | awk '{print $1 " (PID: " $2 ")"}')
    if [ -z "$RESULT" ]; then
        PORT_TABLE+="• Port $PORT: ❌ No process\n"
    else
        PORT_TABLE+="• Port $PORT: ✅ $RESULT\n"
    fi
done

# Check CRITICAL ports
for PORT in "${CRITICAL_PORTS[@]}"; do
    RESULT=$(sudo lsof -i :$PORT -P -n | grep LISTEN)
    if [ -z "$RESULT" ]; then
        ALERTS+=":rotating_light: *ALERT:* Port $PORT is *DOWN*!\n"
    fi
done

# Slack message
read -r -d '' PAYLOAD << EOF
{
  "blocks": [
    {
      "type": "header",
      "text": { "type": "plain_text", "text": ":desktop_computer: Server Health - $HOSTNAME", "emoji": true }
    },
    {
      "type": "context",
      "elements": [{ "type": "mrkdwn", "text": "*Checked:* $DATE" }]
    },
    {
      "type": "section",
      "fields": [
        { "type": "mrkdwn", "text": "*CPU Load:* $CPU_LOAD" },
        { "type": "mrkdwn", "text": "*Memory:* $MEMORY_USAGE%" },
        { "type": "mrkdwn", "text": "*Disk:* $DISK_USAGE" },
        { "type": "mrkdwn", "text": "*Swap:* $SWAP_USAGE%" },
        { "type": "mrkdwn", "text": "*Load:* $LOAD_AVG" },
        { "type": "mrkdwn", "text": "*Uptime:* $UPTIME" }
      ]
    },
    {
      "type": "section",
      "fields": [
        { "type": "mrkdwn", "text": "*Network In:* $RX_HR" },
        { "type": "mrkdwn", "text": "*Network Out:* $TX_HR" },
        { "type": "mrkdwn", "text": "*Connections:* $CONNECTIONS" }
      ]
    },
    {
      "type": "divider"
    },
    {
      "type": "section",
      "text": { "type": "mrkdwn", "text": "*:satellite: Port Monitoring:*\n$PORT_TABLE" }
    }
    $( [ -n "$ALERTS" ] && echo ",{ \"type\": \"section\", \"text\": { \"type\": \"mrkdwn\", \"text\": \"$ALERTS\" } }" )
  ]
}
EOF

# Send to Slack
curl -X POST -H 'Content-type: application/json' --data "$PAYLOAD" "$SLACK_WEBHOOK_URL"
