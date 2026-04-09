require('dotenv').config();
const express = require('express');
const cors = require('cors');
const fs = require('fs');
const path = require('path');
const documentRoutes = require('./routes/documentRoutes');
const submissionRoutes = require('./routes/submissionRoutes');
const { setupLogger, logger } = require('./utils/logger');
const { startNgrok } = require('./config/ngrok');

const app = express();
const PORT = process.env.PORT || 5000;

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

app.use(express.json());
setupLogger(app);

// Routes
app.use('/api', documentRoutes);
app.use('/api/submissions', submissionRoutes);

// Detailed Global Error Handler
app.use((err, req, res, next) => {
    console.error(">>> EXPRESS GLOBAL ERROR DETECTED <<<");
    console.error(err);
    res.status(500).json({ error: err.message, stack: err.stack });
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
