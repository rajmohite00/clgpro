const express = require('express');
const crypto  = require('crypto');
const router  = express.Router();
const jwt     = require('jsonwebtoken');
const bcrypt  = require('bcryptjs');
const { body, validationResult } = require('express-validator');
const User    = require('../models/User');

// ── JWT Secret — MUST be set via environment variable in production ──────────
const JWT_SECRET = process.env.JWT_SECRET;
if (!JWT_SECRET) {
    if (process.env.NODE_ENV === 'production') {
        console.error('[FATAL] JWT_SECRET env variable is not set. Refusing to start.');
        process.exit(1);
    } else {
        console.warn('[WARN] JWT_SECRET not set. Using insecure dev fallback. Set it in your .env file!');
    }
}
const EFFECTIVE_JWT_SECRET = JWT_SECRET || 'DEV_ONLY_fallback_not_for_production';

// ── Simple in-process rate limiter ───────────────────────────────────────────
// Tracks failed attempts per IP. Resets after WINDOW_MS.
const RATE_LIMIT_MAX     = 10;   // max attempts per window
const RATE_LIMIT_WINDOW  = 15 * 60 * 1000; // 15 minutes
const rateLimitStore = new Map(); // { ip => { count, resetAt } }

function checkRateLimit(req, res) {
    const ip  = req.ip || req.connection?.remoteAddress || 'unknown';
    const now = Date.now();
    let entry = rateLimitStore.get(ip);

    if (!entry || now > entry.resetAt) {
        entry = { count: 0, resetAt: now + RATE_LIMIT_WINDOW };
        rateLimitStore.set(ip, entry);
    }

    entry.count += 1;
    if (entry.count > RATE_LIMIT_MAX) {
        const retryAfterSec = Math.ceil((entry.resetAt - now) / 1000);
        res.set('Retry-After', retryAfterSec);
        res.status(429).json({ error: 'Too many attempts. Please try again later.' });
        return false;
    }
    return true;
}

function resetRateLimit(req) {
    const ip = req.ip || req.connection?.remoteAddress || 'unknown';
    rateLimitStore.delete(ip);
}

// ── Authenticate token middleware ────────────────────────────────────────────
const authenticateToken = (req, res, next) => {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1];

    if (!token) return res.status(401).json({ error: 'Authentication required.' });

    jwt.verify(token, EFFECTIVE_JWT_SECRET, (err, decoded) => {
        if (err) {
            const msg = err.name === 'TokenExpiredError'
                ? 'Session expired. Please log in again.'
                : 'Invalid token. Please log in again.';
            return res.status(403).json({ error: msg });
        }
        req.user = decoded;
        next();
    });
};

// ── Validation helpers ───────────────────────────────────────────────────────
const handleValidation = (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
        const first = errors.array()[0];
        return res.status(400).json({ error: first.msg });
    }
    return null;
};

// Seed a default admin (only in non-production)
if (process.env.NODE_ENV !== 'production') {
    bcrypt.hash('Admin@123', 12).then(async hash => {
        try {
            const adminExists = await User.findOne({ email: 'admin@docverify.com' });
            if (!adminExists) {
                await User.create({
                    name: 'Admin User',
                    email: 'admin@docverify.com',
                    password: hash,
                    phone: '',
                    streakDays: 1,
                    lastActivityDate: new Date().toISOString().split('T')[0]
                });
                console.log('[Auth] Seeded default admin user.');
            }
        } catch (err) {
            console.error('[Auth] Failed to seed admin user:', err.message);
        }
    });
}

// ── GET /api/auth/profile ────────────────────────────────────────────────────
router.get('/profile', authenticateToken, async (req, res) => {
    try {
        const user = await User.findOne({ email: req.user.email });
        if (!user) return res.status(404).json({ error: 'User not found.' });

        res.json({
            id:               user._id.toString(),
            name:             user.name,
            email:            user.email,
            phone:            user.phone || '',
            streakDays:       user.streakDays || 0,
            lastActivityDate: user.lastActivityDate || '',
        });
    } catch (_) {
        res.status(500).json({ error: 'Failed to load profile.' });
    }
});

// ── POST /api/auth/register ──────────────────────────────────────────────────
router.post(
    '/register',
    [
        body('name')
            .trim().notEmpty().withMessage('Full name is required.')
            .isLength({ max: 100 }).withMessage('Name must be under 100 characters.')
            .escape(),
        body('email')
            .trim().isEmail().withMessage('Please provide a valid email address.')
            .normalizeEmail(),
        body('password')
            .isLength({ min: 8 }).withMessage('Password must be at least 8 characters.')
            .matches(/[A-Z]/).withMessage('Password must contain at least one uppercase letter.')
            .matches(/[0-9]/).withMessage('Password must contain at least one number.'),
    ],
    async (req, res) => {
        if (!checkRateLimit(req, res)) return;

        const validErr = handleValidation(req, res);
        if (validErr !== null) return;

        try {
            const { name, email, password } = req.body;
            const lowerEmail = email.toLowerCase().trim();

            const existingUser = await User.findOne({ email: lowerEmail });
            if (existingUser) {
                return res.status(409).json({ error: 'An account with this email already exists.' });
            }

            const hashedPassword = await bcrypt.hash(password, 12);

            const newUser = await User.create({
                name:             name.trim(),
                email:            lowerEmail,
                password:         hashedPassword,
                phone:            '',
                streakDays:       1,
                lastActivityDate: new Date().toISOString().split('T')[0],
            });

            const token = jwt.sign(
                { id: newUser._id.toString(), email: lowerEmail, name: newUser.name },
                EFFECTIVE_JWT_SECRET,
                { expiresIn: '7d' }
            );

            resetRateLimit(req);
            console.log(`[Auth] Registered: ${lowerEmail}`);
            res.status(201).json({
                success: true,
                token,
                user: { id: newUser._id.toString(), name: newUser.name, email: lowerEmail, phone: '', streakDays: 1 },
            });
        } catch (err) {
            console.error(err);
            res.status(500).json({ error: 'Registration failed. Please try again.' });
        }
    }
);

// ── POST /api/auth/login ─────────────────────────────────────────────────────
router.post(
    '/login',
    [
        body('email').trim().isEmail().withMessage('Invalid email address.').normalizeEmail(),
        body('password').notEmpty().withMessage('Password is required.'),
    ],
    async (req, res) => {
        if (!checkRateLimit(req, res)) return;

        const validErr = handleValidation(req, res);
        if (validErr !== null) return;

        try {
            const { email, password } = req.body;
            const lowerEmail = email.toLowerCase().trim();
            
            const user = await User.findOne({ email: lowerEmail });

            // Use constant-time comparison to avoid timing attacks
            const dummyHash = '$2a$12$invalidhashforunknownusersXXXXXXXXXXXXXXXXXXXXXXXXX';
            const isMatch = user
                ? await bcrypt.compare(password, user.password)
                : await bcrypt.compare(password, dummyHash).then(() => false);

            if (!user || !isMatch) {
                return res.status(401).json({ error: 'Incorrect email or password.' });
            }

            // Update daily streak
            const todayStr = new Date().toISOString().split('T')[0];
            if (!user.lastActivityDate) {
                user.lastActivityDate = todayStr;
                user.streakDays = 1;
            } else if (user.lastActivityDate !== todayStr) {
                const diffDays = Math.floor(
                    (new Date(todayStr) - new Date(user.lastActivityDate)) / (1000 * 60 * 60 * 24)
                );
                user.streakDays = diffDays === 1 ? (user.streakDays || 0) + 1 : 1;
                user.lastActivityDate = todayStr;
            }
            await user.save();

            const token = jwt.sign(
                { id: user._id.toString(), email: user.email, name: user.name },
                EFFECTIVE_JWT_SECRET,
                { expiresIn: '7d' }
            );

            resetRateLimit(req);
            console.log(`[Auth] Login: ${lowerEmail}`);
            res.json({
                success: true,
                token,
                user: { id: user._id.toString(), name: user.name, email: user.email, phone: user.phone || '', streakDays: user.streakDays },
            });
        } catch (err) {
            console.error(err);
            res.status(500).json({ error: 'Login failed. Please try again.' });
        }
    }
);

// ── POST /api/auth/logout ────────────────────────────────────────────────────
router.post('/logout', (req, res) => {
    // Stateless JWT — client discards the token. Nothing to do server-side.
    res.json({ success: true });
});

// ── PUT /api/auth/profile ────────────────────────────────────────────────────
router.put(
    '/profile',
    authenticateToken,
    [
        body('name').optional().trim().isLength({ min: 1, max: 100 }).withMessage('Name must be 1–100 characters.').escape(),
        body('phone').optional().trim().isLength({ max: 20 }).withMessage('Phone must be under 20 characters.').escape(),
    ],
    async (req, res) => {
        const validErr = handleValidation(req, res);
        if (validErr !== null) return;

        try {
            const user = await User.findOne({ email: req.user.email });
            if (!user) return res.status(404).json({ error: 'User not found.' });

            const { name, phone } = req.body;
            if (name  && name.trim())  user.name  = name.trim();
            if (phone !== undefined)   user.phone = phone.trim();

            await user.save();

            res.json({
                success: true,
                user: { id: user._id.toString(), name: user.name, email: user.email, phone: user.phone, streakDays: user.streakDays },
            });
        } catch (_) {
            res.status(500).json({ error: 'Failed to update profile.' });
        }
    }
);

// ── POST /api/auth/change-password ──────────────────────────────────────────
router.post(
    '/change-password',
    authenticateToken,
    [
        body('currentPassword').notEmpty().withMessage('Current password is required.'),
        body('newPassword')
            .isLength({ min: 8 }).withMessage('New password must be at least 8 characters.')
            .matches(/[A-Z]/).withMessage('New password must contain at least one uppercase letter.')
            .matches(/[0-9]/).withMessage('New password must contain at least one number.'),
    ],
    async (req, res) => {
        const validErr = handleValidation(req, res);
        if (validErr !== null) return;

        try {
            const user = await User.findOne({ email: req.user.email });
            if (!user) return res.status(404).json({ error: 'User not found.' });

            const isMatch = await bcrypt.compare(req.body.currentPassword, user.password);
            if (!isMatch) return res.status(401).json({ error: 'Current password is incorrect.' });

            if (req.body.currentPassword === req.body.newPassword) {
                return res.status(400).json({ error: 'New password must differ from your current password.' });
            }

            user.password = await bcrypt.hash(req.body.newPassword, 12);
            await user.save();
            
            console.log(`[Auth] Password changed for: ${user.email}`);
            res.json({ success: true });
        } catch (_) {
            res.status(500).json({ error: 'Failed to change password.' });
        }
    }
);

// ── POST /api/auth/sync-streak ───────────────────────────────────────────────
router.post('/sync-streak', authenticateToken, async (req, res) => {
    try {
        const user = await User.findOne({ email: req.user.email });
        if (!user) return res.status(404).json({ error: 'User not found.' });

        const todayStr = new Date().toISOString().split('T')[0];
        if (!user.lastActivityDate) {
            user.lastActivityDate = todayStr;
            user.streakDays = 1;
        } else if (user.lastActivityDate !== todayStr) {
            const diffDays = Math.floor(
                (new Date(todayStr) - new Date(user.lastActivityDate)) / (1000 * 60 * 60 * 24)
            );
            user.streakDays = diffDays === 1 ? (user.streakDays || 0) + 1 : 1;
            user.lastActivityDate = todayStr;
        }
        await user.save();

        res.json({ success: true, streakDays: user.streakDays });
    } catch (_) {
        res.status(500).json({ error: 'Failed to sync streak.' });
    }
});

module.exports = router;
