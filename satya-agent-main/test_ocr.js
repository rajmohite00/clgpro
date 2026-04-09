const agent = require('./services/ocrService.js');
console.log("Starting OCR test...");
agent.extractText('test_image.png').then(res => {
    console.log("Success:", res);
    process.exit(0);
}).catch(err => {
    console.error("Error:", err);
    process.exit(1);
});
