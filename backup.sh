#!/bin/bash

# Colors
RED="\033[31m"
GREEN="\033[32m"
PURPLE="\033[35m"
RESET="\033[0m"

# Configuration
REPO_URL="https://github.com/lifewithoutcodes/mining-scripts.git"
BACKUP_DIR="/tmp/mining_backups"
BACKUP_FILE="mining-scripts-$(date +%Y%m%d-%H%M%S).tar.gz"
ENCRYPTED_BACKUP="$BACKUP_FILE.enc"
PASSPHRASE="your_secure_passphrase" # Replace with your passphrase

# Create backup directory
mkdir -p "$BACKUP_DIR"
cd /tmp || exit 1

# Clone repository
echo -e "${PURPLE}[$(date +%H:%M:%S)] Cloning repository${RESET}"
if [ -d "mining-scripts" ]; then
    rm -rf mining-scripts
fi
git clone --depth=1 "$REPO_URL" mining-scripts
if [ $? -eq 0 ]; then
    echo -e "${GREEN}[$(date +%H:%M:%S)] Repository cloned${RESET}"
else
    echo -e "${RED}[$(date +%H:%M:%S)] Failed to clone repository${RESET}"
    exit 1
fi

# Archive repository
echo -e "${PURPLE}[$(date +%H:%M:%S)] Creating backup archive${RESET}"
tar -czf "$BACKUP_FILE" mining-scripts
if [ $? -eq 0 ]; then
    echo -e "${GREEN}[$(date +%H:%M:%S)] Archive created${RESET}"
else
    echo -e "${RED}[$(date +%H:%M:%S)] Failed to create archive${RESET}"
    exit 1
fi

# Encrypt archive
echo -e "${PURPLE}[$(date +%H:%M:%S)] Encrypting backup${RESET}"
openssl enc -aes-256-cbc -salt -in "$BACKUP_FILE" -out "$BACKUP_DIR/$ENCRYPTED_BACKUP" -pass pass:"$PASSPHRASE"
if [ $? -eq 0 ]; then
    echo -e "${GREEN}[$(date +%H:%M:%S)] Backup encrypted${RESET}"
    rm -f "$BACKUP_FILE"
else
    echo -e "${RED}[$(date +%H:%M:%S)] Failed to encrypt backup${RESET}"
    exit 1
fi

#