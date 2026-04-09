# 📡 Satya Agent — API Documentation

> **Smart Document Detective API** — Verify Indian identity documents (Aadhaar, PAN, Voter ID, 10th Marksheet, Bank Passbook) with OCR-powered fraud detection, cryptographic validation, and image forensics.

---

## 📌 Table of Contents

- [Getting Started](#-getting-started)
- [Base URL](#-base-url)
- [API Endpoints](#-api-endpoints)
  - [Healthcheck](#1-healthcheck)
  - [Document Verification (Single)](#2-document-verification--single-document)
  - [Document Verification (Multi-Document Mismatch)](#3-multi-document-mismatch-detection)
- [Response Schema](#-response-schema)
- [Supported Document Types](#-supported-document-types)
- [Error Handling](#-error-handling)
- [Integration Guide — Website (JavaScript)](#-integration-guide--website-javascript)
- [Integration Guide — React / Next.js](#-integration-guide--react--nextjs)
- [Integration Guide — React Native (Mobile)](#-integration-guide--react-native-mobile)
- [Integration Guide — Flutter (Dart)](#-integration-guide--flutter-dart)
- [Integration Guide — cURL / Postman](#-integration-guide--curl--postman)
- [Fraud Score Reference](#-fraud-score-reference)

---

## 🚀 Getting Started

### 1. Install Dependencies
```bash
npm install
```

### 2. Configure Environment
Create a `.env` file in the project root:
```env
PORT=5000
NGROK_AUTHTOKEN=your_ngrok_token_here
```

### 3. Start the Server
```bash
# Production
npm start

# Development (hot-reload)
npm run dev
```

The server will start on `http://localhost:5000`. If ngrok is configured, a public tunnel URL will also be printed.

---

## 🌐 Base URL

| Environment  | URL                                |
| :----------- | :--------------------------------- |
| **Local**    | `http://localhost:5000`            |
| **ngrok**    | `https://<your-subdomain>.ngrok.io` (auto-generated) |
| **Production** | Your deployed server URL         |

> All endpoints are prefixed with `/api`.

---

## 📡 API Endpoints

---

### 1. Healthcheck

Check if the server is running.

| Property     | Value                  |
| :----------- | :--------------------- |
| **Method**   | `GET`                  |
| **URL**      | `/`                    |
| **Auth**     | None                   |
| **Body**     | None                   |

#### Request
```
GET http://localhost:5000/
```

#### Response `200 OK`
```json
{
  "status": "running",
  "message": "Smart Document Detective API is live!"
}
```

---

### 2. Document Verification — Single Document

Upload **one image** of an identity document. The API will automatically detect the document type, extract all data fields, run cryptographic validation (Aadhaar Verhoeff checksum), and perform image forensics.

| Property        | Value                              |
| :-------------- | :--------------------------------- |
| **Method**      | `POST`                             |
| **URL**         | `/api/detect`                      |
| **Content-Type**| `multipart/form-data`              |
| **Auth**        | None                               |
| **Max Files**   | 5                                  |

#### Request Parameters

| Field        | Type     | Required | Description                                    |
| :----------- | :------- | :------- | :--------------------------------------------- |
| `documents`  | `File`   | ✅ Yes   | Image file (JPEG, PNG, WebP, BMP, TIFF)        |

> ⚠️ The form field name **must** be `documents` (not `file`, `image`, etc.)

#### Request Example (cURL)
```bash
curl -X POST http://localhost:5000/api/detect \
  -F "documents=@/path/to/aadhaar_card.jpg"
```

#### Response `200 OK` — Single Document
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
    "name": "RAHUL KUMAR",
    "dob": "15/08/1995",
    "gender": "MALE",
    "idNumber": "234567891234",
    "documentCategory": "AADHAAR",
    "additionalFields": {}
  },
  "ocrText": "GOVERNMENT OF INDIA\nRahul Kumar\n...",
  "forensicsAnalysis": {
    "isBlurred": false,
    "possibleTampering": false,
    "isScreenshot": false
  },
  "aiAgentDecision": {
    "fraudProbability": 0,
    "explanation": "Document seamlessly validated cryptographically and visually."
  },
  "publicUrl": "https://xxxx.ngrok.io"
}
```

---

### 3. Multi-Document Mismatch Detection

Upload **2–5 images** in a single request. The API verifies each document individually **and** performs cross-document NLP mismatch detection (name similarity + DOB matching) to detect if the documents belong to the same person.

| Property        | Value                              |
| :-------------- | :--------------------------------- |
| **Method**      | `POST`                             |
| **URL**         | `/api/detect`                      |
| **Content-Type**| `multipart/form-data`              |
| **Auth**        | None                               |
| **Max Files**   | 5                                  |

#### Request Example (cURL)
```bash
curl -X POST http://localhost:5000/api/detect \
  -F "documents=@/path/to/aadhaar_front.jpg" \
  -F "documents=@/path/to/pan_card.jpg"
```

#### Response `200 OK` — Multi-Document
```json
{
  "agent": "SatyaSatya V2.0",
  "mismatchAnalysis": {
    "documentsAnalyzed": 2,
    "mismatchDetected": false,
    "mismatchDetails": []
  },
  "documents": [
    {
      "documentType": "Aadhaar",
      "validation": { "..." : "..." },
      "extractedInfo": { "..." : "..." },
      "ocrText": "...",
      "forensicsAnalysis": { "..." : "..." },
      "aiAgentDecision": {
        "fraudProbability": 0,
        "explanation": "Document seamlessly validated cryptographically and visually."
      }
    },
    {
      "documentType": "PAN",
      "validation": { "..." : "..." },
      "extractedInfo": { "..." : "..." },
      "ocrText": "...",
      "forensicsAnalysis": { "..." : "..." },
      "aiAgentDecision": {
        "fraudProbability": 0,
        "explanation": "Document seamlessly validated cryptographically and visually."
      }
    }
  ]
}
```

#### Mismatch Alert Example
When names or DOBs don't match across documents:
```json
{
  "mismatchAnalysis": {
    "documentsAnalyzed": 2,
    "mismatchDetected": true,
    "mismatchDetails": [
      "Identity Name Mismatch: Confidence only 42.5%",
      "Date of Birth Conflict: 15/08/1995 vs 20/03/1998"
    ]
  }
}
```

---

## 📦 Response Schema

### Single Document Response

| Field                              | Type      | Description                                           |
| :--------------------------------- | :-------- | :---------------------------------------------------- |
| `agent`                            | `string`  | Agent version identifier                              |
| `documentType`                     | `string`  | Detected document type (see table below)              |
| `validation.isValidFormat`         | `boolean` | Whether the document passes structural checks         |
| `validation.keywordsFound`         | `boolean` | Whether expected keywords were found                  |
| `validation.isMathematicallyFake`  | `boolean` | `true` if Aadhaar Verhoeff checksum failed            |
| `validation.extraValidation`       | `object`  | Document-type-specific validation details             |
| `extractedInfo.name`               | `string`  | Extracted person name                                 |
| `extractedInfo.dob`                | `string`  | Date of birth (DD/MM/YYYY or YYYY)                    |
| `extractedInfo.gender`             | `string`  | Gender (MALE / FEMALE / TRANSGENDER)                  |
| `extractedInfo.idNumber`           | `string`  | Primary ID number (Aadhaar, PAN, EPIC, Acc No, Roll)  |
| `extractedInfo.documentCategory`   | `string`  | Category: AADHAAR, PAN, VOTER_ID, MARKSHEET, BANK_PASSBOOK |
| `extractedInfo.additionalFields`   | `object`  | Extra fields per doc type (see below)                 |
| `ocrText`                          | `string`  | Raw OCR-extracted text from the image                 |
| `forensicsAnalysis.isBlurred`      | `boolean` | Image blur detected                                  |
| `forensicsAnalysis.possibleTampering` | `boolean` | Edge/texture tampering anomaly                     |
| `forensicsAnalysis.isScreenshot`   | `boolean` | Digital screenshot/template detected                  |
| `aiAgentDecision.fraudProbability` | `number`  | Fraud risk score (0–100)                              |
| `aiAgentDecision.explanation`      | `string`  | Human-readable fraud decision                         |

### Additional Fields by Document Type

#### Aadhaar — `additionalFields`
No extra fields (core fields cover everything).

#### PAN — `additionalFields`
No extra fields.

#### Voter ID — `additionalFields`
| Field                  | Description                     |
| :--------------------- | :------------------------------ |
| `epicNumber`           | EPIC number (3 letters + 7 digits) |
| `fatherOrRelationName` | Father/Husband name             |
| `age`                  | Age as stated on card           |
| `address`              | Address if present              |
| `partNumber`           | Part number                     |

#### 10th Marksheet — `additionalFields`
| Field           | Description                           |
| :-------------- | :------------------------------------ |
| `rollNumber`    | Roll/Seat/Registration number         |
| `boardName`     | Board of education (CBSE, ICSE, etc.) |
| `subjects`      | Array of `{ subject, marksObtained, maxMarks }` |
| `totalMarks`    | Total marks obtained                  |
| `maxTotalMarks` | Maximum total marks                   |
| `percentage`    | Percentage score                      |
| `grade`         | Grade/Division                        |
| `examYear`      | Examination year                      |
| `schoolName`    | School/Institution name               |
| `fatherName`    | Father's name                         |
| `motherName`    | Mother's name                         |

#### Bank Passbook — `additionalFields`
| Field                | Description                     |
| :------------------- | :------------------------------ |
| `bankName`           | Detected bank name              |
| `accountNumber`      | Account number                  |
| `ifscCode`           | IFSC code                       |
| `branchName`         | Branch name                     |
| `customerId`         | CIF/Customer ID                 |
| `accountType`        | Savings / Current / Fixed Deposit |
| `jointHolder`        | Joint account holder (if any)   |
| `nominee`            | Nominee name                    |
| `accountOpeningDate` | Date account was opened         |
| `micrCode`           | MICR code (9 digits)            |
| `address`            | Address if present              |

---

## 📄 Supported Document Types

| Document Type     | `documentType` Value | `documentCategory` Value | ID Format Validated |
| :---------------- | :------------------- | :----------------------- | :------------------ |
| Aadhaar Card      | `"Aadhaar"`          | `"AADHAAR"`              | ✅ Verhoeff Checksum |
| PAN Card          | `"PAN"`              | `"PAN"`                  | ✅ Regex Format      |
| Voter ID (EPIC)   | `"Voter ID (EPIC)"`  | `"VOTER_ID"`             | ✅ Regex Format      |
| 10th Marksheet    | `"10th Marksheet"`   | `"MARKSHEET"`            | ✅ Content Analysis  |
| Bank Passbook     | `"Bank Passbook"`    | `"BANK_PASSBOOK"`        | ✅ IFSC + Structure  |
| Unknown           | `"Unknown"`          | `"UNKNOWN"`              | ❌ Not recognized    |

---

## ❌ Error Handling

### No File Uploaded
```json
// Status: 400 Bad Request
{
  "error": "Missing documents. Please upload 1 or more images."
}
```

### Internal Server Error
```json
// Status: 500 Internal Server Error
{
  "error": "Internal server error during document processing.",
  "details": "OCR extraction failed"
}
```

---

## 🌐 Integration Guide — Website (JavaScript)

### Using Vanilla JavaScript (Fetch API)

```html
<!-- Simple Upload Form -->
<input type="file" id="docInput" accept="image/*" multiple />
<button onclick="verifyDocuments()">Verify</button>
<pre id="result"></pre>

<script>
const API_URL = 'http://localhost:5000'; // Change to your deployed URL

async function verifyDocuments() {
  const files = document.getElementById('docInput').files;
  if (files.length === 0) return alert('Please select a document image');

  const formData = new FormData();
  for (const file of files) {
    formData.append('documents', file);
  }

  try {
    const response = await fetch(`${API_URL}/api/detect`, {
      method: 'POST',
      body: formData
      // Do NOT set Content-Type header — let the browser set it with the boundary
    });

    const data = await response.json();
    document.getElementById('result').textContent = JSON.stringify(data, null, 2);

    // Access key results
    if (data.documentType) {
      console.log('Document Type:', data.documentType);
      console.log('Fraud Risk:', data.aiAgentDecision.fraudProbability + '%');
      console.log('Name:', data.extractedInfo?.name);
      console.log('ID Number:', data.extractedInfo?.idNumber);
    }

    // Multi-doc mismatch check
    if (data.mismatchAnalysis) {
      console.log('Mismatch Detected:', data.mismatchAnalysis.mismatchDetected);
      console.log('Details:', data.mismatchAnalysis.mismatchDetails);
    }
  } catch (error) {
    console.error('Verification failed:', error);
  }
}
</script>
```

### Using Axios (CDN)

```html
<script src="https://cdn.jsdelivr.net/npm/axios/dist/axios.min.js"></script>
<script>
async function verifyWithAxios(file) {
  const formData = new FormData();
  formData.append('documents', file);

  const { data } = await axios.post('http://localhost:5000/api/detect', formData, {
    headers: { 'Content-Type': 'multipart/form-data' }
  });

  return data;
}
</script>
```

---

## ⚛️ Integration Guide — React / Next.js

### React Component

```jsx
import { useState } from 'react';

const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:5000';

export default function DocumentVerifier() {
  const [files, setFiles] = useState([]);
  const [result, setResult] = useState(null);
  const [loading, setLoading] = useState(false);

  const handleVerify = async () => {
    if (files.length === 0) return;
    setLoading(true);

    const formData = new FormData();
    files.forEach(file => formData.append('documents', file));

    try {
      const res = await fetch(`${API_URL}/api/detect`, {
        method: 'POST',
        body: formData,
      });
      const data = await res.json();
      setResult(data);
    } catch (err) {
      console.error('Verification error:', err);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div>
      <input
        type="file"
        accept="image/*"
        multiple
        onChange={(e) => setFiles([...e.target.files])}
      />
      <button onClick={handleVerify} disabled={loading}>
        {loading ? 'Verifying...' : 'Verify Documents'}
      </button>

      {result && (
        <div>
          <h3>Document Type: {result.documentType || result.documents?.[0]?.documentType}</h3>
          <p>Fraud Risk: {result.aiAgentDecision?.fraudProbability ?? result.documents?.[0]?.aiAgentDecision?.fraudProbability}%</p>
          <p>Name: {result.extractedInfo?.name ?? result.documents?.[0]?.extractedInfo?.name}</p>

          {result.mismatchAnalysis && (
            <div style={{ color: result.mismatchAnalysis.mismatchDetected ? 'red' : 'green' }}>
              <h4>Cross-Document Match: {result.mismatchAnalysis.mismatchDetected ? '❌ MISMATCH' : '✅ MATCH'}</h4>
              {result.mismatchAnalysis.mismatchDetails.map((d, i) => <p key={i}>⚠️ {d}</p>)}
            </div>
          )}
        </div>
      )}
    </div>
  );
}
```

### API Utility (reusable)
```js
// lib/satya-api.js
const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:5000';

export async function verifyDocuments(files) {
  const formData = new FormData();
  files.forEach(file => formData.append('documents', file));

  const res = await fetch(`${API_URL}/api/detect`, {
    method: 'POST',
    body: formData,
  });

  if (!res.ok) throw new Error(`HTTP ${res.status}: ${res.statusText}`);
  return res.json();
}
```

---

## 📱 Integration Guide — React Native (Mobile)

```jsx
import * as ImagePicker from 'expo-image-picker';

const API_URL = 'http://YOUR_SERVER_IP:5000'; // Use your LAN IP or ngrok URL

export async function pickAndVerifyDocument() {
  // Pick image from gallery
  const result = await ImagePicker.launchImageLibraryAsync({
    mediaTypes: ImagePicker.MediaTypeOptions.Images,
    quality: 0.8,
  });

  if (result.canceled) return null;

  const asset = result.assets[0];
  const formData = new FormData();
  formData.append('documents', {
    uri: asset.uri,
    name: 'document.jpg',
    type: 'image/jpeg',
  });

  const response = await fetch(`${API_URL}/api/detect`, {
    method: 'POST',
    body: formData,
    headers: {
      'Content-Type': 'multipart/form-data',
    },
  });

  return await response.json();
}

// For camera capture:
export async function captureAndVerify() {
  const result = await ImagePicker.launchCameraAsync({
    mediaTypes: ImagePicker.MediaTypeOptions.Images,
    quality: 0.8,
  });

  if (result.canceled) return null;

  const asset = result.assets[0];
  const formData = new FormData();
  formData.append('documents', {
    uri: asset.uri,
    name: 'document.jpg',
    type: 'image/jpeg',
  });

  const response = await fetch(`${API_URL}/api/detect`, {
    method: 'POST',
    body: formData,
    headers: { 'Content-Type': 'multipart/form-data' },
  });

  return await response.json();
}
```

> ⚠️ **React Native Note:** Use your machine's local LAN IP (e.g., `192.168.1.x`) or ngrok public URL. `localhost` won't work on a physical device.

---

## 💙 Integration Guide — Flutter (Dart)

```dart
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';

const String apiUrl = 'http://YOUR_SERVER_IP:5000';

Future<Map<String, dynamic>> verifyDocument(File imageFile) async {
  var request = http.MultipartRequest(
    'POST',
    Uri.parse('$apiUrl/api/detect'),
  );

  request.files.add(
    await http.MultipartFile.fromPath('documents', imageFile.path),
  );

  var streamedResponse = await request.send();
  var response = await http.Response.fromStream(streamedResponse);

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception('Verification failed: ${response.statusCode}');
  }
}

// Multi-document verification
Future<Map<String, dynamic>> verifyMultipleDocuments(List<File> images) async {
  var request = http.MultipartRequest(
    'POST',
    Uri.parse('$apiUrl/api/detect'),
  );

  for (var image in images) {
    request.files.add(
      await http.MultipartFile.fromPath('documents', image.path),
    );
  }

  var streamedResponse = await request.send();
  var response = await http.Response.fromStream(streamedResponse);

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception('Verification failed: ${response.statusCode}');
  }
}

// Usage with ImagePicker:
Future<void> pickAndVerify() async {
  final picker = ImagePicker();
  final XFile? image = await picker.pickImage(source: ImageSource.camera);

  if (image != null) {
    final result = await verifyDocument(File(image.path));
    print('Document Type: ${result['documentType']}');
    print('Fraud Risk: ${result['aiAgentDecision']['fraudProbability']}%');
  }
}
```

---

## 🧪 Integration Guide — cURL / Postman

### cURL — Single Document
```bash
curl -X POST http://localhost:5000/api/detect \
  -F "documents=@./my_aadhaar.jpg"
```

### cURL — Multiple Documents
```bash
curl -X POST http://localhost:5000/api/detect \
  -F "documents=@./aadhaar_front.jpg" \
  -F "documents=@./pan_card.jpg" \
  -F "documents=@./passbook.jpg"
```

### Postman Setup
1. Set method to **POST**
2. URL: `http://localhost:5000/api/detect`
3. Go to **Body** → select **form-data**
4. Add key: `documents` → Change type dropdown to **File**
5. Select your document image(s)
6. Click **Send**

> 💡 **Tip:** To upload multiple files in Postman, add multiple rows with the same key name `documents`, each with a different file.

---

## 🚨 Fraud Score Reference

The `fraudProbability` field ranges from **0** (authentic) to **100** (forged). The scoring rules:

| Trigger                                    | Points Added | Severity  |
| :----------------------------------------- | :----------- | :-------- |
| Aadhaar Verhoeff checksum failed           | `+100`       | 🔴 CRITICAL |
| Digital screenshot detected (high variance)| `+60`        | 🔴 HIGH     |
| Invalid format / no keywords               | `+40`        | 🟡 WARNING  |
| Edge/texture tampering anomaly             | `+40`        | 🟡 WARNING  |
| Voter ID: EPIC number missing              | `+30`        | 🟡 WARNING  |
| Bank Passbook: Account number missing      | `+30`        | 🟡 WARNING  |
| Marksheet: No subject names                | `+25`        | 🟡 WARNING  |
| Significant blur                           | `+20`        | 🟠 PENALTY  |
| Voter ID: No election keywords             | `+20`        | 🟠 PENALTY  |
| Marksheet: Roll number missing             | `+20`        | 🟠 PENALTY  |
| Bank Passbook: IFSC code missing           | `+20`        | 🟠 PENALTY  |
| Marksheet: No marks/percentage pattern     | `+15`        | 🟠 PENALTY  |
| Bank Passbook: No transaction keywords     | `+10`        | ⚪ INFO     |
| WhatsApp transit artifact                  | `+10`        | ⚪ INFO     |

### Interpreting the Score

| Score Range  | Interpretation              | Recommended Action              |
| :----------- | :-------------------------- | :------------------------------ |
| **0%**       | ✅ Fully Authentic          | Auto-approve                    |
| **1–20%**    | ⚠️ Low Risk                | Accept with minor flag          |
| **21–50%**   | 🟡 Medium Risk              | Manual review recommended       |
| **51–80%**   | 🔶 High Risk                | Reject / escalate               |
| **81–100%**  | 🔴 Critical / Forged        | Block immediately               |

---

## 🔑 Quick Reference

```
Base URL:   http://localhost:5000
Endpoint:   POST /api/detect
Field:      documents (multipart file)
Max Files:  5
Response:   JSON
```

---

*Generated for Satya Agent v2.0 — Smart Document Detective*
