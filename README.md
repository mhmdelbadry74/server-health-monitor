# 🖥️ Server Health Monitor (Slack Alerts)

Bash script to monitor server health and send real-time alerts to Slack.

## 📌 What It Does

- Monitors important ports (customizable).
- Alerts you via Slack if any port is down.
- Shows:
  - CPU load
  - Memory usage
  - Disk usage
  - Swap usage
  - Uptime
  - Network traffic (RX/TX)
  - Active TCP connections

## ⚙️ Setup

1. Clone the repo:

```bash
git clone https://github.com/mhmdelbadry74/server-health-monitor.git
cd server-health-monitor
./monitor.sh
