// config/cloudinary.js
// Cloudinary setup — uploads go to the "veriscan-docs" folder.

const cloudinary = require('cloudinary').v2;

cloudinary.config({
    cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
    api_key:    process.env.CLOUDINARY_API_KEY,
    api_secret: process.env.CLOUDINARY_API_SECRET,
    secure: true,
});

/**
 * Upload a Buffer to Cloudinary.
 * IMPORTANT: Do NOT set both `folder` and a `public_id` containing slashes —
 * let Cloudinary auto-generate the public_id within the folder.
 *
 * @param {Buffer}  buffer       - File buffer from memoryStorage
 * @param {string}  originalName - For tagging/context only
 * @param {string}  [folder]     - Cloudinary folder (default: "veriscan-docs")
 * @returns {Promise<{ url: string, publicId: string }>}
 */
function uploadBuffer(buffer, originalName, folder = 'veriscan-docs') {
    return new Promise((resolve, reject) => {
        // Strip extension and special chars from display name
        const displayName = originalName
            .replace(/\.[^/.]+$/, '')           // remove extension
            .replace(/[^a-zA-Z0-9_-]/g, '_')   // sanitise
            .slice(0, 60);                       // Cloudinary max public_id length

        const uploadStream = cloudinary.uploader.upload_stream(
            {
                folder,
                resource_type: 'image',
                use_filename: false,
                unique_filename: true,
                // Let Cloudinary generate a unique ID; use display_name as context tag
                context: `originalName=${displayName}`,
                // Keep original quality for OCR accuracy
                quality: 'auto:best',
            },
            (error, result) => {
                if (error) {
                    return reject(new Error(`Cloudinary upload failed: ${error.message || JSON.stringify(error)}`));
                }
                resolve({
                    url:      result.secure_url,
                    publicId: result.public_id,
                });
            }
        );

        uploadStream.end(buffer);
    });
}

/**
 * Delete a previously uploaded file from Cloudinary (non-fatal wrapper).
 * @param {string} publicId
 */
async function deleteFile(publicId) {
    try {
        await cloudinary.uploader.destroy(publicId, { resource_type: 'image' });
    } catch (err) {
        console.warn(`[Cloudinary] deleteFile failed for ${publicId}: ${err.message}`);
    }
}

module.exports = { cloudinary, uploadBuffer, deleteFile };
