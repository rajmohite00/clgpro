const { logger } = require('../utils/logger');

// Verhoeff checksum arrays for Aadhaar mathematical verification
const d = [
    [0,1,2,3,4,5,6,7,8,9], [1,2,3,4,0,6,7,8,9,5], [2,3,4,0,1,7,8,9,5,6],
    [3,4,0,1,2,8,9,5,6,7], [4,0,1,2,3,9,5,6,7,8], [5,9,8,7,6,0,4,3,2,1],
    [6,5,9,8,7,1,0,4,3,2], [7,6,5,9,8,2,1,0,4,3], [8,7,6,5,9,3,2,1,0,4],
    [9,8,7,6,5,4,3,2,1,0]
];
const p = [
    [0,1,2,3,4,5,6,7,8,9], [1,5,7,6,2,8,3,0,9,4], [5,8,0,3,7,9,6,1,4,2],
    [8,9,1,6,0,4,3,5,2,7], [9,4,5,3,1,2,6,8,7,0], [4,2,8,6,5,7,3,9,0,1],
    [2,7,9,3,8,0,6,4,1,5], [7,0,4,6,9,1,3,2,5,8]
];

function validateVerhoeff(numStr) {
    let c = 0;
    const reversed = numStr.split('').map(Number).reverse();
    for (let i = 0; i < reversed.length; i++) {
        c = d[c][p[i % 8][reversed[i]]];
    }
    return c === 0;
}

// ============================================================
// OCR TEXT PREPROCESSOR
// Cleans common Tesseract OCR noise before keyword matching
// ============================================================
function preprocessOCR(rawText) {
    let text = rawText.toUpperCase();
    
    // 1. Normalize excessive whitespace (OCR often adds random spaces inside words)
    //    e.g. "B A N K" → "BANK", "M A R K S H E E T" → "MARKSHEET"
    //    But keep single spaces between real words
    
    // 2. Fix common OCR character substitutions
    //    These are applied to a copy for matching, not to the original
    text = text
        .replace(/[|]/g, 'I')          // pipe → I
        .replace(/[{}]/g, '')           // remove braces
        .replace(/[`'']/g, "'")         // normalize quotes
        .replace(/\r\n/g, '\n')         // normalize line endings
        .replace(/[ \t]{2,}/g, ' ');    // collapse multiple spaces/tabs to single space

    return text;
}

// ============================================================
// FUZZY KEYWORD MATCHER
// Checks if any keyword appears in text, tolerating OCR noise
// Handles: extra spaces inside words, minor character errors
// ============================================================
function fuzzyContains(text, keyword) {
    // Direct match first (fastest)
    if (text.includes(keyword)) return true;
    
    // Build a regex that allows optional spaces between each character
    // e.g. "BANK" → "B\s*A\s*N\s*K"
    // This catches OCR noise like "B A N K" or "BA NK"
    const spaced = keyword.split('').map(ch => {
        // Escape regex special chars
        const escaped = ch.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
        return escaped;
    }).join('\\s*');
    
    try {
        const regex = new RegExp(spaced);
        return regex.test(text);
    } catch (e) {
        return false;
    }
}

// Check if ANY keyword from a list fuzzy-matches in the text
function fuzzyContainsAny(text, keywords) {
    return keywords.some(kw => fuzzyContains(text, kw));
}

// Count how many keywords from a list fuzzy-match in the text
function fuzzyContainsCount(text, keywords) {
    return keywords.filter(kw => fuzzyContains(text, kw)).length;
}


// ============================================================
// VOTER ID (EPIC) Validation
// ============================================================
function validateVoterID(text) {
    const epicRegex = /\b[A-Z]{3}\d{7}\b/;
    // Also handle OCR noise: spaces in EPIC number like "A B C 1234567"
    const epicNoisyRegex = /\b[A-Z]\s*[A-Z]\s*[A-Z]\s*\d\s*\d\s*\d\s*\d\s*\d\s*\d\s*\d\b/;
    
    const voterKeywords = [
        'ELECTION COMMISSION', 'ELECTORAL', 'VOTER', 'EPIC',
        'ELECTORS PHOTO', 'IDENTITY CARD', 'PHOTO IDENTITY',
        'ELECTION', 'COMMISSION OF INDIA', 'NIRVACHAN',
        'ELECTOR', 'POLLING', 'CONSTITUENCY', 'PART NO'
    ];

    const epicMatch = text.match(epicRegex);
    const epicNoisyMatch = !epicMatch ? text.match(epicNoisyRegex) : null;
    const hasKeywords = fuzzyContainsAny(text, voterKeywords);

    let isValid = false;
    let formatOk = false;
    let epicNumber = null;

    if (epicMatch) {
        formatOk = true;
        isValid = true;
        epicNumber = epicMatch[0];
    } else if (epicNoisyMatch) {
        formatOk = true;
        isValid = true;
        epicNumber = epicNoisyMatch[0].replace(/\s/g, '');
    }

    return {
        detected: formatOk || hasKeywords,
        isValidFormat: isValid || hasKeywords,
        keywordsFound: hasKeywords,
        epicNumber
    };
}

// ============================================================
// 10TH MARKSHEET Validation — OCR-resilient
// ============================================================
function validateMarksheet(text) {
    // Board / Education keywords — extensive for OCR tolerance
    const boardKeywords = [
        'CBSE', 'CENTRAL BOARD', 'ICSE', 'CISCE',
        'STATE BOARD', 'BOARD OF SECONDARY EDUCATION',
        'SECONDARY SCHOOL', 'HIGH SCHOOL', 'SECONDARY EDUCATION',
        'BOARD OF EDUCATION', 'MARKSHEET', 'MARK SHEET', 'MARKS SHEET',
        'STATEMENT OF MARKS', 'MARKS STATEMENT', 'CERTIFICATE',
        'EXAMINATION', 'CLASS X', 'CLASS 10', 'STD X', 'STD 10',
        'MATRICULATION', 'MATRIC', 'SSC', 'SSLC',
        'HIGHER SECONDARY', 'RESULT', 'MARKS OBTAINED',
        'BOARD OF SCHOOL', 'ANNUAL EXAMINATION', 'EXAM',
        'SECONDARY', 'EDUCATION', 'MARKS', 'OBTAINED',
        'MAX MARKS', 'MAXIMUM MARKS', 'THEORY', 'PRACTICAL',
        'INTERNAL', 'EXTERNAL', 'SEAT NO', 'SEAT NUMBER',
        'REGD NO', 'REGISTRATION',
        'PROMOTED', 'COMPARTMENT', 'SUPPLEMENTARY',
        'GRADING', 'CREDIT', 'CGPA', 'GPA',
        'SCHOOL LEAVING', 'TRANSFER CERTIFICATE'
    ];

    // Subject patterns — very broad
    const subjectKeywords = [
        'ENGLISH', 'HINDI', 'MATHEMATICS', 'MATH', 'MATHS',
        'SCIENCE', 'SOCIAL', 'SANSKRIT', 'COMPUTER',
        'PHYSICS', 'CHEMISTRY', 'BIOLOGY', 'HISTORY',
        'GEOGRAPHY', 'ECONOMICS', 'TOTAL', 'AGGREGATE',
        'PERCENTAGE', 'GRADE', 'DIVISION', 'PASS', 'FAIL',
        'FIRST DIVISION', 'SECOND DIVISION', 'DISTINCTION',
        'EVS', 'ENVIRONMENTAL', 'MARATHI', 'GUJARATI', 'TAMIL',
        'TELUGU', 'KANNADA', 'BENGALI', 'URDU', 'PUNJABI',
        'GENERAL KNOWLEDGE', 'DRAWING', 'ARTS', 'CRAFT',
        'PHYSICAL EDUCATION', 'MORAL', 'CIVICS', 'HOME SCIENCE',
        'INFORMATION', 'TECHNOLOGY'
    ];

    // Roll number patterns
    const rollNumberRegex = /\b(?:ROLL\s*(?:NO|NUMBER|NUM)?\.?\s*[:\-]?\s*)(\d{3,15})\b/i;
    const seatNumberRegex = /\b(?:SEAT\s*(?:NO|NUMBER)?\.?\s*[:\-]?\s*)(\d{3,15})\b/i;

    // Marks patterns — very flexible
    const marksPatternRegex = /\b\d{1,3}\s*[\/]\s*\d{2,3}\b/;
    const percentageRegex = /\b\d{1,3}\.?\d{0,2}\s*%/;
    // Also catch standalone 2-3 digit numbers that appear repeatedly (marks columns)
    const marksColumnRegex = /(\b\d{2,3}\b\s*){3,}/;

    const hasKeywords = fuzzyContainsCount(text, boardKeywords) >= 1;
    const keywordCount = fuzzyContainsCount(text, boardKeywords);
    const hasSubjects = fuzzyContainsCount(text, subjectKeywords) >= 1;
    const subjectCount = fuzzyContainsCount(text, subjectKeywords);
    const hasRollNumber = rollNumberRegex.test(text) || seatNumberRegex.test(text);
    const hasMarksPattern = marksPatternRegex.test(text) || percentageRegex.test(text) || marksColumnRegex.test(text);

    // RELAXED DETECTION LOGIC:
    // Detected if:
    //   - Has 2+ board keywords (strong signal), OR
    //   - Has 1+ board keyword AND 2+ subjects, OR
    //   - Has 1+ board keyword AND marks pattern, OR
    //   - Has 1+ board keyword AND roll number, OR
    //   - Has 3+ subjects AND marks pattern (even without board keyword — pure content match), OR
    //   - Has 2+ subjects AND roll number AND marks pattern
    const detected = (
        (keywordCount >= 2) ||
        (hasKeywords && subjectCount >= 2) ||
        (hasKeywords && hasMarksPattern) ||
        (hasKeywords && hasRollNumber) ||
        (subjectCount >= 3 && hasMarksPattern) ||
        (subjectCount >= 2 && hasRollNumber && hasMarksPattern)
    );

    const isValidFormat = detected;

    return {
        detected,
        isValidFormat,
        keywordsFound: hasKeywords,
        subjectsFound: subjectCount >= 2,
        hasRollNumber,
        hasMarksPattern
    };
}

// ============================================================
// BANK PASSBOOK Validation — OCR-resilient
// ============================================================
function validateBankPassbook(text) {
    // Bank name keywords — very broad, includes abbreviations and common OCR errors
    const bankKeywords = [
        'STATE BANK', 'SBI', 'BANK OF INDIA', 'PUNJAB NATIONAL',
        'CANARA BANK', 'UNION BANK', 'BANK OF BARODA', 'HDFC',
        'ICICI', 'AXIS BANK', 'KOTAK', 'YES BANK', 'IDBI',
        'INDIAN BANK', 'CENTRAL BANK', 'UCO BANK', 'SYNDICATE',
        'ALLAHABAD BANK', 'ANDHRA BANK', 'DENA BANK', 'VIJAYA BANK',
        'BANK OF MAHARASHTRA', 'ORIENTAL BANK', 'CORPORATION BANK',
        'SAVINGS ACCOUNT', 'CURRENT ACCOUNT', 'PASSBOOK',
        'BRANCH', 'CUSTOMER ID', 'CIF', 'ACCOUNT HOLDER',
        // Additional for OCR resilience
        'BANK', 'SAVING', 'ACCOUNT', 'A/C', 'ACC',
        'PASS BOOK', 'ACCOUNT NO', 'ACCOUNT NUMBER', 'ACC NO',
        'IFSC', 'MICR', 'NEFT', 'RTGS',
        'PNB', 'BOI', 'BOB', 'IOB', 'OBC',
        'GRAMIN', 'GRAMEEN', 'COOPERATIVE', 'SAHAKARI',
        'BANDHAN', 'FEDERAL BANK', 'SOUTH INDIAN BANK',
        'KARUR VYSYA', 'CITY UNION', 'TMB', 'TAMILNAD',
        'KARNATAKA BANK', 'LAKSHMI VILAS', 'DCB', 'RBL',
        'FINO', 'PAYTM', 'AIRTEL PAYMENTS', 'JANALAKSHMI',
        'EQUITAS', 'UJJIVAN', 'AU SMALL FINANCE',
        'JOINT HOLDER', 'NOMINEE', 'OPENING DATE'
    ];

    const transactionKeywords = [
        'DEPOSIT', 'WITHDRAWAL', 'BALANCE', 'CREDIT', 'DEBIT',
        'TRANSACTION', 'INTEREST', 'OPENING BALANCE', 'CLOSING BALANCE',
        'NEFT', 'RTGS', 'IMPS', 'UPI', 'ATM', 'CHEQUE',
        'PARTICULARS', 'DR', 'CR', 'TRANSFER',
        'BY CASH', 'TO SELF', 'BY TRANSFER', 'NARRATION',
        'REFERENCE', 'CHQ', 'INR', 'AMOUNT'
    ];

    // IFSC code format: 4 uppercase letters + 0 + 6 alphanumeric
    // Also handle OCR noise (spaces inside IFSC)
    const ifscRegex = /\b[A-Z]{4}0[A-Z0-9]{6}\b/;
    const ifscNoisyRegex = /[A-Z]\s*[A-Z]\s*[A-Z]\s*[A-Z]\s*0\s*[A-Z0-9]\s*[A-Z0-9]\s*[A-Z0-9]\s*[A-Z0-9]\s*[A-Z0-9]\s*[A-Z0-9]/;
    
    // Account number: 9-18 digits (allow spaces inside from OCR)
    const accountRegex = /\b\d{9,18}\b/;
    const accountNoisyRegex = /(?:ACCOUNT|A\/C|ACC)\s*(?:NO|NUMBER|NUM)?\.?\s*[:\-]?\s*[\d\s]{9,25}/;
    
    // CIF / Customer ID
    const cifRegex = /\b(?:CIF|CUSTOMER\s*ID)[:\s]*(\d{5,15})\b/;

    const bankKeywordCount = fuzzyContainsCount(text, bankKeywords);
    const hasBankKeywords = bankKeywordCount >= 1;
    const transKeywordCount = fuzzyContainsCount(text, transactionKeywords);
    const hasTransactionKeywords = transKeywordCount >= 1;
    const hasIFSC = ifscRegex.test(text) || ifscNoisyRegex.test(text);
    const hasAccountNumber = accountRegex.test(text) || accountNoisyRegex.test(text);
    const hasCIF = cifRegex.test(text);

    // RELAXED DETECTION LOGIC:
    // Detected if:
    //   - Has 3+ bank keywords (strong signal by itself), OR
    //   - Has "BANK" or bank name + (IFSC or account number or transaction keywords), OR
    //   - Has "PASSBOOK" keyword, OR
    //   - Has IFSC code + account number (structural match alone), OR
    //   - Has "ACCOUNT" + "BANK" (simple combo), OR
    //   - Has 2+ bank keywords + any structural element
    const hasPassbookKeyword = fuzzyContains(text, 'PASSBOOK') || fuzzyContains(text, 'PASS BOOK');
    const hasBankWord = fuzzyContains(text, 'BANK');
    const hasAccountWord = fuzzyContains(text, 'ACCOUNT') || fuzzyContains(text, 'A/C');
    const hasSavingsWord = fuzzyContains(text, 'SAVING') || fuzzyContains(text, 'SAVINGS');
    
    const detected = (
        hasPassbookKeyword ||
        (bankKeywordCount >= 3) ||
        (hasBankWord && hasIFSC) ||
        (hasBankWord && hasAccountNumber && hasAccountWord) ||
        (hasBankWord && hasTransactionKeywords) ||
        (hasBankWord && hasSavingsWord) ||
        (hasIFSC && hasAccountNumber) ||
        (hasBankKeywords && (hasIFSC || hasAccountNumber || hasTransactionKeywords || hasCIF)) ||
        (hasAccountWord && hasSavingsWord) ||
        (hasAccountWord && hasIFSC)
    );

    // Valid format if structural elements align
    const isValidFormat = detected;

    // Validate IFSC
    let ifscValid = false;
    const ifscMatch = text.match(ifscRegex);
    let ifscCode = null;
    if (ifscMatch) {
        ifscValid = true;
        ifscCode = ifscMatch[0];
    } else {
        const noisyMatch = text.match(ifscNoisyRegex);
        if (noisyMatch) {
            ifscValid = true;
            ifscCode = noisyMatch[0].replace(/\s/g, '');
        }
    }

    return {
        detected,
        isValidFormat,
        keywordsFound: hasBankKeywords,
        hasIFSC,
        ifscValid,
        ifscCode,
        hasAccountNumber,
        hasTransactionKeywords
    };
}


// ============================================================
// MAIN VALIDATION ORCHESTRATOR
// Uses scoring to determine the BEST match among all document types
// instead of a rigid priority chain
// ============================================================
const validateDocument = (ocrText) => {
    const text = preprocessOCR(ocrText);
    
    // Log the cleaned OCR text for debugging
    logger.info(`[ValidationService] OCR Text (first 300 chars): ${text.substring(0, 300).replace(/\n/g, ' | ')}`);
    
    // --- Aadhaar Detection ---
    const aadhaarDigitsRegex = /\b(\d{4})[\s\-]*(\d{4})[\s\-]*(\d{4})\b/;
    const aadhaarKeywords = fuzzyContains(text, 'AADHAAR') || 
                            fuzzyContains(text, 'UNIQUE IDENTIFICATION') ||
                            fuzzyContains(text, 'UIDAI');
    const aadhaarGovtKeywords = fuzzyContains(text, 'GOVT OF INDIA') || fuzzyContains(text, 'GOVERNMENT OF INDIA');
    
    // --- PAN Detection ---
    const panRegex = /\b[A-Z]{5}[0-9O]{4}[A-Z]\b/;
    const panKeywords = fuzzyContains(text, 'INCOME TAX DEPARTMENT') || fuzzyContains(text, 'PERMANENT ACCOUNT NUMBER');
    
    let isValidFormat = false;
    let documentType = "Unknown";
    let isMathematicallyFake = false;
    let extraValidation = {};

    // === SCORING SYSTEM ===
    // Instead of rigid priority, compute confidence score for each type
    const scores = { aadhaar: 0, pan: 0, voter: 0, marksheet: 0, passbook: 0 };

    // --- AADHAAR scoring ---
    const aadhaarMatch = text.match(aadhaarDigitsRegex);
    let verhoeffPassed = false;
    if (aadhaarMatch) {
        const fullNumber = aadhaarMatch[1] + aadhaarMatch[2] + aadhaarMatch[3];
        verhoeffPassed = validateVerhoeff(fullNumber);
        if (verhoeffPassed) {
            scores.aadhaar += 5;
        } else {
            isMathematicallyFake = true;
            scores.aadhaar += 3; // Still likely an Aadhaar attempt
        }
    }
    if (aadhaarKeywords) scores.aadhaar += 4;
    if (aadhaarGovtKeywords && !fuzzyContains(text, 'BANK')) scores.aadhaar += 1; // Don't count "GOVT" if "BANK" also present

    // --- PAN scoring ---
    if (panRegex.test(text)) scores.pan += 4;
    if (panKeywords) scores.pan += 4;

    // --- Voter scoring ---
    const voterResult = validateVoterID(text);
    if (voterResult.detected) scores.voter += 3;
    if (voterResult.isValidFormat) scores.voter += 2;
    if (voterResult.keywordsFound) scores.voter += 2;

    // --- Marksheet scoring ---
    const marksheetResult = validateMarksheet(text);
    if (marksheetResult.detected) scores.marksheet += 4;
    if (marksheetResult.subjectsFound) scores.marksheet += 2;
    if (marksheetResult.hasRollNumber) scores.marksheet += 1;
    if (marksheetResult.hasMarksPattern) scores.marksheet += 2;

    // --- Passbook scoring ---
    const passbookResult = validateBankPassbook(text);
    if (passbookResult.detected) scores.passbook += 4;
    if (passbookResult.hasIFSC) scores.passbook += 2;
    if (passbookResult.hasAccountNumber) scores.passbook += 1;
    if (passbookResult.hasTransactionKeywords) scores.passbook += 2;

    logger.info(`[ValidationService] Detection Scores: Aadhaar=${scores.aadhaar}, PAN=${scores.pan}, Voter=${scores.voter}, Marksheet=${scores.marksheet}, Passbook=${scores.passbook}`);

    // --- Pick the highest-scoring type ---
    const maxScore = Math.max(...Object.values(scores));
    
    if (maxScore === 0) {
        documentType = "Unknown";
        isValidFormat = false;
    } else if (scores.aadhaar === maxScore && scores.pan === maxScore && scores.aadhaar >= 3) {
        documentType = "Aadhaar & PAN detected";
        isValidFormat = true;
    } else if (scores.aadhaar === maxScore && scores.aadhaar >= 3) {
        documentType = "Aadhaar";
        isValidFormat = !isMathematicallyFake;
    } else if (scores.pan === maxScore && scores.pan >= 3) {
        documentType = "PAN";
        isValidFormat = true;
    } else if (scores.voter === maxScore && scores.voter >= 3) {
        documentType = "Voter ID (EPIC)";
        isValidFormat = voterResult.isValidFormat;
        extraValidation = {
            epicNumber: voterResult.epicNumber,
            voterKeywordsFound: voterResult.keywordsFound
        };
    } else if (scores.marksheet === maxScore && scores.marksheet >= 3) {
        documentType = "10th Marksheet";
        isValidFormat = marksheetResult.isValidFormat;
        extraValidation = {
            subjectsFound: marksheetResult.subjectsFound,
            hasRollNumber: marksheetResult.hasRollNumber,
            hasMarksPattern: marksheetResult.hasMarksPattern
        };
    } else if (scores.passbook === maxScore && scores.passbook >= 3) {
        documentType = "Bank Passbook";
        isValidFormat = passbookResult.isValidFormat;
        extraValidation = {
            ifscCode: passbookResult.ifscCode,
            ifscValid: passbookResult.ifscValid,
            hasAccountNumber: passbookResult.hasAccountNumber,
            hasTransactionData: passbookResult.hasTransactionKeywords
        };
    }

    return {
        documentType,
        isValidFormat,
        keywordsFound: (aadhaarKeywords || panKeywords || voterResult.keywordsFound || marksheetResult.keywordsFound || passbookResult.keywordsFound),
        isMathematicallyFake,
        extraValidation
    };
};

module.exports = { validateDocument };
