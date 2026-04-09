// routes/submissionRoutes.js
// In-memory submission store (persists as long as the server is running)
// For production, replace with a real database (MongoDB, PostgreSQL, etc.)

const express = require('express');
const router = express.Router();

/** @type {Array<Object>} In-memory store */
const submissions = [];

// ─── POST /api/submissions ─────────────────────────────────────────────────
// Called by frontend after Satya Agent detection completes.
// Body: { id, applicant, categoryKey, categoryTitle, documents[], detectionResult, submittedAt }
router.post('/', (req, res) => {
    const body = req.body;
    if (!body || !body.id) {
        return res.status(400).json({ error: 'Invalid submission: missing id.' });
    }
    // Avoid duplicates
    const existing = submissions.findIndex(s => s.id === body.id);
    if (existing !== -1) {
        submissions[existing] = { ...submissions[existing], ...body };
    } else {
        submissions.unshift({
            ...body,
            status: body.status || 'pending',
            receivedAt: new Date().toISOString(),
        });
    }
    console.log(`[Submissions] Saved submission ${body.id} (total: ${submissions.length})`);
    res.status(201).json({ success: true, id: body.id });
});

// ─── GET /api/submissions ──────────────────────────────────────────────────
// Called by admin portal to load all submissions.
router.get('/', (req, res) => {
    res.json(submissions);
});

// ─── GET /api/submissions/:id ──────────────────────────────────────────────
// Called by frontend status page to poll a single submission.
router.get('/:id', (req, res) => {
    const found = submissions.find(s => s.id === req.params.id);
    if (!found) return res.status(404).json({ error: 'Submission not found' });
    res.json(found);
});

// ─── PATCH /api/submissions/:id/status ────────────────────────────────────
// Called by admin portal when Accept / Reject is clicked.
// Body: { status: "approved" | "rejected", officerNote?: string }
router.patch('/:id/status', (req, res) => {
    const { status, officerNote } = req.body;
    if (!['approved', 'rejected'].includes(status)) {
        return res.status(400).json({ error: 'Status must be "approved" or "rejected"' });
    }
    const idx = submissions.findIndex(s => s.id === req.params.id);
    if (idx === -1) return res.status(404).json({ error: 'Submission not found' });

    submissions[idx] = {
        ...submissions[idx],
        status,
        officerNote: officerNote || null,
        decidedAt: new Date().toISOString(),
    };
    console.log(`[Submissions] ${status.toUpperCase()} decision applied to ${req.params.id}`);
    res.json({ success: true, id: req.params.id, status });
});

module.exports = router;
