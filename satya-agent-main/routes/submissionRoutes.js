const express = require('express');
const router = express.Router();
const jwt = require('jsonwebtoken');
const Submission = require('../models/Submission');

// ── Authentication middleware ──────────────────────────────────────────────
const authenticateToken = (req, res, next) => {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1];
    
    if (!token) return res.status(401).json({ error: 'Authentication required' });

    const secret = process.env.JWT_SECRET || 'DEV_ONLY_fallback_not_for_production';
    jwt.verify(token, secret, (err, user) => {
        if (err) return res.status(403).json({ error: 'Invalid or expired token' });
        req.user = user;
        next();
    });
};

// ─── POST /api/submissions ─────────────────────────────────────────────────
// Must be authenticated to submit
router.post('/', authenticateToken, async (req, res) => {
    try {
        const body = req.body;
        if (!body || !body.id) {
            return res.status(400).json({ error: 'Invalid submission: missing id.' });
        }
        
        // Use findOneAndUpdate to act as an upsert (update if exists, insert if not)
        const updateData = {
            applicant: body.applicant || 'Unknown',
            categoryKey: body.categoryKey,
            categoryTitle: body.categoryTitle,
            documents: body.documents || [],
            detectionResult: body.detectionResult || {},
            submittedBy: req.user.email,
            status: body.status || 'pending',
        };

        await Submission.findOneAndUpdate(
            { id: body.id },
            { $set: updateData },
            { upsert: true, new: true }
        );
        
        console.log(`[Submissions] Saved submission ${body.id} by ${req.user.email}`);
        res.status(201).json({ success: true, id: body.id });
    } catch (err) {
        console.error('[Submissions] Error saving:', err);
        res.status(500).json({ error: 'Failed to save submission.' });
    }
});

// ─── GET /api/submissions ──────────────────────────────────────────────────
// Must be authenticated to view
router.get('/', authenticateToken, async (req, res) => {
    try {
        const submissions = await Submission.find().sort({ createdAt: -1 });
        res.json(submissions);
    } catch (err) {
        res.status(500).json({ error: 'Failed to fetch submissions' });
    }
});

// ─── GET /api/submissions/:id ──────────────────────────────────────────────
router.get('/:id', authenticateToken, async (req, res) => {
    try {
        const found = await Submission.findOne({ id: req.params.id });
        if (!found) return res.status(404).json({ error: 'Submission not found' });
        res.json(found);
    } catch (err) {
        res.status(500).json({ error: 'Failed to fetch submission' });
    }
});

// ─── PATCH /api/submissions/:id/status ────────────────────────────────────
router.patch('/:id/status', authenticateToken, async (req, res) => {
    try {
        const { status, officerNote } = req.body;
        if (!['approved', 'rejected'].includes(status)) {
            return res.status(400).json({ error: 'Status must be "approved" or "rejected"' });
        }
        
        const updateData = {
            status,
            officerNote: officerNote || null,
            decidedAt: new Date(),
            decidedBy: req.user.email,
        };

        const updated = await Submission.findOneAndUpdate(
            { id: req.params.id },
            { $set: updateData },
            { new: true }
        );
        
        if (!updated) return res.status(404).json({ error: 'Submission not found' });

        console.log(`[Submissions] ${status.toUpperCase()} decision applied to ${req.params.id} by ${req.user.email}`);
        res.json({ success: true, id: req.params.id, status });
    } catch (err) {
        res.status(500).json({ error: 'Failed to update submission status' });
    }
});

module.exports = router;
