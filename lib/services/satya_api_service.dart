import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

// ════════════════════════════════════════════════════════════════════════════
//  SATYA AGENT — API Service
//  Smart Document Detective backend integration
//  Backend repo: satya-agent-main  |  Framework: Node.js + Express
// ════════════════════════════════════════════════════════════════════════════
//
//  📡 BACKEND ENDPOINTS
//  ┌─────────────────────────────────────────────────────────────────────┐
//  │  GET  /            → Health check                                   │
//  │  GET  /health      → Health check (alternative)                     │
//  │  POST /api/detect  → Verify document (single or multi, max 5 files) │
//  └─────────────────────────────────────────────────────────────────────┘
//
//  📎 UPLOAD RULES
//  • Form field name MUST be:  documents
//  • Supported formats:        JPG, PNG, WebP, BMP, TIFF  (images only)
//  • Max file size:            10 MB per file
//  • Max files per request:    5
//
//  📱 HOW TO CONNECT FROM ANDROID
//  ┌───────────────────────────────────────────────────────────────────────────┐
//  │ Physical device (USB/WiFi)  →  http://10.132.127.43:5000  (your PC IP)   │
//  │ Android Emulator            →  http://10.0.2.2:5000                      │
//  │ Production (Render deploy)  →  https://satya-agent-main.onrender.com     │
//  └───────────────────────────────────────────────────────────────────────────┘
//
// ════════════════════════════════════════════════════════════════════════════

class SatyaApiService {
  // ─── ✅ ACTIVE BASE URL — Render.com Cloud Deployment ────────────────────────
  static const String baseUrl = 'https://antonymous-wynona-dictatingly.ngrok-free.dev';

  // ─── Other options (uncomment whichever applies, comment out the one above) ─
  // static const String baseUrl = 'http://10.132.127.43:5000';          // Physical device (same WiFi)
  // static const String baseUrl = 'http://10.0.2.2:5000';               // Android Emulator
  // static const String baseUrl = 'http://localhost:5000';              // Windows desktop only

  // ─── Endpoints ───────────────────────────────────────────────────────────────
  static const String _detectPath = '/api/detect';
  static const String _healthPath = '/health';

  // ─── Timeout ─────────────────────────────────────────────────────────────────
  // OCR + AI processing can take time, especially on first cold boot
  static const Duration _timeout = Duration(seconds: 180);

  // ════════════════════════════════════════════════════════════════════════════
  //  PUBLIC API
  // ════════════════════════════════════════════════════════════════════════════

  /// 🏓 Ping the backend to check if it is alive.
  /// Returns `true` if the server responded with status = "running".
  static Future<bool> checkHealth() async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl$_healthPath'), headers: {
            'ngrok-skip-browser-warning': 'true',
          })
          .timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        return body['status'] == 'running';
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// 📄 Verify a SINGLE document image.
  ///
  /// Sends the image to `POST /api/detect` and returns a typed [SatyaResult]
  /// containing OCR text, extracted fields, forensics analysis,
  /// and the AI fraud probability score.
  ///
  /// Throws [SatyaApiException] on any network or server error.
  static Future<SatyaResult> verifySingleDocument(File imageFile) async {
    return _post([imageFile]);
  }

  /// 📚 Verify 2–5 documents in ONE request.
  ///
  /// The backend will analyse each doc individually AND run cross-doc
  /// mismatch detection (name similarity + DOB comparison).
  ///
  /// Returns a [SatyaResult] with `mismatchAnalysis` + per-doc `documents` list.
  static Future<SatyaResult> verifyMultipleDocuments(List<File> files) async {
    if (files.isEmpty) throw SatyaApiException('No files provided.');
    if (files.length > 5) throw SatyaApiException('Max 5 files per request.');
    return _post(files);
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  PRIVATE HELPERS
  // ════════════════════════════════════════════════════════════════════════════

  static Future<SatyaResult> _post(List<File> files) async {
    try {
      final req = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl$_detectPath'),
      );
      req.headers['ngrok-skip-browser-warning'] = 'true';

      // IMPORTANT: field name must be exactly "documents"
      // IMPORTANT: contentType must be set — without it multer's fileFilter
      //            sees no MIME type and throws "Only image files are accepted"
      for (final f in files) {
        final ext = f.path.split('.').last.toLowerCase();
        final mimeType = switch (ext) {
          'jpg' || 'jpeg' => 'image/jpeg',
          'png'           => 'image/png',
          'webp'          => 'image/webp',
          'bmp'           => 'image/bmp',
          'gif'           => 'image/gif',
          _               => 'image/jpeg', // safe default
        };

        req.files.add(await http.MultipartFile.fromPath(
          'documents',
          f.path,
          contentType: MediaType.parse(mimeType),
        ));
      }

      final streamed = await req.send().timeout(_timeout);
      final res = await http.Response.fromStream(streamed);

      switch (res.statusCode) {
        case 200:
          return SatyaResult.fromJson(
              jsonDecode(res.body) as Map<String, dynamic>);
        case 400:
          final err = jsonDecode(res.body) as Map<String, dynamic>;
          throw SatyaApiException(
              err['error']?.toString() ?? 'Bad request (400).');
        case 404:
          throw SatyaApiException(
              'API route not found (404). Check that the backend is running at $baseUrl');
        case 500:
          throw SatyaApiException(
              'Backend internal error (500). Check server logs.');
        default:
          throw SatyaApiException(
              'Unexpected response: ${res.statusCode}');
      }
    } on SocketException catch (e) {
      throw SatyaApiException(
          'Cannot reach server at $baseUrl.\n'
          'Make sure:\n'
          '• Your phone and PC are on the same WiFi\n'
          '• Backend is running (node app.js)\n'
          '• PC firewall allows port 5000\n'
          'Error: ${e.message}');
    } on http.ClientException catch (e) {
      throw SatyaApiException('Network error: ${e.message}');
    } catch (e) {
      if (e is SatyaApiException) rethrow;
      throw SatyaApiException('Unexpected error: $e');
    }
  }
}

// ════════════════════════════════════════════════════════════════════════════
//  EXCEPTION
// ════════════════════════════════════════════════════════════════════════════

class SatyaApiException implements Exception {
  final String message;
  const SatyaApiException(this.message);

  @override
  String toString() => message;
}

// ════════════════════════════════════════════════════════════════════════════
//  RESPONSE MODELS
//  Mirrors the exact JSON structure returned by /api/detect
// ════════════════════════════════════════════════════════════════════════════

/// Top-level result — handles BOTH single-doc and multi-doc responses.
///
/// Single doc:  `documentType`, `validation`, `extractedInfo`, `forensicsAnalysis`, `aiAgentDecision`
/// Multi doc:   `documents` (list) + `mismatchAnalysis`
class SatyaResult {
  final String agent;

  // Single-doc fields
  final String? documentType;
  final SatyaValidation? validation;
  final SatyaExtractedInfo? extractedInfo;
  final String? ocrText;
  final SatyaForensics? forensicsAnalysis;
  final SatyaAiDecision? aiAgentDecision;

  // Multi-doc fields
  final SatyaMismatchAnalysis? mismatchAnalysis;
  final List<SatyaDocumentResult>? documents;

  const SatyaResult({
    required this.agent,
    this.documentType,
    this.validation,
    this.extractedInfo,
    this.ocrText,
    this.forensicsAnalysis,
    this.aiAgentDecision,
    this.mismatchAnalysis,
    this.documents,
  });

  bool get isSingle => documentType != null;
  bool get isMulti  => documents != null && documents!.isNotEmpty;

  /// Fraud score 0–100. For multi-doc returns the highest among all docs.
  int get fraudScore {
    if (isSingle) return (aiAgentDecision?.fraudProbability ?? 0).round();
    if (isMulti)  {
      return documents!
          .map((d) => (d.aiAgentDecision?.fraudProbability ?? 0).round())
          .reduce((a, b) => a > b ? a : b);
    }
    return 0;
  }

  /// `true` when fraud score < 50 (document considered authentic).
  bool get isAuthentic => fraudScore < 50;

  /// Human-readable risk label.
  String get riskLabel {
    final s = fraudScore;
    if (s == 0)   return 'Authentic';
    if (s <= 20)  return 'Low Risk';
    if (s <= 50)  return 'Medium Risk';
    if (s <= 80)  return 'High Risk';
    return 'Critical / Forged';
  }

  factory SatyaResult.fromJson(Map<String, dynamic> j) => SatyaResult(
        agent:             j['agent'] ?? 'Satya V2.0',
        documentType:      j['documentType'],
        validation:        j['validation']        != null ? SatyaValidation.fromJson(j['validation'])       : null,
        extractedInfo:     j['extractedInfo']     != null ? SatyaExtractedInfo.fromJson(j['extractedInfo']) : null,
        ocrText:           j['ocrText'],
        forensicsAnalysis: j['forensicsAnalysis'] != null ? SatyaForensics.fromJson(j['forensicsAnalysis']) : null,
        aiAgentDecision:   j['aiAgentDecision']   != null ? SatyaAiDecision.fromJson(j['aiAgentDecision'])  : null,
        mismatchAnalysis:  j['mismatchAnalysis']  != null ? SatyaMismatchAnalysis.fromJson(j['mismatchAnalysis']) : null,
        documents:         j['documents'] != null
            ? (j['documents'] as List).map((d) => SatyaDocumentResult.fromJson(d as Map<String, dynamic>)).toList()
            : null,
      );

  // ── Converts API result → ResultScreen / SharedPreferences format ──────────
  // Returns a fraud-detection-centric map. No match/mismatch comparisons.
  Map<String, dynamic> toResultScreenData() {
    final score  = fraudScore;
    final isReal = isAuthentic;
    final date   = DateTime.now().toString().split(' ')[0];

    // ── Build per-document list ──────────────────────────────────────────────
    List<Map<String, dynamic>> docList = [];

    if (isSingle) {
      // Single document
      final reasons = _buildReasons(
        validation: validation,
        forensics: forensicsAnalysis,
        aiExplanation: aiAgentDecision?.explanation,
        fraudScore: score,
      );
      docList.add({
        'documentType': documentType ?? 'Document',
        'docStatus':    isReal ? 'REAL' : 'FAKE',
        'fraudScore':   score,
        'reasons':      reasons,
        'ocrData': {
          'name':     extractedInfo?.name     ?? '',
          'dob':      extractedInfo?.dob       ?? '',
          'gender':   extractedInfo?.gender    ?? '',
          'idNumber': extractedInfo?.idNumber  ?? '',
        },
        'aiExplanation': aiAgentDecision?.explanation ?? '',
      });
    } else if (isMulti && documents != null) {
      // Multiple documents — one entry per doc
      for (int idx = 0; idx < documents!.length; idx++) {
        final doc     = documents![idx];
        final docScore = (doc.aiAgentDecision?.fraudProbability ?? 0).round();
        final docReal  = docScore < 50;
        final reasons  = _buildReasons(
          validation:    doc.validation,
          forensics:     doc.forensicsAnalysis,
          aiExplanation: doc.aiAgentDecision?.explanation,
          fraudScore:    docScore,
        );
        docList.add({
          'documentType': doc.documentType ?? 'Document ${idx + 1}',
          'docStatus':    docReal ? 'REAL' : 'FAKE',
          'fraudScore':   docScore,
          'reasons':      reasons,
          'ocrData': {
            'name':     doc.extractedInfo?.name     ?? '',
            'dob':      doc.extractedInfo?.dob       ?? '',
            'gender':   doc.extractedInfo?.gender    ?? '',
            'idNumber': doc.extractedInfo?.idNumber  ?? '',
          },
          'aiExplanation': doc.aiAgentDecision?.explanation ?? '',
        });
      }
    }

    // ── Short overall summary sentence ───────────────────────────────────────
    String overallSummary;
    if (isReal) {
      overallSummary = 'The document appears genuine with a low fraud risk score of $score%.';
    } else if (score >= 70) {
      overallSummary = 'This document is highly suspicious. Multiple fraud indicators were detected (score: $score%).';
    } else {
      overallSummary = 'This document appears suspicious due to detected anomalies (score: $score%).';
    }
    if (aiAgentDecision?.explanation.isNotEmpty == true) {
      overallSummary = aiAgentDecision!.explanation;
    } else if (documents?.firstOrNull?.aiAgentDecision?.explanation.isNotEmpty == true) {
      overallSummary = documents!.first.aiAgentDecision!.explanation;
    }

    // Human-readable summary line (used in history list)
    final docTypeLabel = documentType
        ?? documents?.map((d) => d.documentType ?? 'Document').join(' + ')
        ?? 'Document';
    final summaryLine = isSingle
        ? '$docTypeLabel Fraud Analysis'
        : 'Multi-Doc Analysis ($docTypeLabel)';

    return {
      'date':            date,           // yyyy-MM-dd — reliable for weekday parsing
      'status':          isReal ? 'REAL' : 'FAKE',
      'fraudScore':      score,
      'summary':         summaryLine,    // shown as title in history & analytics
      'overallSummary':  overallSummary,
      'documentType':    documentType ?? documents?.map((d) => d.documentType).join(', ') ?? 'Unknown',
      'documents':       docList,
      // Legacy shortcuts (used by history screen & PDF export)
      'extractedName':     extractedInfo?.name    ?? documents?.firstOrNull?.extractedInfo?.name     ?? '',
      'extractedDob':      extractedInfo?.dob      ?? documents?.firstOrNull?.extractedInfo?.dob      ?? '',
      'extractedIdNumber': extractedInfo?.idNumber ?? documents?.firstOrNull?.extractedInfo?.idNumber ?? '',
      'aiExplanation':     aiAgentDecision?.explanation
                             ?? documents?.firstOrNull?.aiAgentDecision?.explanation ?? '',
    };
  }

  /// Derives a list of human-readable fraud reasons from validation + forensics data.
  static List<String> _buildReasons({
    SatyaValidation?  validation,
    SatyaForensics?   forensics,
    String?           aiExplanation,
    required int      fraudScore,
  }) {
    final reasons = <String>[];

    if (validation != null) {
      if (!validation.isValidFormat)         reasons.add('Invalid ID format detected');
      if (!validation.keywordsFound)         reasons.add('Expected keywords not found in document');
      if (validation.isMathematicallyFake)   reasons.add('Data inconsistency detected');
    }

    if (forensics != null) {
      if (forensics.isScreenshot)            reasons.add('Screenshot detected — not an original document');
      if (forensics.isBlurred)               reasons.add('Blur detected — image quality too low');
      if (forensics.possibleTampering)       reasons.add('Possible tampering or digital alteration found');
    }

    // If no specific reasons but score is high, add a generic note
    if (reasons.isEmpty && fraudScore >= 50) {
      reasons.add('AI detected suspicious patterns in the document');
    }

    return reasons;
  }
}

// ─── Per-document result (multi-doc mode) ────────────────────────────────────
class SatyaDocumentResult {
  final String? documentType;
  final SatyaValidation? validation;
  final SatyaExtractedInfo? extractedInfo;
  final String? ocrText;
  final SatyaForensics? forensicsAnalysis;
  final SatyaAiDecision? aiAgentDecision;

  const SatyaDocumentResult({
    this.documentType,
    this.validation,
    this.extractedInfo,
    this.ocrText,
    this.forensicsAnalysis,
    this.aiAgentDecision,
  });

  factory SatyaDocumentResult.fromJson(Map<String, dynamic> j) =>
      SatyaDocumentResult(
        documentType:      j['documentType'],
        validation:        j['validation']        != null ? SatyaValidation.fromJson(j['validation'])       : null,
        extractedInfo:     j['extractedInfo']     != null ? SatyaExtractedInfo.fromJson(j['extractedInfo']) : null,
        ocrText:           j['ocrText'],
        forensicsAnalysis: j['forensicsAnalysis'] != null ? SatyaForensics.fromJson(j['forensicsAnalysis']) : null,
        aiAgentDecision:   j['aiAgentDecision']   != null ? SatyaAiDecision.fromJson(j['aiAgentDecision'])  : null,
      );
}

// ─── Validation ───────────────────────────────────────────────────────────────
class SatyaValidation {
  final bool isValidFormat;
  final bool keywordsFound;
  final bool isMathematicallyFake;
  final Map<String, dynamic> extraValidation;

  const SatyaValidation({
    required this.isValidFormat,
    required this.keywordsFound,
    required this.isMathematicallyFake,
    required this.extraValidation,
  });

  factory SatyaValidation.fromJson(Map<String, dynamic> j) => SatyaValidation(
        isValidFormat:        j['isValidFormat']       ?? false,
        keywordsFound:        j['keywordsFound']        ?? false,
        isMathematicallyFake: j['isMathematicallyFake'] ?? false,
        extraValidation:      Map<String, dynamic>.from(j['extraValidation'] ?? {}),
      );
}

// ─── Extracted Info ───────────────────────────────────────────────────────────
class SatyaExtractedInfo {
  final String? name;
  final String? dob;
  final String? gender;
  final String? idNumber;
  final String? documentCategory;
  final Map<String, dynamic> additionalFields;

  const SatyaExtractedInfo({
    this.name,
    this.dob,
    this.gender,
    this.idNumber,
    this.documentCategory,
    required this.additionalFields,
  });

  factory SatyaExtractedInfo.fromJson(Map<String, dynamic> j) =>
      SatyaExtractedInfo(
        name:              j['name'],
        dob:               j['dob'],
        gender:            j['gender'],
        idNumber:          j['idNumber'],
        documentCategory:  j['documentCategory'],
        additionalFields:  Map<String, dynamic>.from(j['additionalFields'] ?? {}),
      );
}

// ─── Forensics ────────────────────────────────────────────────────────────────
class SatyaForensics {
  final bool isBlurred;
  final bool possibleTampering;
  final bool isScreenshot;

  const SatyaForensics({
    required this.isBlurred,
    required this.possibleTampering,
    required this.isScreenshot,
  });

  factory SatyaForensics.fromJson(Map<String, dynamic> j) => SatyaForensics(
        isBlurred:          j['isBlurred']          ?? false,
        possibleTampering:  j['possibleTampering']   ?? false,
        isScreenshot:       j['isScreenshot']        ?? false,
      );
}

// ─── AI Decision ──────────────────────────────────────────────────────────────
class SatyaAiDecision {
  final num fraudProbability;
  final String explanation;

  const SatyaAiDecision({
    required this.fraudProbability,
    required this.explanation,
  });

  factory SatyaAiDecision.fromJson(Map<String, dynamic> j) => SatyaAiDecision(
        fraudProbability: j['fraudProbability'] ?? 0,
        explanation:      j['explanation']?.toString() ?? '',
      );
}

// ─── Mismatch Analysis (multi-doc) ───────────────────────────────────────────
class SatyaMismatchAnalysis {
  final int documentsAnalyzed;
  final bool mismatchDetected;
  final List<String> mismatchDetails;

  const SatyaMismatchAnalysis({
    required this.documentsAnalyzed,
    required this.mismatchDetected,
    required this.mismatchDetails,
  });

  factory SatyaMismatchAnalysis.fromJson(Map<String, dynamic> j) =>
      SatyaMismatchAnalysis(
        documentsAnalyzed: j['documentsAnalyzed'] ?? 0,
        mismatchDetected:  j['mismatchDetected']  ?? false,
        mismatchDetails:   List<String>.from(j['mismatchDetails'] ?? []),
      );
}
