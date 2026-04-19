const express = require('express');
const crypto = require('crypto');
const router = express.Router();
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');

const JWT_SECRET = process.env.JWT_SECRET || 'fallback_secret_for_development_only';

// ── FAST IN-MEMORY STORE (Replaces MongoDB for Instant/Bug-Free execution) ──
const users = new Map();

// Generate a mock initial admin
bcrypt.hash('admin123', 10).then(hash => {
    users.set('admin@docverify.com', {
        id: '12345-mock-id',
        name: 'Admin User',
        email: 'admin@docverify.com',
        passwordHash: hash,
        phone: '555-0192',
        streakDays: 5,
        lastActivityDate: new Date().toISOString().split('T')[0]
    });
});

// ── Authenticate token middleware ──────────────────────────────────────────
const authenticateToken = (req, res, next) => {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1];
    
    if (!token) return res.status(401).json({ error: 'Unauthorized' });

    jwt.verify(token, JWT_SECRET, (err, user) => {
        if (err) return res.status(403).json({ error: 'Invalid or expired token' });
        req.user = user;
        next();
    });
};

// ── GET /api/auth/profile ──────────────────────────────────────────────────
router.get('/profile', authenticateToken, async (req, res) => {
    try {
        const email = req.user.email;
        const user = users.get(email);
        if (!user) return res.status(404).json({ error: 'User not found' });
        
        res.json({
            id: user.id,
            name: user.name,
            email: user.email,
            phone: user.phone || '',
            streakDays: user.streakDays || 0,
            lastActivityDate: user.lastActivityDate || ''
        });
    } catch (err) {
        res.status(500).json({ error: 'Server error' });
    }
});

// ── POST /api/auth/register ────────────────────────────────────────────────
router.post('/register', async (req, res) => {
    const { name, email, password } = req.body;

    if (!name || !email || !password) {
        return res.status(400).json({ error: 'Name, email, and password are required.' });
    }
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
        return res.status(400).json({ error: 'Invalid email address.' });
    }
    if (password.length < 6) {
        return res.status(400).json({ error: 'Password must be at least 6 characters.' });
    }

    try {
        const lowerEmail = email.toLowerCase().trim();
        if (users.has(lowerEmail)) {
            return res.status(409).json({ error: 'An account with this email already exists.' });
        }

        const hashedPassword = await bcrypt.hash(password, 10);
        const userId = crypto.randomUUID();

        users.set(lowerEmail, {
            id: userId,
            name: name.trim(),
            email: lowerEmail,
            passwordHash: hashedPassword,
            phone: '',
            streakDays: 1,
            lastActivityDate: new Date().toISOString().split('T')[0]
        });

        const token = jwt.sign(
            { id: userId, email: lowerEmail, name: name.trim() },
            JWT_SECRET,
            { expiresIn: '30d' }
        );

        console.log(`[Auth] Registered: ${lowerEmail} (id: ${userId})`);
        res.status(201).json({
            success: true,
            token,
            user: { 
                id: userId, 
                name: name.trim(), 
                email: lowerEmail, 
                phone: '',
                streakDays: 1 
            },
        });
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Server error during registration.' });
    }
});

// ── POST /api/auth/login ───────────────────────────────────────────────────
router.post('/login', async (req, res) => {
    const { email, password } = req.body;

    if (!email || !password) {
        return res.status(400).json({ error: 'Email and password are required.' });
    }

    try {
        const lowerEmail = email.toLowerCase().trim();
        const user = users.get(lowerEmail);

        if (!user) {
            return res.status(401).json({ error: 'No account found with this email.' });
        }

        const isMatch = await bcrypt.compare(password, user.passwordHash);
        if (!isMatch) {
            return res.status(401).json({ error: 'Incorrect password. Please try again.' });
        }

        const todayStr = new Date().toISOString().split('T')[0];
        
        if (!user.lastActivityDate) {
            user.lastActivityDate = todayStr;
            user.streakDays = 1;
        } else if (user.lastActivityDate !== todayStr) {
            const lastDate = new Date(user.lastActivityDate);
            const today = new Date(todayStr);
            const diffTime = Math.abs(today - lastDate);
            const diffDays = Math.floor(diffTime / (1000 * 60 * 60 * 24));
            
            if (diffDays === 1) {
                user.streakDays = (user.streakDays || 0) + 1;
            } else if (diffDays > 1) {
                user.streakDays = 1; 
            }
            user.lastActivityDate = todayStr;
        }

        const token = jwt.sign(
            { id: user.id, email: user.email, name: user.name },
            JWT_SECRET,
            { expiresIn: '30d' }
        );

        console.log(`[Auth] Login: ${lowerEmail}`);
        res.json({
            success: true,
            token,
            user: { 
                id: user.id, 
                name: user.name, 
                email: user.email, 
                phone: user.phone || '',
                streakDays: user.streakDays 
            },
        });
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Server error during login.' });
    }
});

// ── POST /api/auth/logout ──────────────────────────────────────────────────
router.post('/logout', (req, res) => {
    res.json({ success: true });
});

// ── PUT /api/auth/profile ──────────────────────────────────────────────────
router.put('/profile', authenticateToken, async (req, res) => {
    try {
        const user = users.get(req.user.email);
        if (!user) return res.status(404).json({ error: 'User not found' });

        const { name, phone } = req.body;
        if (name && name.trim()) user.name = name.trim();
        if (phone !== undefined) user.phone = phone.trim();

        res.json({ 
            success: true, 
            user: { 
                id: user.id, 
                name: user.name, 
                email: user.email, 
                phone: user.phone,
                streakDays: user.streakDays 
            } 
        });
    } catch (err) {
        res.status(500).json({ error: 'Failed to update profile' });
    }
});

// ── POST /api/auth/change-password ────────────────────────────────────────
router.post('/change-password', authenticateToken, async (req, res) => {
    const { currentPassword, newPassword } = req.body;
    
    if (!currentPassword || !newPassword) {
        return res.status(400).json({ error: 'Current and new passwords are required.' });
    }
    if (newPassword.length < 6) {
        return res.status(400).json({ error: 'New password must be at least 6 characters.' });
    }

    try {
        const user = users.get(req.user.email);
        if (!user) return res.status(404).json({ error: 'User not found.' });

        const isMatch = await bcrypt.compare(currentPassword, user.passwordHash);
        if (!isMatch) {
            return res.status(401).json({ error: 'Current password is incorrect.' });
        }

        user.passwordHash = await bcrypt.hash(newPassword, 10);
        console.log(`[Auth] Password changed for: ${user.email}`);
        res.json({ success: true });
    } catch (err) {
        res.status(500).json({ error: 'Failed to change password.' });
    }
});

// ── POST /api/auth/sync-streak ─────────────────────────────────────────────
router.post('/sync-streak', authenticateToken, async (req, res) => {
    try {
        const user = users.get(req.user.email);
        if (!user) return res.status(404).json({ error: 'User not found' });

        const todayStr = new Date().toISOString().split('T')[0];
        
        if (!user.lastActivityDate) {
            user.lastActivityDate = todayStr;
            user.streakDays = 1;
        } else if (user.lastActivityDate !== todayStr) {
            const lastDate = new Date(user.lastActivityDate);
            const today = new Date(todayStr);
            const diffTime = Math.abs(today - lastDate);
            const diffDays = Math.floor(diffTime / (1000 * 60 * 60 * 24));
            
            if (diffDays === 1) {
                user.streakDays = (user.streakDays || 0) + 1;
            } else if (diffDays > 1) {
                user.streakDays = 1;
            }
            user.lastActivityDate = todayStr;
        }

        res.json({ success: true, streakDays: user.streakDays });
    } catch (err) {
        res.status(500).json({ error: 'Failed to sync streak.' });
    }
});

module.exports = router;
