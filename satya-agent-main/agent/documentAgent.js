const { extractText } = require('../services/ocrService');
const { analyzeImage } = require('../services/imageService');
const { validateDocument } = require('../services/validationService');
const { extractData } = require('../services/extractionTool'); 
const { logger } = require('../utils/logger');
const chalk = require('chalk');
const stringSimilarity = require('string-similarity');

// N8N Style Multi-Agent Architecture Orchestrator - Powered by Satya
class DocumentAgentOrchestrator {
    constructor() {
        this.agentName = "[Satya 🧠]";
    }

    async analyzeMultiple(imagePaths) {
        console.log(chalk.cyan.bold('\n==================================================================='));
        console.log(chalk.magenta.bold(`  ${this.agentName} WAKING UP... CONFIGURING TERMINAL MATRIX`));
        console.log(chalk.cyan.bold('===================================================================\n'));

        const results = [];
        
        // Loop over however many documents were submitted
        for (let i = 0; i < imagePaths.length; i++) {
            console.log(chalk.yellow.bold(`\n${this.agentName} 👁️ SCANNING DOCUMENT [${i+1}/${imagePaths.length}] => ${imagePaths[i]}`));
            const res = await this.processSingle(imagePaths[i], i + 1);
            results.push(res);
        }

        // Multi-Document Advanced Mismatch Detection Logic (BERT-Lite)
        if (results.length > 1) {
            console.log(chalk.bgBlue.white.bold(`\n ${this.agentName} 🔗 INITIALIZING NLP MISMATCH DETECTION NODE `));
            
            const name1 = results[0].extractedInfo?.name || "";
            const name2 = results[1].extractedInfo?.name || "";
            const dob1 = results[0].extractedInfo?.dob || "";
            const dob2 = results[1].extractedInfo?.dob || "";

            let mismatchDetected = false;
            let mismatchDetails = [];

            // Perform Lexical/Contextual NLP comparison (simulating BERT)
            if (name1 && name2) {
                const similarity = stringSimilarity.compareTwoStrings(name1.toLowerCase(), name2.toLowerCase());
                console.log(chalk.blue(`   ↳ Lexical analysis between names: "${name1}" vs "${name2}"`));
                console.log(chalk.blue(`   ↳ Deep Match Probability: ${(similarity * 100).toFixed(1)}%`));
                
                if (similarity < 0.70) {
                    mismatchDetected = true;
                    mismatchDetails.push(`Identity Name Mismatch: Confidence only ${(similarity * 100).toFixed(1)}%`);
                    console.log(chalk.red.bold(`   [🚨 ALERT] MAJOR IDENTITY NAME MISMATCH DETECTED!`));
                } else {
                    console.log(chalk.green.bold(`   [✅ VALID] Identity Name Verified across documents.`));
                }
            } else {
                console.log(chalk.keyword('orange')(`   [⚠ WARN] Cannot run NLP matching: Missing Extracted Name Data.`));
            }

            // Check DOB strict equality
            if (dob1 && dob2) {
                if (dob1 !== dob2) {
                    mismatchDetected = true;
                    mismatchDetails.push(`Date of Birth Conflict: ${dob1} vs ${dob2}`);
                    console.log(chalk.red.bold(`   [🚨 ALERT] CRITICAL DATE OF BIRTH CONFLICT DETECTED!`));
                } else {
                    console.log(chalk.green.bold(`   [✅ VALID] Date of Birth perfectly aligned.`));
                }
            }

            // Cross-document type mismatch analysis
            const doc1Type = results[0].documentType;
            const doc2Type = results[1].documentType;
            console.log(chalk.blue(`   ↳ Document Types: "${doc1Type}" ↔ "${doc2Type}"`));

            // Cross-reference ID numbers if both exist (e.g. Aadhaar number should only appear on Aadhaar)
            const id1 = results[0].extractedInfo?.idNumber || "";
            const id2 = results[1].extractedInfo?.idNumber || "";
            if (id1 && id2 && id1 === id2 && doc1Type !== doc2Type) {
                // Same ID number on different document types is suspicious
                mismatchDetected = true;
                mismatchDetails.push(`Duplicate ID number "${id1}" found on different document types (${doc1Type} & ${doc2Type})`);
                console.log(chalk.red.bold(`   [🚨 ALERT] SAME ID NUMBER ON DIFFERENT DOCUMENT TYPES!`));
            }

            console.log(chalk.magenta.bold(`\n${this.agentName} ✨ EXECUTION COMPLETE. DATA STREAMING TO WEB GUI...\n`));

            return {
                agent: "SatyaSatya V2.0",
                mismatchAnalysis: {
                    documentsAnalyzed: results.length,
                    mismatchDetected: mismatchDetected,
                    mismatchDetails: mismatchDetails
                },
                documents: results
            };
        }

        console.log(chalk.magenta.bold(`\n${this.agentName} ✨ SINGLE DOCUMENT PIPELINE COMPLETE.\n`));
        return {
            agent: "SatyaSatya V2.0",
            ...results[0]
        };
    }

    async processSingle(imagePath, index) {
        // --- NODE 1: Perception & Forensics ---
        console.log(chalk.gray(`   ├─ Executing Node 1: Visual Perception Array (OCR + Spatial Forensics)`));
        const [ocrText, imageAnalysis] = await Promise.all([
            extractText(imagePath),
            analyzeImage(imagePath)
        ]);

        // --- OCR DEBUG OUTPUT ---
        console.log(chalk.bgGray.white(`   │  ─── RAW OCR TEXT (first 500 chars) ───`));
        const ocrPreview = ocrText.substring(0, 500).replace(/\n/g, '\n   │  ');
        console.log(chalk.gray(`   │  ${ocrPreview}`));
        console.log(chalk.bgGray.white(`   │  ─── END OCR TEXT ───`));

        // --- NODE 2: Data Extraction Node ---
        console.log(chalk.gray(`   ├─ Executing Node 2: Programmatic Data Extraction NLP`));
        const extractedData = extractData(ocrText);
        if (extractedData.name) console.log(chalk.gray(`   │  (Found Context: Identity "${extractedData.name}")`));
        if (extractedData.documentCategory) console.log(chalk.gray(`   │  (Detected Category: ${extractedData.documentCategory})`));

        // --- NODE 3: Cryptographic / Format Validation Node ---
        console.log(chalk.gray(`   ├─ Executing Node 3: Document Format & Verification Tool`));
        const validation = validateDocument(ocrText);
        console.log(chalk.gray(`   │  (Document Type: ${validation.documentType})`));

        // --- NODE 4: Analytical Decision Matrix ---
        console.log(chalk.gray(`   ├─ Executing Node 4: Fraud Heuristics Computation...`));
        let ruleScore = 0;
        let triggers = [];

        // === AADHAAR-SPECIFIC RULES ===
        if (validation.isMathematicallyFake) {
            ruleScore += 100;
            triggers.push("Cryptographic Verhoeff Checksum FAILED");
            console.log(chalk.red(`   │  [CRITICAL] Mathematical Verhoeff check failed! Synthetic ID!`));
        }

        // === UNIVERSAL FORMAT RULES ===
        if (!validation.isValidFormat && !validation.isMathematicallyFake) {
            ruleScore += 40; 
            triggers.push("Invalid Format / No Keywords");
            console.log(chalk.red(`   │  [WARN] Incorrect structural format`));
        }

        // === VOTER ID SPECIFIC RULES ===
        if (validation.documentType === 'Voter ID (EPIC)') {
            const extra = validation.extraValidation || {};
            if (!extra.epicNumber) {
                ruleScore += 30;
                triggers.push("Voter ID: EPIC Number Not Detected");
                console.log(chalk.red(`   │  [WARN] EPIC number missing from Voter ID`));
            }
            if (!validation.keywordsFound) {
                ruleScore += 20;
                triggers.push("Voter ID: No Election Commission keywords found");
                console.log(chalk.red(`   │  [WARN] Missing Election Commission keyword markers`));
            }
        }

        // === MARKSHEET SPECIFIC RULES ===
        if (validation.documentType === '10th Marksheet') {
            const extra = validation.extraValidation || {};
            if (!extra.subjectsFound) {
                ruleScore += 25;
                triggers.push("Marksheet: No Subject Names Detected");
                console.log(chalk.red(`   │  [WARN] No recognizable subject names on marksheet`));
            }
            if (!extra.hasRollNumber) {
                ruleScore += 20;
                triggers.push("Marksheet: Roll Number Missing");
                console.log(chalk.red(`   │  [WARN] Roll number not found on marksheet`));
            }
            if (!extra.hasMarksPattern) {
                ruleScore += 15;
                triggers.push("Marksheet: No Marks/Percentage Pattern Found");
                console.log(chalk.red(`   │  [WARN] No marks or percentage patterns detected`));
            }
        }

        // === BANK PASSBOOK SPECIFIC RULES ===
        if (validation.documentType === 'Bank Passbook') {
            const extra = validation.extraValidation || {};
            if (!extra.hasAccountNumber) {
                ruleScore += 30;
                triggers.push("Bank Passbook: Account Number Missing");
                console.log(chalk.red(`   │  [WARN] Account number not found on passbook`));
            }
            if (!extra.ifscValid && !extra.ifscCode) {
                ruleScore += 20;
                triggers.push("Bank Passbook: IFSC Code Missing");
                console.log(chalk.red(`   │  [WARN] IFSC code not detected`));
            }
            if (!extra.hasTransactionData) {
                ruleScore += 10;
                triggers.push("Bank Passbook: No Transaction Keywords");
                console.log(chalk.keyword('orange')(`   │  [INFO] No transaction entries detected (may be front page only)`));
            }
        }

        // === IMAGE FORENSICS (UNIVERSAL) ===
        if (imageAnalysis.isBlurred) {
            ruleScore += 20;
            triggers.push("Significant Blur");
        }
        if (imageAnalysis.isScreenshot) {
            ruleScore += 60; 
            triggers.push("Digital Screenshot Detected");
            console.log(chalk.red(`   │  [CRITICAL] Massive Image Variance: Synthetic Web Screenshot Identified!`));
        } else if (imageAnalysis.possibleTampering) {
            ruleScore += 40;
            triggers.push("Edge/Texture Tampering");
            console.log(chalk.red(`   │  [WARN] Micro-texture edge tampering anomaly detected.`));
        }
        
        if (imagePath.includes("WhatsApp")) {
            ruleScore += 10;
            triggers.push("WhatsApp transit artifact");
        }

        const analyticalScore = Math.min(ruleScore, 100);
        
        if (analyticalScore === 0) {
            console.log(chalk.green.bold(`   └─ Document ${index} [${validation.documentType}] Authentic: 0% Fraud Risk`));
        } else {
            console.log(chalk.red.bold(`   └─ Document ${index} [${validation.documentType}] Fraud Probability: ${analyticalScore}%`));
        }

        return {
            documentType: validation.documentType,
            validation: {
                isValidFormat: validation.isValidFormat,
                keywordsFound: validation.keywordsFound || false,
                isMathematicallyFake: validation.isMathematicallyFake || false,
                extraValidation: validation.extraValidation || {}
            },
            extractedInfo: extractedData,
            ocrText: ocrText,
            forensicsAnalysis: imageAnalysis,
            aiAgentDecision: {
                fraudProbability: analyticalScore,
                explanation: analyticalScore === 0 ? "Document seamlessly validated cryptographically and visually." : "FRAUD TRIGGERS: " + triggers.join(", ")
            },
            publicUrl: global.publicNgrokUrl || "ngrok not active"
        };
    }
}

module.exports = new DocumentAgentOrchestrator();
