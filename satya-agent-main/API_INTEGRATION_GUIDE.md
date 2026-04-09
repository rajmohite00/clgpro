# 🚀 Satya Agent - API Integration Guide

This guide provides simple, plug-and-play code snippets to quickly integrate the **Smart Document Detective API** into your website or mobile application.

## 📌 Available API Endpoints

### 1. Healthcheck (`GET /`)
Use this endpoint to verify if the API server is up and running.
- **URL:** `http://localhost:5000/` (or your ngrok URL)
- **Method:** `GET`
- **Response:** `{ "status": "running", "message": "Smart Document Detective API is live!" }`

### 2. Document Verification (`POST /api/detect`)
Use this endpoint to upload 1 to 5 document images. It auto-detects the document type (Aadhaar, PAN, Voter ID, Bank Passbook, 10th Marksheet), extracts data via OCR, and provides a fraud probability score and mismatch details if multiple documents are uploaded.
- **URL:** `http://localhost:5000/api/detect`
- **Method:** `POST`
- **Body:** `multipart/form-data` containing a `documents` field (file).

---

## 🌐 Website Integration (Frontend)

### Option 1: Plain HTML & Vanilla JavaScript (Fetch API)
Easily test the API using a standard HTML file.

```html
<!DOCTYPE html>
<html>
<head>
    <title>Document Verification Component</title>
</head>
<body>
    <h2>Upload Identity Document</h2>
    <input type="file" id="fileInput" accept="image/*" multiple />
    <button onclick="verifyDocuments()">Verify Document</button>
    <pre id="output" style="background: #f4f4f4; padding: 10px; margin-top: 15px; border-radius: 5px;"></pre>

    <script>
        async function verifyDocuments() {
            const files = document.getElementById('fileInput').files;
            if (files.length === 0) return alert('Please select at least one document image.');

            const formData = new FormData();
            // Append files to the "documents" field
            for (const file of files) {
                formData.append('documents', file);
            }

            document.getElementById('output').textContent = 'Processing... Please wait.';

            try {
                // Change URL to your dynamic backend URL if hosted
                const response = await fetch('http://localhost:5000/api/detect', {
                    method: 'POST',
                    body: formData // Let the browser set Content-Type to multipart/form-data
                });

                const data = await response.json();
                document.getElementById('output').textContent = JSON.stringify(data, null, 2);
            } catch (error) {
                document.getElementById('output').textContent = 'Error: ' + error.message;
            }
        }
    </script>
</body>
</html>
```

### Option 2: React.js / Next.js

```jsx
import React, { useState } from 'react';

export default function DocumentUploader() {
  const [result, setResult] = useState(null);
  const [loading, setLoading] = useState(false);

  const handleUpload = async (event) => {
    const files = event.target.files;
    if (!files.length) return;

    setLoading(true);
    const formData = new FormData();
    for (let i = 0; i < files.length; i++) {
        formData.append('documents', files[i]);
    }

    try {
      const response = await fetch('http://localhost:5000/api/detect', {
        method: 'POST',
        body: formData,
      });
      const data = await response.json();
      setResult(data);
    } catch (error) {
      console.error('Error uploading document:', error);
    } finally {
        setLoading(false);
    }
  };

  return (
    <div style={{ padding: '20px', fontFamily: 'sans-serif' }}>
      <h3>Upload Document for AI Verification</h3>
      <input type="file" multiple accept="image/*" onChange={handleUpload} />
      {loading && <p>Analyzing document...</p>}
      
      {result && (
        <div style={{ marginTop: 20, background: '#f9f9f9', padding: '15px', borderRadius: '8px' }}>
          <h4>Result Summary:</h4>
          <p><strong>Detected Type:</strong> {result.documentType || 'N/A'}</p>
          <p><strong>Fraud Risk:</strong> {result.aiAgentDecision?.fraudProbability}%</p>
          <p><strong>Extracted Name:</strong> {result.extractedInfo?.name}</p>
          <details>
             <summary style={{ cursor: 'pointer', fontWeight: 'bold' }}>View Full Response</summary>
             <pre style={{ fontSize: '12px', background: '#eef', padding: '10px' }}>
                 {JSON.stringify(result, null, 2)}
             </pre>
          </details>
        </div>
      )}
    </div>
  );
}
```

---

## 📱 Mobile App Integration

### Option 1: React Native (Expo)

```javascript
import React, { useState } from 'react';
import { View, Button, Text, ScrollView, StyleSheet } from 'react-native';
import * as ImagePicker from 'expo-image-picker';

export default function App() {
  const [result, setResult] = useState(null);

  const pickImage = async () => {
    let result = await ImagePicker.launchImageLibraryAsync({
      mediaTypes: ImagePicker.MediaTypeOptions.Images,
      allowsEditing: false,
      quality: 0.8,
    });

    if (!result.canceled) {
      uploadDocument(result.assets[0]);
    }
  };

  const uploadDocument = async (asset) => {
    const formData = new FormData();
    formData.append('documents', {
      uri: asset.uri,
      name: 'id_document.jpg',
      type: 'image/jpeg',
    });

    try {
      // NOTE: Replace YOUR_LOCAL_IP with your machine's IP (e.g., 192.168.1.5) or Ngrok URL
      const response = await fetch('http://YOUR_LOCAL_IP:5000/api/detect', {
        method: 'POST',
        body: formData,
        headers: { 'Content-Type': 'multipart/form-data' },
      });
      
      const data = await response.json();
      setResult(data);
    } catch (error) {
      console.error(error);
    }
  };

  return (
    <View style={styles.container}>
      <Button title="Select ID Document from Gallery" onPress={pickImage} />
      {result && (
        <ScrollView style={styles.resultBox}>
          <Text style={styles.bold}>Fraud Risk: {result.aiAgentDecision?.fraudProbability}%</Text>
          <Text style={styles.bold}>Doc Type: {result.documentType}</Text>
          <Text style={{ marginTop: 10 }}>{JSON.stringify(result, null, 2)}</Text>
        </ScrollView>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, justifyContent: 'center', padding: 20, paddingTop: 60 },
  resultBox: { marginTop: 20, padding: 10, backgroundColor: '#f0f0f0', borderRadius: 8 },
  bold: { fontWeight: 'bold', fontSize: 16 }
});
```

### Option 2: Flutter (Dart)

To use this, make sure to add `image_picker` and `http` to your `pubspec.yaml`.

```dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class DocumentVerificationScreen extends StatefulWidget {
  @override
  _DocumentVerificationScreenState createState() => _DocumentVerificationScreenState();
}

class _DocumentVerificationScreenState extends State<DocumentVerificationScreen> {
  String _result = 'No document selected';

  Future<void> pickAndVerifyDocument() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() { _result = 'Uploading & Analyzing...'; });

      var request = http.MultipartRequest(
        'POST',
        // NOTE: If testing on Android Emulator, use 10.0.2.2 instead of localhost
        // If testing on a physical device, use your PC's IP address (e.g. 192.168.1.5)
        Uri.parse('http://10.0.2.2:5000/api/detect')
      );
      
      request.files.add(await http.MultipartFile.fromPath('documents', image.path));

      try {
        var streamedResponse = await request.send();
        var response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          setState(() {
            _result = "Type: ${data['documentType']}\nFraud Score: ${data['aiAgentDecision']['fraudProbability']}%\nName: ${data['extractedInfo']['name']}";
          });
        } else {
          setState(() { _result = 'Error! Status Code: ${response.statusCode}'; });
        }
      } catch (e) {
        setState(() { _result = 'Network Error: $e'; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Satya Agent Integration')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: pickAndVerifyDocument,
                child: Text('Upload Document'),
              ),
              SizedBox(height: 30),
              Container(
                padding: EdgeInsets.all(16),
                color: Colors.grey[200],
                child: Text(_result, textAlign: TextAlign.center, style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```
