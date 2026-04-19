const Tesseract = require('tesseract.js');
const { Jimp } = require('jimp');
const fs = require('fs');
const os = require('os');
const path = require('path');
const { logger } = require('../utils/logger');

// Root dir of the project — where eng.traineddata lives
const PROJECT_ROOT = path.resolve(__dirname, '..');

// ── Persistent Worker Pool for "Real-Time" Speed ────────────────────────────
// Reusing workers avoids the 2-5 second overhead of initializing Tesseract on every scan.
let workerPool = null;

const getWorker = async () => {
    if (workerPool) return workerPool;
    
    logger.info('Initializing persistent OCR worker pool...');
    workerPool = await Tesseract.createWorker('eng', 1, {
        logger:      () => {},             // silence verbose logging
        langPath:    PROJECT_ROOT,          // root dir has eng.traineddata
        cachePath:   os.tmpdir(),
        cacheMethod: 'write',
        gzip:        false,
    });
    return workerPool;
};

const extractText = async (imagePath) => {
    let optimizedImagePath = imagePath;
    try {
        logger.info(`Starting OCR for ${imagePath}`);

        // --- PREPROCESS IMAGE FOR OPTIMAL OCR ---
        try {
            const image = await Jimp.read(imagePath);
            optimizedImagePath = imagePath + '_ocr_optimized.jpg';
            
            await image
                .greyscale()
                .contrast(0.5)
                .normalize()
                .write(optimizedImagePath);
                
            logger.info(`Successfully generated contrasting image for robust OCR: ${optimizedImagePath}`);
        } catch (jimpError) {
            logger.warn(`Optimization of image failed prior to OCR. Falling back to original image: ${jimpError.message}`);
            optimizedImagePath = imagePath;
        }

        const worker = await getWorker();

        // Add timeout to prevent infinite hanging
        const recognizePromise = worker.recognize(optimizedImagePath);
        const timeoutPromise = new Promise((_, reject) => {
             const id = setTimeout(() => { reject(new Error('OCR Timeout: Extraction took too long')); }, 60000);
             if (id.unref) id.unref();
        });

        const result = await Promise.race([recognizePromise, timeoutPromise]);
        
        // Clean and normalize output
        const cleanText = result.data.text.replace(/\n\s*\n/g, '\n').trim();
        return cleanText;
    } catch (error) {
        logger.error(`OCR failed: ${error.message}`);
        // If worker failed, we might need to reset it
        workerPool = null; 
        throw new Error('OCR extraction failed: ' + error.message);
    } finally {
        // Cleanup enhanced temporary image aggressively
        if (optimizedImagePath !== imagePath && fs.existsSync(optimizedImagePath)) {
            try { fs.unlinkSync(optimizedImagePath); } catch (e) {
                logger.warn(`Could not delete temp optimized OCR image: ${e.message}`);
            }
        }
    }
};

module.exports = { extractText };
