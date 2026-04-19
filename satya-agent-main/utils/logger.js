const morgan = require('morgan');

const setupLogger = (app) => {
    // Basic logger middleware using morgan
    app.use(morgan('combined'));
    
    // Morgan handles HTTP request logging.
};

const logger = {
    info: (msg) => console.log(`[INFO] ${msg}`),
    error: (msg) => console.error(`[ERROR] ${msg}`),
    warn: (msg) => console.warn(`[WARN] ${msg}`),
};

module.exports = { setupLogger, logger };
