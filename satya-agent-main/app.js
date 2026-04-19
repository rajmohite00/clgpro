require('dotenv').config();
const express = require('express');
const cors = require('cors');
const fs = require('fs');
const path = require('path');

const helmet = require('helmet');
const rateLimit = require('express-rate-limit');

const documentRoutes = require('./routes/documentRoutes');
const submissionRoutes = require('./routes/submissionRoutes');
const authRoutes = require('./routes/authRoutes');
const { setupLogger, logger } = require('./utils/logger');
const { startNgrok } = require('./config/ngrok');

const app = express();
const PORT = process.env.PORT || 5000;
const MONGO_URI = process.env.MONGO_URI || 'mongodb://127.0.0.1:27017/smart-document';

// CORS — Whitelist allowed origins
const allowedOrigins = [
    // Local development
    'http://localhost:3000',
    'http://localhost:3001',
    'http://localhost:3002',
    'http://localhost:5000',
    'http://localhost:5173',
    // Production Vercel deployments
    'https://veriscan-main.vercel.app',
    'https://veriscan-admin.vercel.app',
    // Render backend (no trailing slash!)
    'https://satya-agent-main.onrender.com',
];

app.use(helmet());
app.use(cors({
    origin: function (origin, callback) {
        // Allow requests with no origin (mobile apps, curl, Postman, server-to-server)
        if (!origin) return callback(null, true);

        // Check exact match
        if (allowedOrigins.includes(origin)) {
            return callback(null, true);
        }

        // Allow any Vercel preview deploy URL (e.g. veriscan-main-abc123.vercel.app)
        if (/^https:\/\/veriscan.*\.vercel\.app$/.test(origin)) {
            return callback(null, true);
        }

        // Allow any onrender.com subdomain
        if (/^https:\/\/.*\.onrender\.com$/.test(origin)) {
            return callback(null, true);
        }

        // Allow any localhost port
        if (/^http:\/\/localhost:\d+$/.test(origin)) {
            return callback(null, true);
        }

        callback(new Error('Not allowed by CORS'));
    },
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With'],
}));

// Trust proxies (required for ngrok, Vercel, Render)
app.set('trust proxy', 1);

// Global Rate Limiter
const globalLimiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 100, // Limit each IP to 100 requests per windowMs
    message: { error: 'Too many requests from this IP, please try again after 15 minutes' },
    standardHeaders: true, // Return rate limit info in the `RateLimit-*` headers
    legacyHeaders: false, // Disable the `X-RateLimit-*` headers
});
app.use(globalLimiter);

app.use(express.json({ limit: '5mb' }));
app.use(express.urlencoded({ extended: true, limit: '5mb' }));
setupLogger(app);

// Routes
app.use('/api', documentRoutes);
app.use('/api/submissions', submissionRoutes);
app.use('/api/auth', authRoutes);

// Global Error Handler — never leak stack traces in production
app.use((err, req, res, next) => {
    const isProd = process.env.NODE_ENV === 'production';
    const status = err.status || 500;
    logger.error(`[GlobalError] ${err.message}`);
    if (!isProd) logger.error(err.stack);

    // Multer file-type rejection
    if (err.message === 'Only image files are accepted.') {
        return res.status(400).json({ error: err.message });
    }

    res.status(status).json({
        error: isProd ? 'An internal server error occurred.' : err.message,
    });
});

// Healthcheck — used by frontend checkHealth() and Render
app.get('/', (req, res) => {
    res.json({ status: 'running', message: 'Smart Document Detective API is live!' });
});

// Explicit /health route as alternative
app.get('/health', (req, res) => {
    res.json({ status: 'running', message: 'Smart Document Detective API is live!' });
});

// Start Server only if not in Vercel
if (process.env.VERCEL !== '1') {
    // Memory-only mode (MongoDB removed for simplicity)
    app.listen(PORT, async () => {
        logger.info(`Server running on http://localhost:${PORT}`);

        // Attempt ngrok connection
        const currentNgrokToken = process.env.NGROK_AUTHTOKEN ? process.env.NGROK_AUTHTOKEN.trim() : null;
        if (currentNgrokToken && currentNgrokToken !== 'your_token') {
            const publicUrl = await startNgrok(PORT);
            if (publicUrl) {
                global.publicNgrokUrl = publicUrl;
            }
        } else {
            logger.warn('Please set NGROK_AUTHTOKEN in .env to expose port publicly.');
            global.publicNgrokUrl = "ngrok not configured properly in .env";
        }
    });
}

// Export the Express API for Vercel
module.exports = app;
