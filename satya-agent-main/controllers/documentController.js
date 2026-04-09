// controllers/documentController.js
//
// Flow:
//  1. Multer provides in-memory Buffers (memoryStorage — no uploads/ folder).
//  2. Each Buffer is written to OS tmpdir for Tesseract OCR (fast local read).
//  3. Optionally uploaded to Cloudinary if credentials are configured.
//     → Cloudinary failure is NON-FATAL: OCR continues regardless.
//  4. Satya Agent runs the 4-node pipeline on the temp file paths.
//  5. Cloudinary URLs (if any) are attached to the response.
//  6. Temp files and optionally Cloudinary copies are cleaned up.

const agent  = require('../agent/documentAgent');
const { logger } = require('../utils/logger');
const os   = require('os');
const path = require('path');
const fs   = require('fs');

// ── Cloudinary: only load if all three credentials are present ─────────────
const CLOUD_NAME   = process.env.CLOUDINARY_CLOUD_NAME;
const CLOUD_KEY    = process.env.CLOUDINARY_API_KEY;
const CLOUD_SECRET = process.env.CLOUDINARY_API_SECRET;
const KEEP_ON_CLOUD = process.env.CLOUDINARY_KEEP === 'true';

const cloudinaryEnabled =
    CLOUD_NAME  && CLOUD_NAME  !== 'your_cloud_name' &&
    CLOUD_KEY   && CLOUD_KEY   !== 'your_api_key'    &&
    CLOUD_SECRET && CLOUD_SECRET !== 'your_api_secret';

let uploadBuffer = null;
let deleteFile   = null;

if (cloudinaryEnabled) {
    try {
        const { uploadBuffer: ub, deleteFile: df } = require('../config/cloudinary');
        uploadBuffer = ub;
        deleteFile   = df;
        logger.info('[Controller] Cloudinary integration ENABLED.');
    } catch (e) {
        logger.warn(`[Controller] Cloudinary config failed to load: ${e.message}. Continuing without Cloudinary.`);
    }
} else {
    logger.info('[Controller] Cloudinary credentials not set — uploads stored in tmpdir only (no cloud backup).');
}

// ─────────────────────────────────────────────────────────────────────────────
const processDocument = async (req, res) => {

    // ── 1. Validate upload ────────────────────────────────────────────────────
    let targetFiles = [];
    if (req.files && req.files.length > 0) {
        targetFiles = req.files;
    } else if (req.file) {
        targetFiles = [req.file];
    } else {
        return res.status(400).json({ error: 'Missing documents. Please upload 1 or more images.' });
    }

    const tmpPaths    = [];   // local temp file paths for Tesseract
    const cloudUrls   = [];   // Cloudinary URLs or null
    const publicIds   = [];   // Cloudinary public_ids for cleanup

    try {
        for (const file of targetFiles) {

            // ── 2. Write temp file ────────────────────────────────────────────
            // Use a safe filename: timestamp + sanitised original name, no dots except extension
            const safeName = file.originalname.replace(/[^a-zA-Z0-9._-]/g, '_');
            const tmpPath  = path.join(os.tmpdir(), `veri_${Date.now()}_${safeName}`);
            fs.writeFileSync(tmpPath, file.buffer);
            tmpPaths.push(tmpPath);

            // ── 3. Cloudinary upload (optional, non-fatal) ────────────────────
            let cloudUrl  = null;
            let publicId  = null;

            if (cloudinaryEnabled && uploadBuffer) {
                try {
                    const result = await uploadBuffer(file.buffer, safeName);
                    cloudUrl = result.url;
                    publicId = result.publicId;
                    logger.info(`[Cloudinary] Uploaded: ${cloudUrl}`);
                } catch (cloudErr) {
                    // NOT fatal — log and continue with local OCR
                    logger.warn(`[Cloudinary] Upload failed (non-fatal): ${cloudErr.message}`);
                }
            }

            cloudUrls.push(cloudUrl);
            publicIds.push(publicId);
        }

        // ── 4. Run Satya Agent pipeline ───────────────────────────────────────
        logger.info(`[Controller] Running agent on ${tmpPaths.length} file(s)...`);
        const responseData = await agent.analyzeMultiple(tmpPaths);

        // ── 5. Attach Cloudinary URLs to response ─────────────────────────────
        if (Array.isArray(responseData.documents)) {
            responseData.documents = responseData.documents.map((doc, i) => ({
                ...doc,
                cloudinaryUrl: cloudUrls[i] || null,
            }));
        } else {
            responseData.cloudinaryUrl = cloudUrls[0] || null;
        }

        res.status(200).json(responseData);

    } catch (error) {
        logger.error(`[Controller] Document processing error: ${error.message}`);
        logger.error(error.stack);
        res.status(500).json({
            error: 'Internal server error during document processing.',
            details: error.message,
        });
    } finally {
        // ── 6. Cleanup ────────────────────────────────────────────────────────
        for (const tmpPath of tmpPaths) {
            if (tmpPath && fs.existsSync(tmpPath)) {
                try { fs.unlinkSync(tmpPath); } catch (_) { /* ignore */ }
            }
        }
        if (!KEEP_ON_CLOUD && deleteFile) {
            for (const pid of publicIds) {
                if (pid) await deleteFile(pid).catch(() => {});
            }
        }
    }
};

module.exports = { processDocument };
