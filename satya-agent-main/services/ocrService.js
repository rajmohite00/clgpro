const Tesseract = require('tesseract.js');
const { Jimp } = require('jimp');
const fs = require('fs');
const os = require('os');
const path = require('path');
const { logger } = require('../utils/logger');

// Root dir of the project — where eng.traineddata lives
const PROJECT_ROOT = path.resolve(__dirname, '..');

const extractText = async (imagePath) => {
    let optimizedImagePath = imagePath;
    try {
        logger.info(`Starting OCR for ${imagePath}`);

        // --- PREPROCESS IMAGE FOR OPTIMAL OCR ---
        // OCR struggles with noise and poor contrast. We use Jimp to
        // convert to grayscale, increase contrast natively, and normalize metrics.
        try {
            const image = await Jimp.read(imagePath);
            optimizedImagePath = imagePath + '_ocr_optimized.jpg';
            
            // Apply grayscale, adjust contrast heavily (+50%), and normalize values
            
            // For Jimp 1.6+, write() returns a Promise, do not use callbacks to await
            await image
                .greyscale()
                .contrast(0.5)
                .normalize()
                .write(optimizedImagePath);
                
            logger.info(`Successfully generated contrasting image for robust OCR: ${optimizedImagePath}`);
        } catch (jimpError) {
            logger.warn(`Optimization of image failed prior to OCR. Falling back to original image: ${jimpError.message}`);
            optimizedImagePath = imagePath; // Fallback gracefully
        }

        const worker = await Tesseract.createWorker('eng', 1, {
            logger:      () => {},             // silence verbose logging
            langPath:    PROJECT_ROOT,          // root dir has eng.traineddata
            cachePath:   os.tmpdir(),
            cacheMethod: 'write',
            gzip:        false,                // ← CRITICAL: local file is not gzipped
        });

        // Add timeout to prevent infinite hanging (60s for large/complex documents)
        const recognizePromise = worker.recognize(optimizedImagePath);
        const timeoutPromise = new Promise((_, reject) => {
             const id = setTimeout(() => { reject(new Error('OCR Timeout: Extraction took too long')); }, 60000);
             if (id.unref) id.unref();
        });

        let result;
        try {
            result = await Promise.race([recognizePromise, timeoutPromise]);
        } finally {
            await worker.terminate();
        }
        
        // Clean and normalize output
        const cleanText = result.data.text.replace(/\n\s*\n/g, '\n').trim();
        return cleanText;
    } catch (error) {
        logger.error(`OCR failed: ${error.message}`);
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
