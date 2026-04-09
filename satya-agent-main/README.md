# Satya Agent — Smart Document Detective 🕵️‍♂️

A production-grade, multi-node automated document verification backend. The system orchestrates a deterministic 4-node pipeline — OCR preprocessing, programmatic data extraction, cryptographic validation, and visual forensics — to detect forged or tampered Indian identity documents without relying on any LLM API.

---

## 📁 Project Structure

```
satya-agent-main/
├── app.js                    # Express server entry point, CORS config, routes
├── routes/
│   └── documentRoutes.js     # POST /api/detect — Multer upload handler
├── controllers/
│   └── documentController.js # Request handler → calls agent.analyzeMultiple()
├── agent/
│   └── documentAgent.js      # 🧠 Orchestrator — runs all 4 nodes + mismatch detection
├── services/
│   ├── ocrService.js         # Node 1a — Tesseract OCR with Jimp preprocessing
│   ├── imageService.js       # Node 1b — Laplacian/Sobel forensic image analysis
│   ├── extractionTool.js     # Node 2  — Regex + spatial name/DOB/ID extraction
│   └── validationService.js  # Node 3  — Format, keyword, Verhoeff checksum validation
├── utils/
│   └── logger.js             # Morgan + Winston logger setup
├── config/
│   └── ngrok.js              # Optional ngrok tunnel for public URL exposure
├── uploads/                  # Temporary uploaded files (auto-cleaned on Vercel/tmpdir)
├── eng.traineddata           # Bundled Tesseract English language model
├── .env                      # Environment variables (PORT, NGROK_AUTHTOKEN)
└── package.json
```

---

## 🚀 Quick Start

```bash
# 1. Install dependencies
cd satya-agent-main
npm install

# 2. Configure environment
cp .env.example .env         # Set PORT and NGROK_AUTHTOKEN

# 3. Start development server (with auto-reload)
npm run dev                  # nodemon app.js → http://localhost:5000

# 4. Start production server
npm start                    # node app.js
```

---

## 🌐 API Endpoints

### `POST /api/detect` — Verify Documents

Upload 1–5 document images. The pipeline runs OCR, data extraction, format validation, and forensics on each file.

| Property | Value |
|---|---|
| **URL** | `http://localhost:5000/api/detect` |
| **Method** | `POST` |
| **Content-Type** | `multipart/form-data` |
| **Field name** | `documents` (array, max 5 files) |
| **Accepted types** | JPG, PNG, WEBP |
| **Max file size** | 10 MB per file |

**Example (cURL):**
```bash
curl -X POST http://localhost:5000/api/detect \
  -F "documents=@aadhaar.jpg"
```

**Single Document Response:**
```json
{
  "agent": "SatyaSatya V2.0",
  "documentType": "Aadhaar",
  "validation": {
    "isValidFormat": true,
    "keywordsFound": true,
    "isMathematicallyFake": false,
    "extraValidation": {}
  },
  "extractedInfo": {
    "name": "JOHN DOE",
    "dob": "01/01/1990",
    "gender": "MALE",
    "idNumber": "123456789012",
    "documentCategory": "AADHAAR",
    "additionalFields": {}
  },
  "ocrText": "Government of India...",
  "forensicsAnalysis": {
    "isBlurred": false,
    "possibleTampering": false,
    "isScreenshot": false
  },
  "aiAgentDecision": {
    "fraudProbability": 0,
    "explanation": "Document seamlessly validated cryptographically and visually."
  },
  "publicUrl": "ngrok not active"
}
```

**Multi-Document Response (2–5 files):**
```json
{
  "agent": "SatyaSatya V2.0",
  "mismatchAnalysis": {
    "documentsAnalyzed": 2,
    "mismatchDetected": false,
    "mismatchDetails": []
  },
  "documents": [ /* array of single-doc results */ ]
}
```

**Error Responses:**

| Status | Scenario | Response |
|---|---|---|
| `400` | No file uploaded | `{ "error": "Missing documents. Please upload 1 or more images." }` |
| `500` | OCR/processing error | `{ "error": "Internal server error during document processing.", "details": "..." }` |

---

### `GET /health` — Health Check

Used by the frontend to check if the backend is live.

```bash
curl http://localhost:5000/health
# → { "status": "running", "message": "Smart Document Detective API is live!" }
```

### `GET /` — Root

Same as `/health`. Used by Render's health check probe.

---

## 🧠 4-Node Pipeline Architecture

All analysis is orchestrated by `agent/documentAgent.js` (`DocumentAgentOrchestrator`).

```
Uploaded Image
    │
    ▼
┌─────────────────────────────────────────────────────────┐
│  NODE 1 — Perception & Forensics (runs in parallel)     │
│  ├── ocrService.js     → Jimp preprocess + Tesseract OCR│
│  └── imageService.js   → Laplacian + Sobel forensics    │
└────────────────────────┬────────────────────────────────┘
                         │ ocrText + imageAnalysis
                         ▼
┌─────────────────────────────────────────────────────────┐
│  NODE 2 — Data Extraction (extractionTool.js)           │
│  → detectCategory() — scores each document type         │
│  → Regex extraction: ID, DOB, Gender                    │
│  → Spatial name extraction (line-above DOB/Gender)      │
│  → Category-specific: EPIC#, account#, roll#, subjects  │
└────────────────────────┬────────────────────────────────┘
                         │ extractedData
                         ▼
┌─────────────────────────────────────────────────────────┐
│  NODE 3 — Cryptographic Validation (validationService)  │
│  → Scoring system selects best-matching document type   │
│  → Aadhaar: Verhoeff checksum on 12-digit number        │
│  → PAN: 5-letter + 4-digit + 1-letter regex             │
│  → Voter ID: EPIC regex + Election Commission keywords   │
│  → Marksheet: Board + subject + marks pattern scoring   │
│  → Bank Passbook: IFSC + account# + transaction keywords│
└────────────────────────┬────────────────────────────────┘
                         │ validation result
                         ▼
┌─────────────────────────────────────────────────────────┐
│  NODE 4 — Fraud Heuristics (documentAgent.js)           │
│  → Tallies rule penalties into fraudProbability (0-100) │
│  → Returns final aiAgentDecision                        │
└─────────────────────────────────────────────────────────┘
```

If **multiple documents** are uploaded, a **Mismatch Detection** node runs after all documents are processed, comparing names (using `string-similarity` / BERT-lite lexical matching) and DOBs across documents.

---

## 🔬 Node 1a — OCR Service (`services/ocrService.js`)

**Methods used:** `Jimp.read()`, `.greyscale()`, `.contrast(0.5)`, `.normalize()`, `.write()`, `Tesseract.createWorker()`, `worker.recognize()`

**Flow:**
1. Reads image with **Jimp**
2. Applies **grayscale → +50% contrast → normalize** for better OCR accuracy
3. Saves optimized temp image alongside original
4. Runs **Tesseract.js** with bundled `eng.traineddata` (no internet needed)
5. Uses `Promise.race()` with a **20-second timeout** to prevent hanging
6. Terminates worker and cleans up temp image in `finally` block
7. Returns cleaned OCR text (collapses blank lines)

**Key config:**
```js
Tesseract.createWorker('eng', 1, {
    langPath: path.join(__dirname, '..'), // uses bundled eng.traineddata
    cachePath: os.tmpdir(),
    cacheMethod: 'write'
})
```

---

## 🔬 Node 1b — Image Forensics (`services/imageService.js`)

**Methods used:** `Jimp.read()`, `.resize()`, `.greyscale()`, pixel-level Laplacian + Sobel convolution

**How it works:**

1. Resizes image to **300px width** for speed
2. Converts to grayscale
3. Performs **pixel-level spatial convolution** on every pixel:
   - **Laplacian filter** — `4×center - top - bottom - left - right` — measures sharpness variance
   - **Sobel gradient** — `√(gx² + gy²)` — counts edge pixels
4. Derives three forensic flags:

| Flag | Condition | Meaning |
|---|---|---|
| `isBlurred` | Laplacian variance `< 80` | Image is too blurry — low-quality capture |
| `isScreenshot` | Laplacian variance `> 4500` | Unnaturally sharp — digital template or web screenshot |
| `possibleTampering` | Edge density `< 0.02` or `> 0.45` | Too smooth (synthetic clone) or over-detailed (spliced) |

---

## 🔬 Node 2 — Data Extraction (`services/extractionTool.js`)

**Main function:** `extractData(ocrText)`

### Step 1 — Category Detection (`detectCategory`)
Uses a **scoring system** (not a rigid priority chain) to pick the most likely document type:

| Category | Key Signals |
|---|---|
| `AADHAAR` | "AADHAAR", "UIDAI", "UNIQUE IDENTIFICATION", 12-digit number |
| `PAN` | "PERMANENT ACCOUNT NUMBER", "INCOME TAX", 10-char PAN pattern |
| `VOTER_ID` | "ELECTION COMMISSION", "NIRVACHAN", "ELECTORAL", EPIC regex |
| `MARKSHEET` | Board name, subject names, roll number, marks patterns |
| `BANK_PASSBOOK` | "PASSBOOK", IFSC code, account number, transaction keywords |

### Step 2 — ID Number Extraction
```
AADHAAR  → /\b(\d{4})[\s\-]*(\d{4})[\s\-]*(\d{4})\b/
PAN      → /\b[A-Z]{5}[0-9O]{4}[A-Z]\b/    (O/0 OCR tolerance)
VOTER_ID → /\b[A-Z]{3}\d{7}\b/              (+ noisy variant with spaces)
PASSBOOK → account number from "ACCOUNT NO:" patterns
MARKSHEET→ roll number from "ROLL NO:" patterns
```

### Step 3 — DOB Extraction
Primary: labeled DOB regex covering `DOB`, `DATE OF BIRTH`, `D.O.B`, `YOB`, `BORN ON`  
Fallback: any `DD/MM/YYYY`, `DD-MM-YYYY`, `DD.MM.YYYY` pattern

### Step 4 — Gender Extraction
```js
/\b(MALE|FEMALE|TRANSGENDER)\b/
```

### Step 5 — Name Extraction (Spatial Algorithm)
Primary: scans lines for DOB/Gender markers → name is typically 1–2 lines **above** that line  
Fallback 1: labeled patterns — `NAME OF CANDIDATE:`, `ACCOUNT HOLDER:`, etc.  
Fallback 2: last-resort scan for any line of 2–4 all-caps words with 3+ letters each

### Step 6 — Category-Specific Extraction
| Category | Additional Fields Extracted |
|---|---|
| `VOTER_ID` | EPIC number, father/relation name, age, address, part number |
| `MARKSHEET` | Roll number, board name, per-subject marks, total, percentage, grade, exam year, school name, father's name, mother's name |
| `BANK_PASSBOOK` | Bank name, account number, IFSC code, branch name, customer ID, account type, joint holder, nominee, opening date, MICR code, address |

---

## 🔬 Node 3 — Validation (`services/validationService.js`)

**Main function:** `validateDocument(ocrText)`

### OCR Preprocessing (`preprocessOCR`)
Before any matching:
- Converts text to UPPERCASE
- Replaces `|` → `I` (common OCR substitution)
- Collapses multiple spaces/tabs to single space
- Normalizes line endings

### Fuzzy Keyword Matching (`fuzzyContains`)
Handles OCR noise where words have random spaces (e.g. `B A N K`):
```js
// "BANK" → regex /B\s*A\s*N\s*K/ — matches "BANK", "B A N K", "BA NK"
```

### Scoring System
Each document type gets a confidence score. The highest scorer wins:

| Document | Score Sources |
|---|---|
| Aadhaar | 12-digit match (+5 if Verhoeff passes, +3 if fails), "AADHAAR"/ "UIDAI" keywords |
| PAN | 10-char PAN regex, "INCOME TAX DEPARTMENT" keywords |
| Voter ID | EPIC regex, "ELECTION COMMISSION" / "NIRVACHAN" keywords |
| Marksheet | Board keywords, subject names, roll number, marks patterns |
| Bank Passbook | "PASSBOOK", IFSC regex, account number, transaction keywords |

### Aadhaar Verhoeff Checksum
The 12th digit of every Aadhaar number is a **cryptographic checksum** over the dihedral group D₅. A structurally valid number that fails this check is **mathematically proven fake**.

```js
function validateVerhoeff(numStr) {
    let c = 0;
    const reversed = numStr.split('').map(Number).reverse();
    for (let i = 0; i < reversed.length; i++) {
        c = d[c][p[i % 8][reversed[i]]];  // d = multiplication table, p = permutation table
    }
    return c === 0;   // Must resolve to exactly 0
}
```

### Document-Specific Validation Rules

**Voter ID (EPIC):**
- Regex: `/\b[A-Z]{3}\d{7}\b/` (3 letters + 7 digits)
- OCR-noise variant: allows spaces between characters
- Keywords: Election Commission, Electoral, NIRVACHAN, EPIC

**10th Marksheet:**
- Relaxed multi-signal detection (requires combination, not all)
- Checks: board keywords, subject names (CBSE/ICSE/State), roll number, marks pattern, percentage

**Bank Passbook:**
- IFSC format: `/\b[A-Z]{4}0[A-Z0-9]{6}\b/`
- Account number: 9–18 digits
- CIF / Customer ID extraction
- Transaction keywords: DEPOSIT, WITHDRAWAL, NEFT, RTGS, IMPS, UPI

---

## 🚨 Node 4 — Fraud Heuristics Scoring

All boolean signals from Nodes 1–3 are tallied into a `fraudProbability` (0–100%). Higher = more suspicious.

| Trigger | Penalty | Description |
|---|---|---|
| Verhoeff Checksum Failed | **+100** | Aadhaar number is mathematically fake |
| Digital Screenshot Detected | **+60** | Laplacian variance > 4500 — web/app template |
| Invalid Format / No Keywords | **+40** | Document doesn't match any known type |
| Edge/Texture Tampering | **+40** | Abnormal edge density — possible splicing |
| Voter ID: No EPIC Number | **+30** | Voter ID without valid EPIC serial |
| Marksheet: No Subjects | **+25** | Marksheet with no detectable subject names |
| Marksheet: Roll Number Missing | **+20** | Marksheet without roll/seat number |
| Voter ID: No EC Keywords | **+20** | Missing Election Commission markers |
| Significant Blur | **+20** | Laplacian variance < 80 — poor quality scan |
| Bank: No Account Number | **+30** | Passbook with no account number |
| Bank: No IFSC Code | **+20** | Passbook with no IFSC |
| Marksheet: No Marks Pattern | **+15** | No numerical marks/percentage detected |
| Bank: No Transactions | **+10** | Front page only — no transaction entries |
| WhatsApp Transit Artifact | **+10** | Filename contains "WhatsApp" |

Final score is capped at 100. Score of `0` = **Authentic / 0% Fraud Risk**.

---

## 🔗 Multi-Document Mismatch Detection

When 2+ documents are uploaded, after all individual analyses, the orchestrator runs NLP cross-verification:

| Check | Method | Threshold |
|---|---|---|
| **Name Match** | `string-similarity.compareTwoStrings()` (Dice coefficient) | Fail if similarity < 70% |
| **DOB Match** | Strict string equality | Fail if DOBs differ |
| **Duplicate ID on different doc types** | String equality + doc type mismatch | Flags cloning attempt |

---

## 📦 Dependencies

| Package | Version | Purpose |
|---|---|---|
| `express` | ^4.19.2 | HTTP server framework |
| `multer` | ^1.4.5-lts.1 | Multipart file upload handling |
| `cors` | ^2.8.5 | Cross-origin request headers |
| `dotenv` | ^16.4.5 | `.env` file loading |
| `tesseract.js` | ^5.0.5 | Pure-JS OCR engine (Tesseract 5) |
| `jimp` | ^1.6.0 | Pure-JS image manipulation for preprocessing and forensics |
| `string-similarity` | ^4.0.4 | Dice-coefficient BERT-lite name comparison |
| `morgan` | ^1.10.0 | HTTP request logging |
| `chalk` | ^4.1.2 | Terminal color output |
| `nodemon` | ^3.1.14 | Dev server auto-reload |
| `@ngrok/ngrok` | ^1.7.0 | Optional public tunnel |
| `axios` | ^1.6.8 | HTTP client (available for future use) |

---

## ⚙️ Environment Variables

| Variable | Default | Purpose |
|---|---|---|
| `PORT` | `5000` | Server port |
| `NGROK_AUTHTOKEN` | _(empty)_ | Your ngrok auth token for public URL tunneling |
| `OLLAMA_URL` | `http://localhost:11434` | Reserved for future LLaMA Node 5 integration |
| `VERCEL` | _(not set)_ | Set to `1` on Vercel — disables `app.listen()`, uses `/tmp` for uploads |

---

## 🌍 CORS Policy

The server allows requests from:
- Any `localhost` port (`http://localhost:*`)
- `https://veriscan-main.vercel.app` and `https://veriscan-admin.vercel.app`
- Any `*.vercel.app` subdomain (Vercel preview deployments)
- Any `*.onrender.com` subdomain (Render deployments)

No `Origin` header (mobile apps, Postman, cURL) is always allowed.

---

## 📜 Supported Document Types

| Document | ID Format | Key Validation |
|---|---|---|
| **Aadhaar Card** | 12 digits (4-4-4) | Verhoeff checksum, UIDAI keywords |
| **PAN Card** | 5 letters + 4 digits + 1 letter | Regex format, Income Tax keywords |
| **Voter ID (EPIC)** | 3 letters + 7 digits | EPIC regex, Election Commission keywords |
| **10th Marksheet** | Roll/Seat number | Board name, subjects, marks patterns |
| **Bank Passbook** | 9–18 digit account number | IFSC regex, passbook/savings account keywords |

---

## 🛠️ How to Add a New Document Type

1. **validationService.js** — Add a `validateXxx(text)` function with detection logic. Add a score key to the `scores` object in `validateDocument()`.
2. **extractionTool.js** — Add score signals to `detectCategory()`. Add an extraction case to `extractData()` → `switch(category)`. Create `extractXxxFields(text, info)` to populate `additionalFields`.
3. **documentAgent.js** — Add document-specific scoring rules in Node 4 (the if-blocks for penalty additions based on `validation.documentType`).
