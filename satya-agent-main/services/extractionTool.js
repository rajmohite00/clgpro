const { logger } = require('../utils/logger');

// ============================================================
// FUZZY KEYWORD MATCHER (same as validationService)
// Handles OCR noise like random spaces inside words
// ============================================================
function fuzzyContains(text, keyword) {
    if (text.includes(keyword)) return true;
    const spaced = keyword.split('').map(ch => {
        const escaped = ch.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
        return escaped;
    }).join('\\s*');
    try {
        return new RegExp(spaced).test(text);
    } catch (e) {
        return false;
    }
}

function fuzzyContainsCount(text, keywords) {
    return keywords.filter(kw => fuzzyContains(text, kw)).length;
}

function preprocessOCR(rawText) {
    let text = rawText.toUpperCase();
    text = text
        .replace(/[|]/g, 'I')
        .replace(/[{}]/g, '')
        .replace(/[`'']/g, "'")
        .replace(/\r\n/g, '\n')
        .replace(/[ \t]{2,}/g, ' ');
    return text;
}


const extractData = (ocrText) => {
    const text = preprocessOCR(ocrText);
    
    // Log OCR text for debugging
    logger.info(`[ExtractionTool] OCR Text (first 200 chars): ${text.substring(0, 200).replace(/\n/g, ' | ')}`);
    
    const extractedInfo = {
        name: null,
        dob: null,
        gender: null,
        idNumber: null,
        documentCategory: null,
        additionalFields: {}
    };

    // ================================================================
    // STEP 1: Detect document category from OCR text
    // ================================================================
    const category = detectCategory(text);
    extractedInfo.documentCategory = category;
    logger.info(`[ExtractionTool] Detected Category: ${category}`);

    // ================================================================
    // STEP 2: Extract ID Number based on document type
    // ================================================================
    const aadhaarRegex = /\b(\d{4})[\s\-]*(\d{4})[\s\-]*(\d{4})\b/;
    const panRegex = /\b[A-Z]{5}[0-9O]{4}[A-Z]\b/;
    const epicRegex = /\b[A-Z]{3}\d{7}\b/;
    const epicNoisyRegex = /\b[A-Z]\s*[A-Z]\s*[A-Z]\s*\d\s*\d\s*\d\s*\d\s*\d\s*\d\s*\d\b/;

    if (category === 'AADHAAR' && aadhaarRegex.test(text)) {
        extractedInfo.idNumber = text.match(aadhaarRegex)[0].replace(/[\s\-]/g, '');
    } else if (category === 'PAN' && panRegex.test(text)) {
        extractedInfo.idNumber = text.match(panRegex)[0];
    } else if (category === 'VOTER_ID') {
        const em = text.match(epicRegex);
        const emNoisy = !em ? text.match(epicNoisyRegex) : null;
        if (em) extractedInfo.idNumber = em[0];
        else if (emNoisy) extractedInfo.idNumber = emNoisy[0].replace(/\s/g, '');
    } else if (category === 'BANK_PASSBOOK') {
        // For bank passbook, extract account number as primary ID
        const accRegex = /(?:ACCOUNT|A\/C|ACC)\s*(?:NO|NUMBER|NUM)?\.?\s*[:\-]?\s*(\d{9,18})/;
        const accMatch = text.match(accRegex);
        if (accMatch) extractedInfo.idNumber = accMatch[1];
        else {
            // Fallback: look for 9-18 digit number that's not a phone number
            const genericAcc = text.match(/\b(\d{9,18})\b/);
            if (genericAcc) extractedInfo.idNumber = genericAcc[1];
        }
    } else if (category === 'MARKSHEET') {
        // For marksheet, extract roll number as primary ID
        const rollRegex = /(?:ROLL|SEAT)\s*(?:NO|NUMBER|NUM)?\.?\s*[:\-]?\s*(\d{3,15})/;
        const rollMatch = text.match(rollRegex);
        if (rollMatch) extractedInfo.idNumber = rollMatch[1];
    } else {
        // Generic fallback
        if (aadhaarRegex.test(text)) {
            extractedInfo.idNumber = text.match(aadhaarRegex)[0].replace(/[\s\-]/g, '');
        } else if (panRegex.test(text)) {
            extractedInfo.idNumber = text.match(panRegex)[0];
        } else if (epicRegex.test(text)) {
            extractedInfo.idNumber = text.match(epicRegex)[0];
        }
    }
    
    // ================================================================
    // STEP 3: Extract DOB (universal)
    // ================================================================
    const dobRegex = /(?:DOB|YEAR OF BIRTH|YOB|DATE OF BIRTH|DOB:|BIRTH\s*DATE|D\.O\.B|BORN ON|DATE\s*OF\s*BIRTH)[\s:]*([0-9]{2}[\/\-\.][0-9]{2}[\/\-\.][0-9]{4}|[0-9]{4})/i;
    const dobMatch = text.match(dobRegex);
    if (dobMatch) extractedInfo.dob = dobMatch[1];

    // Fallback DOB: find common date patterns DD/MM/YYYY or DD-MM-YYYY or DD.MM.YYYY
    if (!extractedInfo.dob) {
        const fallbackDobRegex = /\b(\d{2}[\/\-\.]\d{2}[\/\-\.]\d{4})\b/;
        const fallbackMatch = text.match(fallbackDobRegex);
        if (fallbackMatch) extractedInfo.dob = fallbackMatch[1];
    }

    // ================================================================
    // STEP 4: Extract Gender
    // ================================================================
    const genderRegex = /\b(MALE|FEMALE|TRANSGENDER)\b/;
    const genderMatch = text.match(genderRegex);
    if (genderMatch) extractedInfo.gender = genderMatch[1];

    // ================================================================
    // STEP 5: Extract Name intelligently
    // ================================================================
    const lines = text.split('\n').filter(line => line.trim().length > 2);
    
    const noisePatterns = [
        'INDIA', 'GOVERNMENT', 'TAX', 'ELECTION', 'COMMISSION',
        'DEPARTMENT', 'BOARD', 'EDUCATION', 'BANK', 'BRANCH',
        'SECONDARY', 'CBSE', 'ICSE', 'STATE', 'MARKSHEET',
        'CERTIFICATE', 'STATEMENT', 'PASSBOOK', 'ACCOUNT',
        'AADHAAR', 'PERMANENT', 'INCOME', 'ELECTORAL', 'PHOTO',
        'IDENTITY CARD', 'MARKS', 'EXAMINATION', 'RESULT',
        'SAVINGS', 'CURRENT', 'IFSC', 'NEFT', 'RTGS',
        'CENTRAL', 'NATIONAL', 'RESERVE'
    ];

    for (let i = 0; i < lines.length; i++) {
        if (dobRegex.test(lines[i]) || genderRegex.test(lines[i])) {
            if (i > 0 && !noisePatterns.some(np => lines[i-1].includes(np))) {
                const cleaned = lines[i-1].trim().replace(/[^a-zA-Z\s]/g, '').trim();
                // Basic validation for name length and structure
                if (cleaned.length > 2 && /[A-Z]+\s+[A-Z]+/.test(cleaned)) extractedInfo.name = cleaned;
            } else if (i > 1 && !noisePatterns.some(np => lines[i-2].includes(np))) {
                const cleaned = lines[i-2].trim().replace(/[^a-zA-Z\s]/g, '').trim();
                if (cleaned.length > 2 && /[A-Z]+\s+[A-Z]+/.test(cleaned)) extractedInfo.name = cleaned;
            }
            break;
        }
    }

    // Fallback name extraction with many patterns
    if (!extractedInfo.name) {
        const namePatterns = [
            /(?:NAME\s*OF\s*(?:CANDIDATE|STUDENT|ACCOUNT\s*HOLDER|HOLDER|DEPOSITOR|ELECTOR))[\s:]+([A-Z][A-Z\s\.]{2,40})/,
            /(?:CANDIDATE(?:'?S)?\s*NAME|STUDENT(?:'?S)?\s*NAME|HOLDER(?:'?S)?\s*NAME|ELECTOR(?:'?S)?\s*NAME)[\s:]+([A-Z][A-Z\s\.]{2,40})/,
            /(?:ACCOUNT\s*HOLDER|A\/C\s*HOLDER)[\s:]+([A-Z][A-Z\s\.]{2,40})/,
            /(?:^|\n)\s*NAME[\s:]+([A-Z][A-Z\s\.]{2,40})/
        ];
        for (const pat of namePatterns) {
            const m = text.match(pat);
            if (m) {
                const cleaned = m[1].trim().replace(/[^a-zA-Z\s]/g, '').trim();
                if (cleaned.length > 2) {
                    extractedInfo.name = cleaned;
                    break;
                }
            }
        }
    }
    
    // Absolute last resort for Name: Look for a clean line of 2 or 3 capitalized words
    if (!extractedInfo.name) {
        // Iterate through lines again, ignoring known noise patterns and looking for pure names
        for (let i = 0; i < lines.length; i++) {
            const line = lines[i].trim();
            // Skip short lines, lines with numbers, or lines matching noise
            if (line.length < 5 || /\d/.test(line) || noisePatterns.some(np => line.includes(np))) continue;
            
            // Check if line consists of 2 or 3 words, each with at least 3 letters
            const words = line.split(/\s+/);
            if (words.length >= 2 && words.length <= 4) {
                const isValidName = words.every(w => /^[A-Z]{3,}$/.test(w));
                if (isValidName) {
                    extractedInfo.name = line.replace(/[^a-zA-Z\s]/g, '').trim();
                    break; // Pick the first matched pure name as likely candidate
                }
            }
        }
    }

    // ================================================================
    // STEP 6: Category-specific additional extraction
    // ================================================================
    switch (category) {
        case 'VOTER_ID':
            extractVoterIDFields(text, extractedInfo);
            break;
        case 'MARKSHEET':
            extractMarksheetFields(text, extractedInfo);
            break;
        case 'BANK_PASSBOOK':
            extractBankPassbookFields(text, extractedInfo);
            break;
        default:
            break;
    }

    return extractedInfo;
};

// ================================================================
// CATEGORY DETECTOR — OCR-resilient with fuzzy matching
// ================================================================
function detectCategory(text) {
    const scores = {
        AADHAAR: 0,
        PAN: 0,
        VOTER_ID: 0,
        MARKSHEET: 0,
        BANK_PASSBOOK: 0
    };

    // ---- Aadhaar signals ----
    if (fuzzyContains(text, 'AADHAAR')) scores.AADHAAR += 4;
    if (fuzzyContains(text, 'UNIQUE IDENTIFICATION')) scores.AADHAAR += 4;
    if (fuzzyContains(text, 'UIDAI')) scores.AADHAAR += 4;
    if (fuzzyContains(text, 'GOVT OF INDIA') || fuzzyContains(text, 'GOVERNMENT OF INDIA')) scores.AADHAAR += 1;
    if (/\b\d{4}\s*\d{4}\s*\d{4}\b/.test(text)) scores.AADHAAR += 2;

    // ---- PAN signals ----
    if (fuzzyContains(text, 'PERMANENT ACCOUNT NUMBER')) scores.PAN += 4;
    if (fuzzyContains(text, 'INCOME TAX')) scores.PAN += 4;
    if (/\b[A-Z]{5}[0-9O]{4}[A-Z]\b/.test(text)) scores.PAN += 3;

    // ---- Voter ID signals ----
    if (fuzzyContains(text, 'ELECTION COMMISSION')) scores.VOTER_ID += 4;
    if (fuzzyContains(text, 'ELECTORAL')) scores.VOTER_ID += 3;
    if (fuzzyContains(text, 'VOTER')) scores.VOTER_ID += 2;
    if (fuzzyContains(text, 'EPIC')) scores.VOTER_ID += 2;
    if (fuzzyContains(text, 'NIRVACHAN')) scores.VOTER_ID += 4;
    if (fuzzyContains(text, 'ELECTORS PHOTO')) scores.VOTER_ID += 3;
    if (/\b[A-Z]{3}\d{7}\b/.test(text)) scores.VOTER_ID += 3;

    // ---- Marksheet signals (very broad) ----
    const marksheetStrongKeywords = ['MARKSHEET', 'MARK SHEET', 'MARKS SHEET', 'STATEMENT OF MARKS', 'MARKS STATEMENT'];
    const marksheetBoardKeywords = ['CBSE', 'ICSE', 'CISCE', 'BOARD OF SECONDARY', 'SECONDARY EDUCATION', 'STATE BOARD', 'BOARD OF EDUCATION'];
    const marksheetExamKeywords = ['EXAMINATION', 'ANNUAL', 'CLASS X', 'CLASS 10', 'STD X', 'STD 10', 'MATRICULATION', 'SSC', 'SSLC', 'MATRIC'];
    const marksheetStructKeywords = ['ROLL NO', 'ROLL NUMBER', 'SEAT NO', 'SEAT NUMBER', 'REGD NO', 'REGISTRATION'];
    const marksheetContentKeywords = ['MARKS OBTAINED', 'MAX MARKS', 'MAXIMUM MARKS', 'THEORY', 'PRACTICAL', 'OBTAINED', 'TOTAL', 'AGGREGATE', 'PERCENTAGE', 'GRADE', 'DIVISION', 'CGPA', 'GPA'];
    const marksheetSubjects = ['ENGLISH', 'HINDI', 'MATHEMATICS', 'MATHS', 'SCIENCE', 'SOCIAL', 'SANSKRIT', 'PHYSICS', 'CHEMISTRY', 'BIOLOGY', 'HISTORY', 'GEOGRAPHY', 'ECONOMICS', 'CIVICS', 'EVS', 'MARATHI', 'GUJARATI', 'TAMIL', 'TELUGU', 'KANNADA', 'BENGALI', 'URDU', 'PUNJABI', 'DRAWING', 'COMPUTER'];

    if (fuzzyContainsCount(text, marksheetStrongKeywords) >= 1) scores.MARKSHEET += 5;
    if (fuzzyContainsCount(text, marksheetBoardKeywords) >= 1) scores.MARKSHEET += 4;
    if (fuzzyContainsCount(text, marksheetExamKeywords) >= 1) scores.MARKSHEET += 3;
    if (fuzzyContainsCount(text, marksheetStructKeywords) >= 1) scores.MARKSHEET += 2;
    if (fuzzyContainsCount(text, marksheetContentKeywords) >= 1) scores.MARKSHEET += 2;
    const subjCount = fuzzyContainsCount(text, marksheetSubjects);
    if (subjCount >= 3) scores.MARKSHEET += 4;
    else if (subjCount >= 2) scores.MARKSHEET += 3;
    else if (subjCount >= 1) scores.MARKSHEET += 1;
    if (/\b\d{1,3}\s*\/\s*\d{2,3}\b/.test(text)) scores.MARKSHEET += 1;
    // Penalize if bank terms also present (avoid confusion)
    if (fuzzyContains(text, 'BANK') || fuzzyContains(text, 'PASSBOOK')) scores.MARKSHEET -= 2;

    // ---- Bank Passbook signals (very broad) ----
    if (fuzzyContains(text, 'PASSBOOK') || fuzzyContains(text, 'PASS BOOK')) scores.BANK_PASSBOOK += 5;
    if (fuzzyContains(text, 'SAVINGS ACCOUNT') || fuzzyContains(text, 'SAVING ACCOUNT')) scores.BANK_PASSBOOK += 4;
    if (fuzzyContains(text, 'CURRENT ACCOUNT')) scores.BANK_PASSBOOK += 4;
    if (fuzzyContains(text, 'ACCOUNT HOLDER') || fuzzyContains(text, 'A/C HOLDER')) scores.BANK_PASSBOOK += 3;
    if (fuzzyContains(text, 'ACCOUNT NO') || fuzzyContains(text, 'ACCOUNT NUMBER') || fuzzyContains(text, 'A/C NO')) scores.BANK_PASSBOOK += 3;
    if (fuzzyContains(text, 'IFSC') || fuzzyContains(text, 'MICR')) scores.BANK_PASSBOOK += 3;
    if (/\b[A-Z]{4}0[A-Z0-9]{6}\b/.test(text)) scores.BANK_PASSBOOK += 3;
    if (fuzzyContains(text, 'BRANCH')) scores.BANK_PASSBOOK += 1;
    if (fuzzyContains(text, 'CUSTOMER ID') || fuzzyContains(text, 'CIF')) scores.BANK_PASSBOOK += 2;
    
    const bankNames = [
        'STATE BANK', 'SBI', 'HDFC', 'ICICI', 'AXIS', 'PNB', 'KOTAK',
        'BANK OF INDIA', 'BANK OF BARODA', 'CANARA', 'UNION BANK',
        'YES BANK', 'IDBI', 'INDIAN BANK', 'BOI', 'BOB', 'IOB',
        'FEDERAL', 'BANDHAN', 'GRAMIN', 'GRAMEEN', 'COOPERATIVE',
        'CENTRAL BANK', 'UCO', 'SYNDICATE', 'KARNATAKA BANK'
    ];
    const bankNameCount = fuzzyContainsCount(text, bankNames);
    if (bankNameCount >= 1) scores.BANK_PASSBOOK += 3;
    
    const transKeywords = ['DEPOSIT', 'WITHDRAWAL', 'BALANCE', 'CREDIT', 'DEBIT', 'NEFT', 'RTGS', 'IMPS', 'UPI', 'CHEQUE', 'TRANSFER'];
    if (fuzzyContainsCount(text, transKeywords) >= 1) scores.BANK_PASSBOOK += 2;
    
    // Penalize if marksheet terms also present
    if (fuzzyContainsCount(text, marksheetSubjects) >= 2) scores.BANK_PASSBOOK -= 2;

    // Find the highest-scoring category
    let maxScore = 0;
    let detected = 'UNKNOWN';
    for (const [cat, score] of Object.entries(scores)) {
        if (score > maxScore) {
            maxScore = score;
            detected = cat;
        }
    }

    logger.info(`[ExtractionTool] Category Scores: ${JSON.stringify(scores)}, Winner: ${detected} (score ${maxScore})`);

    // Lower threshold to 2 for better OCR tolerance
    return maxScore >= 2 ? detected : 'UNKNOWN';
}

// ================================================================
// VOTER ID SPECIFIC EXTRACTION
// ================================================================
function extractVoterIDFields(text, info) {
    const epicMatch = text.match(/\b[A-Z]{3}\d{7}\b/);
    const epicNoisyMatch = !epicMatch ? text.match(/\b[A-Z]\s*[A-Z]\s*[A-Z]\s*\d\s*\d\s*\d\s*\d\s*\d\s*\d\s*\d\b/) : null;
    if (epicMatch) info.additionalFields.epicNumber = epicMatch[0];
    else if (epicNoisyMatch) info.additionalFields.epicNumber = epicNoisyMatch[0].replace(/\s/g, '');

    const fatherRegex = /(?:FATHER(?:'?S)?\s*NAME|S\/O|D\/O|W\/O|HUSBAND(?:'?S)?\s*NAME)[\s:]+([A-Z][A-Z\s\.]{2,40})/;
    const fatherMatch = text.match(fatherRegex);
    if (fatherMatch) info.additionalFields.fatherOrRelationName = fatherMatch[1].trim();

    const ageRegex = /(?:AGE|AGE AS ON)[\s:]*(\d{1,3})/;
    const ageMatch = text.match(ageRegex);
    if (ageMatch) info.additionalFields.age = ageMatch[1];

    const addressRegex = /(?:ADDRESS|ADDR)[\s:]+(.+)/;
    const addrMatch = text.match(addressRegex);
    if (addrMatch) info.additionalFields.address = addrMatch[1].trim();

    const partRegex = /(?:PART\s*(?:NO|NUMBER)?\.?)[\s:]*(\d+)/;
    const partMatch = text.match(partRegex);
    if (partMatch) info.additionalFields.partNumber = partMatch[1];
}

// ================================================================
// 10TH MARKSHEET SPECIFIC EXTRACTION
// ================================================================
function extractMarksheetFields(text, info) {
    // Roll Number (flexible)
    const rollRegex = /(?:ROLL|SEAT|REGD|REGISTRATION)\s*(?:NO|NUMBER|NUM)?\.?\s*[:\-]?\s*(\d{3,15})/;
    const rollMatch = text.match(rollRegex);
    if (rollMatch) info.additionalFields.rollNumber = rollMatch[1];

    // Board Name extraction
    const boardPatterns = [
        /CENTRAL BOARD OF SECONDARY EDUCATION/,
        /CBSE/,
        /INDIAN CERTIFICATE OF SECONDARY EDUCATION/,
        /ICSE/,
        /COUNCIL FOR THE INDIAN SCHOOL CERTIFICATE/,
        /CISCE/,
        /BOARD OF SECONDARY EDUCATION[\s,]*[A-Z]*/,
        /MAHARASHTRA STATE BOARD/,
        /UP BOARD|UTTAR PRADESH BOARD/,
        /BIHAR SCHOOL EXAMINATION BOARD/,
        /MADHYA PRADESH BOARD/,
        /RAJASTHAN BOARD/,
        /BOARD OF SCHOOL EDUCATION/,
        /WEST BENGAL BOARD/,
        /TAMIL NADU BOARD/,
        /KARNATAKA BOARD/,
        /ANDHRA PRADESH BOARD/,
        /TELANGANA BOARD/,
        /KERALA BOARD/,
        /GUJARAT BOARD/,
        /PUNJAB BOARD/,
        /HARYANA BOARD/,
        /JAK BOARD|JAMMU/,
        /ASSAM BOARD/,
        /ODISHA BOARD|ORISSA BOARD/,
        /JHARKHAND BOARD/,
        /UTTARAKHAND BOARD/,
        /GOA BOARD/,
        /MANIPUR BOARD/,
        /MEGHALAYA BOARD/,
        /MIZORAM BOARD/,
        /NAGALAND BOARD/,
        /TRIPURA BOARD/,
        /CHHATTISGARH BOARD/,
        /NIOS/, /NATIONAL INSTITUTE OF OPEN/
    ];
    for (const bp of boardPatterns) {
        const m = text.match(bp);
        if (m) {
            info.additionalFields.boardName = m[0].trim();
            break;
        }
    }

    // Extract subjects and marks
    const subjects = [];
    const subjectNames = [
        'ENGLISH', 'HINDI', 'MATHEMATICS', 'MATHS', 'MATH',
        'SCIENCE', 'SOCIAL SCIENCE', 'SOCIAL STUDIES', 'SOCIAL',
        'SANSKRIT', 'COMPUTER', 'COMPUTER SCIENCE', 'IT',
        'PHYSICS', 'CHEMISTRY', 'BIOLOGY',
        'HISTORY', 'GEOGRAPHY', 'ECONOMICS', 'CIVICS',
        'HOME SCIENCE', 'PHYSICAL EDUCATION', 'ART', 'DRAWING',
        'INFORMATION TECHNOLOGY', 'INFORMATION PRACTICES',
        'EVS', 'ENVIRONMENTAL', 'GENERAL KNOWLEDGE',
        'MARATHI', 'GUJARATI', 'TAMIL', 'TELUGU', 'KANNADA',
        'BENGALI', 'URDU', 'PUNJABI', 'MALAYALAM', 'ODIA'
    ];

    const lines = text.split('\n');
    for (const line of lines) {
        for (const subjectName of subjectNames) {
            if (fuzzyContains(line, subjectName)) {
                const marksMatch = line.match(/(\d{1,3})\s*(?:[\/]\s*(\d{2,3}))?/);
                if (marksMatch) {
                    const entry = { subject: subjectName, marksObtained: marksMatch[1] };
                    if (marksMatch[2]) entry.maxMarks = marksMatch[2];
                    subjects.push(entry);
                } else {
                    subjects.push({ subject: subjectName, marksObtained: 'N/A' });
                }
                break;
            }
        }
    }
    if (subjects.length > 0) info.additionalFields.subjects = subjects;

    // Total / Aggregate
    const totalRegex = /(?:TOTAL|AGGREGATE|GRAND TOTAL)[\s:]*(\d{1,4})\s*(?:[\/]\s*(\d{3,4}))?/;
    const totalMatch = text.match(totalRegex);
    if (totalMatch) {
        info.additionalFields.totalMarks = totalMatch[1];
        if (totalMatch[2]) info.additionalFields.maxTotalMarks = totalMatch[2];
    }

    // Percentage
    const percentRegex = /(\d{1,3}\.?\d{0,2})\s*%/;
    const percentMatch = text.match(percentRegex);
    if (percentMatch) info.additionalFields.percentage = percentMatch[1];

    // Grade / Division
    const gradeRegex = /(?:GRADE|DIVISION|RESULT)[\s:]*([A-Z][A-Z\+\-\s]*(?:DIVISION|DISTINCTION)?)/;
    const gradeMatch = text.match(gradeRegex);
    if (gradeMatch) info.additionalFields.grade = gradeMatch[1].trim();

    // Exam Year
    const yearRegex = /(?:YEAR|SESSION|EXAM(?:INATION)?\s*(?:YEAR)?)\s*[:\-]?\s*(\d{4})/;
    const yearMatch = text.match(yearRegex);
    if (yearMatch) info.additionalFields.examYear = yearMatch[1];

    // School / Institution Name
    const schoolRegex = /(?:SCHOOL|INSTITUTION|CENTRE|CENTER)[\s:]+([A-Z][A-Z\s\.,]{3,50})/;
    const schoolMatch = text.match(schoolRegex);
    if (schoolMatch) info.additionalFields.schoolName = schoolMatch[1].trim();

    // Candidate Name
    const candRegex = /(?:NAME\s*(?:OF\s*)?(?:CANDIDATE|STUDENT)|CANDIDATE(?:'?S)?\s*NAME|STUDENT(?:'?S)?\s*NAME)[\s:]+([A-Z][A-Z\s\.]{2,40})/;
    const candMatch = text.match(candRegex);
    if (candMatch) info.name = candMatch[1].trim();

    // Father's Name
    const fatherRegex = /(?:FATHER(?:'?S)?\s*NAME|S\/O|SON\s*OF|DAUGHTER\s*OF)[\s:]+([A-Z][A-Z\s\.]{2,40})/;
    const fatherMatch = text.match(fatherRegex);
    if (fatherMatch) info.additionalFields.fatherName = fatherMatch[1].trim();

    // Mother's Name
    const motherRegex = /(?:MOTHER(?:'?S)?\s*NAME)[\s:]+([A-Z][A-Z\s\.]{2,40})/;
    const motherMatch = text.match(motherRegex);
    if (motherMatch) info.additionalFields.motherName = motherMatch[1].trim();
}

// ================================================================
// BANK PASSBOOK SPECIFIC EXTRACTION
// ================================================================
function extractBankPassbookFields(text, info) {
    // Bank Name — extensive list
    const bankNames = [
        'STATE BANK OF INDIA', 'SBI', 'PUNJAB NATIONAL BANK', 'PNB',
        'BANK OF INDIA', 'BANK OF BARODA', 'CANARA BANK', 'UNION BANK OF INDIA',
        'HDFC BANK', 'ICICI BANK', 'AXIS BANK', 'KOTAK MAHINDRA BANK',
        'YES BANK', 'IDBI BANK', 'INDIAN BANK', 'CENTRAL BANK OF INDIA',
        'UCO BANK', 'SYNDICATE BANK', 'BANK OF MAHARASHTRA',
        'ORIENTAL BANK OF COMMERCE', 'CORPORATION BANK', 'DENA BANK',
        'ALLAHABAD BANK', 'ANDHRA BANK', 'VIJAYA BANK', 'INDIAN OVERSEAS BANK',
        'FEDERAL BANK', 'SOUTH INDIAN BANK', 'KARUR VYSYA BANK',
        'CITY UNION BANK', 'TAMILNAD MERCANTILE BANK', 'KARNATAKA BANK',
        'LAKSHMI VILAS BANK', 'DCB BANK', 'RBL BANK',
        'BANDHAN BANK', 'EQUITAS', 'AU SMALL FINANCE BANK',
        'UJJIVAN', 'FINO PAYMENTS BANK', 'PAYTM PAYMENTS BANK'
    ];
    for (const bn of bankNames) {
        if (fuzzyContains(text, bn)) {
            info.additionalFields.bankName = bn;
            break;
        }
    }

    // Account Number
    const accPatterns = [
        /(?:ACCOUNT|A\/C|ACC)\s*(?:NO|NUMBER|NUM)?\.?\s*[:\-]?\s*(\d{9,18})/,
        /(?:A\/C\s*NO|ACCT)\s*[:\-]?\s*(\d{9,18})/
    ];
    for (const pat of accPatterns) {
        const m = text.match(pat);
        if (m) {
            info.additionalFields.accountNumber = m[1];
            break;
        }
    }

    // IFSC Code
    const ifscPatterns = [
        /(?:IFSC|IFS\s*CODE)[\s:]*([A-Z]{4}0[A-Z0-9]{6})/,
        /\b([A-Z]{4}0[A-Z0-9]{6})\b/
    ];
    for (const pat of ifscPatterns) {
        const m = text.match(pat);
        if (m) {
            info.additionalFields.ifscCode = m[1];
            break;
        }
    }

    // Branch Name
    const branchRegex = /(?:BRANCH)[\s:]+([A-Z][A-Z\s\.,]{2,40})/;
    const branchMatch = text.match(branchRegex);
    if (branchMatch) info.additionalFields.branchName = branchMatch[1].trim();

    // Customer ID / CIF
    const cifPatterns = [
        /(?:CIF|CUSTOMER\s*ID|CUSTOMER\s*NO|CUST\s*ID)[\s:]*(\d{5,15})/,
        /(?:CIF)\s*[:\-]?\s*(\d{5,15})/
    ];
    for (const pat of cifPatterns) {
        const m = text.match(pat);
        if (m) {
            info.additionalFields.customerId = m[1];
            break;
        }
    }

    // Account Type
    if (fuzzyContains(text, 'SAVINGS') || fuzzyContains(text, 'SAVING')) {
        info.additionalFields.accountType = 'Savings';
    } else if (fuzzyContains(text, 'CURRENT')) {
        info.additionalFields.accountType = 'Current';
    } else if (fuzzyContains(text, 'FIXED DEPOSIT') || fuzzyContains(text, 'FD')) {
        info.additionalFields.accountType = 'Fixed Deposit';
    }

    // Account Holder Name
    const holderPatterns = [
        /(?:ACCOUNT\s*HOLDER|A\/C\s*HOLDER|HOLDER(?:'?S)?\s*NAME|NAME\s*OF\s*(?:ACCOUNT\s*)?HOLDER|DEPOSITOR)[\s:]+([A-Z][A-Z\s\.]{2,40})/,
        /(?:NAME)\s*[:\-]\s*([A-Z][A-Z\s\.]{2,40})/
    ];
    for (const pat of holderPatterns) {
        const m = text.match(pat);
        if (m) {
            // Make sure it's not a noise match
            const cleaned = m[1].trim();
            if (cleaned.length > 2 && !/^(OF|THE|AND|FOR|BANK|BRANCH)/.test(cleaned)) {
                info.name = cleaned;
                break;
            }
        }
    }

    // Joint Account Holder
    const jointRegex = /(?:JOINT\s*HOLDER|SECOND\s*HOLDER)[\s:]+([A-Z][A-Z\s\.]{2,40})/;
    const jointMatch = text.match(jointRegex);
    if (jointMatch) info.additionalFields.jointHolder = jointMatch[1].trim();

    // Nominee
    const nomineeRegex = /(?:NOMINEE)[\s:]+([A-Z][A-Z\s\.]{2,40})/;
    const nomineeMatch = text.match(nomineeRegex);
    if (nomineeMatch) info.additionalFields.nominee = nomineeMatch[1].trim();

    // Opening Date
    const openDateRegex = /(?:OPENING\s*DATE|DATE\s*OF\s*OPENING|OPENED\s*ON|DATE\s*OF\s*OPEN)[\s:]*(\d{2}[\/\-\.]\d{2}[\/\-\.]\d{4})/;
    const openMatch = text.match(openDateRegex);
    if (openMatch) info.additionalFields.accountOpeningDate = openMatch[1];

    // MICR Code
    const micrRegex = /(?:MICR)[\s:]*(\d{9})/;
    const micrMatch = text.match(micrRegex);
    if (micrMatch) info.additionalFields.micrCode = micrMatch[1];

    // Address
    const addrRegex = /(?:ADDRESS)[\s:]+(.+)/;
    const addrMatch = text.match(addrRegex);
    if (addrMatch) info.additionalFields.address = addrMatch[1].trim();
}

module.exports = { extractData };
