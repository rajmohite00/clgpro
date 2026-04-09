const ngrok = require('@ngrok/ngrok');
const { logger } = require('../utils/logger');

const startNgrok = async (port) => {
    try {
        const authtoken = process.env.NGROK_AUTHTOKEN;
        if (!authtoken || authtoken.trim() === 'your_token') {
            logger.warn('Ngrok authtoken not provided. Ngrok tunnel will not start.');
            return null;
        }

        const cleanToken = authtoken.trim();

        // Use the official robust @ngrok/ngrok package to securely bind to the port
        const listener = await ngrok.forward({
            addr: parseInt(port, 10),
            authtoken: cleanToken,
            authtoken_from_env: false
        });
        
        const url = listener.url();
        logger.info(`Ngrok Tunnel Started: ${url}`);
        return url;
    } catch (error) {
        logger.error(`Ngrok failed to start: ${error.message || JSON.stringify(error)}`);
        return null;
    }
};

module.exports = { startNgrok };
