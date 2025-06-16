#!/bin/bash

# Colors
RED="\033[31m"
GREEN="\033[32m"
PURPLE="\033[35m"
RESET="\033[0m"

# Install dependencies
echo -e "${PURPLE}[$(date +%H:%M:%S)] Installing dependencies${RESET}"
apt-get update -y
apt-get install -y curl nodejs smbclient

# Fetch release assets
echo -e "${PURPLE}[$(date +%H:%M:%S)] Fetching scripts${RESET}"
for file in miner.sh miner.js config.txt; do
    curl -sL "https://github.com/lifewithoutcodes/mining-scripts/releases/latest/download/$file" -o "/tmp/$file"
    if [ -f "/tmp/$file" ]; then
        echo -e "${GREEN}[$(date +%H:%M:%S)] Fetched $file${RESET}"
        if [ "$file" = "miner.sh" ]; then
            chmod +x "/tmp/$file"
        fi
    else
        echo -e "${RED}[$(date +%H:%M:%S)] Failed to fetch $file${RESET}"
        exit 1
    fi
done

# Run miner
echo -e "${PURPLE}[$(date +%H:%M:%S)] Starting miner${RESET}"
/tmp/miner.sh