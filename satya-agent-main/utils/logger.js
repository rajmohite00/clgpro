const morgan = require('morgan');

const setupLogger = (app) => {
    // Basic logger middleware using morgan
    app.use(morgan('combined'));
    
    // Custom manual logger for important events
    app.use((req, res, next) => {
        logger.info(`${req.method} ${req.url}`);
        next();
    });
};

const logger = {
    info: (msg) => console.log(`[INFO] ${msg}`),
    error: (msg) => console.error(`[ERROR] ${msg}`),
    warn: (msg) => console.warn(`[WARN] ${msg}`),
};

module.exports = { setupLogger, logger };
