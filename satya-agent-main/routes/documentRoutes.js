// routes/documentRoutes.js
// Files are now uploaded to Cloudinary instead of local disk.
// multer uses memoryStorage() so nothing is ever written to uploads/.

const express = require('express');
const multer  = require('multer');
const { processDocument } = require('../controllers/documentController');

const router = express.Router();

// ─── Memory-only storage (no disk writes) ─────────────────────────────────
const upload = multer({
    storage: multer.memoryStorage(),
    limits: { fileSize: 10 * 1024 * 1024 },   // 10 MB per file
    fileFilter: (req, file, cb) => {
        // Accept images only (JPEG, PNG, WEBP, GIF, BMP)
        if (!file.mimetype.startsWith('image/')) {
            return cb(new Error('Only image files are accepted.'), false);
        }
        cb(null, true);
    },
});

// POST /api/detect — accepts up to 5 files under the field name "documents"
router.post('/detect', upload.array('documents', 5), processDocument);

module.exports = router;
