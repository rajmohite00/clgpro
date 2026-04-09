const { Jimp } = require('jimp'); // Using the pure-JS image manipulation library
const { logger } = require('../utils/logger');

const analyzeImage = async (imagePath) => {
    try {
        logger.info(`Starting highly optimized Pure-JS Forensics for ${imagePath}`);

        // Read image and scale down dramatically (300px width) for massive performance boost
        const image = await Jimp.read(imagePath);
        image.resize({ w: 300 });
        image.greyscale(); // Convert to grayscale for laplacian/blur gradient checking

        const width = image.bitmap.width;
        const height = image.bitmap.height;
        const data = image.bitmap.data;

        let sum = 0;
        let sumSq = 0;
        let count = 0;
        let edgePixels = 0;

        // Perform spatial convolution to detect blur (variance of Laplacian) & edges
        for (let y = 1; y < height - 1; y++) {
            for (let x = 1; x < width - 1; x++) {
                const idx = (y * width + x) * 4;
                const topVal = data[((y - 1) * width + x) * 4];
                const bottomVal = data[((y + 1) * width + x) * 4];
                const leftVal = data[(y * width + (x - 1)) * 4];
                const rightVal = data[(y * width + (x + 1)) * 4];

                const centerVal = data[idx];

                // Laplacian response: 4*center - top - bottom - left - right
                const laplacian = (4 * centerVal) - topVal - bottomVal - leftVal - rightVal;
                
                sum += laplacian;
                sumSq += (laplacian * laplacian);
                count++;

                // Basic horizontal/vertical gradient for edge detection (Sobel magnitude)
                const gx = rightVal - leftVal;
                const gy = bottomVal - topVal;
                const gradient = Math.sqrt(gx * gx + gy * gy);
                
                // Threshold for counting an edge pixel
                if (gradient > 45) {
                    edgePixels++;
                }
            }
        }

        const mean = sum / count;
        const variance = (sumSq / count) - (mean * mean);
        
        // Threshold for blur detection
        const isBlurred = variance < 80;

        // A massive variance (> 5000) implies a digital template / screenshot instead of a physical camera photo
        // Real phone photos have noise that brings variance cleanly into the hundreds. Perfect digital fakes score >5000.
        const isScreenshot = variance > 4500;

        // Edge density: fraction of pixels considered "edges"
        const edgeDensity = edgePixels / count;
        
        // Suspiciously smooth images (synthetic clones) or perfectly digital layouts flag tampering
        const possibleTampering = edgeDensity < 0.02 || isScreenshot || edgeDensity > 0.45;

        logger.info(`Forensics completed: Variance=${variance.toFixed(2)}, Edge Density=${edgeDensity.toFixed(4)}, Digital Fake Flags: ${isScreenshot}`);

        return {
            isBlurred,
            possibleTampering,
            isScreenshot
        };
    } catch (error) {
        logger.error(`Image Analysis failed: ${error.message}`);
        // Return clean defaults to not crash the Multi-Agent orchestrator pipeline
        return {
            isBlurred: false,
            possibleTampering: false,
            isScreenshot: false
        };
    }
};

module.exports = { analyzeImage };
