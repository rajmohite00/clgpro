import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

// ════════════════════════════════════════════════════════════════════════════
//  Professional PDF Report Generator
// ════════════════════════════════════════════════════════════════════════════

class PdfReportGenerator {
  // ── Color constants ────────────────────────────────────────────────────
  static const PdfColor _headerBg  = PdfColor.fromInt(0xFF0A0F1E);
  static const PdfColor _green     = PdfColor.fromInt(0xFF10B981);
  static const PdfColor _red       = PdfColor.fromInt(0xFFEF4444);
  static const PdfColor _amber     = PdfColor.fromInt(0xFFF59E0B);
  static const PdfColor _sectionBg = PdfColor.fromInt(0xFFF8FAFC);
  static const PdfColor _divider   = PdfColor.fromInt(0xFFE2E8F0);
  static const PdfColor _textMain  = PdfColor.fromInt(0xFF0F172A);
  static const PdfColor _textSub   = PdfColor.fromInt(0xFF64748B);
  static const PdfColor _tableBg   = PdfColor.fromInt(0xFF1E3A5F);

  static PdfColor _scoreColor(int s) {
    if (s <= 30) return _green;
    if (s <= 70) return _amber;
    return _red;
  }

  static String _riskLabel(int s) {
    if (s <= 30) return 'LOW RISK';
    if (s <= 70) return 'MEDIUM RISK';
    return 'HIGH RISK';
  }

  static pw.Widget _statBox(String label, String value, PdfColor bg, PdfColor fg) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: pw.BoxDecoration(
          color: bg,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(label, style: pw.TextStyle(fontSize: 6.5, color: fg, letterSpacing: 0.8)),
            pw.SizedBox(height: 4),
            pw.Text(value, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: fg)),
          ],
        ),
      ),
    );
  }

  /// Main entry point — call this to render and share/print the report.
  static Future<void> generate({
    required List<Map<String, dynamic>> docs,
    required int fraudScore,
    required String status,
    required String summary,
  }) async {
    final pdf      = pw.Document();
    final now      = DateTime.now();
    final date     = '${now.year}-${_p(now.month)}-${_p(now.day)}';
    final time     = '${_p(now.hour)}:${_p(now.minute)}';
    final reportId = 'DVR-${now.year}${_p(now.month)}${_p(now.day)}-${now.millisecondsSinceEpoch % 100000}';
    final isReal   = status == 'REAL';
    final overallAccent = isReal ? _green : _red;

    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 36),

      // ── Header ────────────────────────────────────────────────────────
      header: (ctx) => pw.Container(
        decoration: const pw.BoxDecoration(color: _headerBg),
        padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('DOCVERIFY',
                    style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                        letterSpacing: 4)),
                pw.SizedBox(height: 2),
                pw.Text('FRAUD INTELLIGENCE SYSTEM',
                    style: const pw.TextStyle(
                        fontSize: 7, color: _green, letterSpacing: 2)),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text('DOCUMENT VERIFICATION REPORT',
                    style: const pw.TextStyle(
                        fontSize: 8, color: PdfColors.white, letterSpacing: 1)),
                pw.SizedBox(height: 3),
                pw.Text('ID: $reportId',
                    style: const pw.TextStyle(fontSize: 7, color: _green)),
                pw.Text('$date  $time',
                    style: const pw.TextStyle(
                        fontSize: 7, color: PdfColors.grey300)),
              ],
            ),
          ],
        ),
      ),

      // ── Footer ────────────────────────────────────────────────────────
      footer: (ctx) => pw.Container(
        margin: const pw.EdgeInsets.only(top: 8),
        padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        decoration: const pw.BoxDecoration(
          border: pw.Border(
              top: pw.BorderSide(color: _divider, width: 0.5)),
        ),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('DocVerify — AI-Powered Document Fraud Detection System',
                style: const pw.TextStyle(fontSize: 7, color: _textSub)),
            pw.Text(
                'Page ${ctx.pageNumber} of ${ctx.pagesCount}',
                style: const pw.TextStyle(fontSize: 7, color: _textSub)),
          ],
        ),
      ),

      build: (ctx) => [
        pw.SizedBox(height: 20),

        // ── Verdict banner ─────────────────────────────────────────────
        pw.Container(
          padding: const pw.EdgeInsets.all(16),
          decoration: pw.BoxDecoration(
            color: isReal
                ? const PdfColor.fromInt(0xFFD1FAE5)
                : const PdfColor.fromInt(0xFFFEE2E2),
            borderRadius:
                const pw.BorderRadius.all(pw.Radius.circular(8)),
            border: pw.Border.all(color: overallAccent, width: 1),
          ),
          child: pw.Row(
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('VERIFICATION VERDICT',
                        style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.bold,
                            color: _textSub,
                            letterSpacing: 1.5)),
                    pw.SizedBox(height: 4),
                    pw.Text(isReal ? 'GENUINE' : 'FRAUDULENT',
                        style: pw.TextStyle(
                            fontSize: 22,
                            fontWeight: pw.FontWeight.bold,
                            color: overallAccent,
                            letterSpacing: 1)),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      isReal
                          ? 'All documents passed authenticity verification. No fraud indicators detected.'
                          : 'Fraud indicators were detected. Please review the flagged documents carefully.',
                      style: const pw.TextStyle(fontSize: 9, color: _textMain),
                    ),
                    if (summary.isNotEmpty) ...[
                      pw.SizedBox(height: 6),
                      pw.Text(summary,
                          style: const pw.TextStyle(
                              fontSize: 8, color: _textSub)),
                    ],
                  ],
                ),
              ),
              pw.SizedBox(width: 20),
              // Score gauge
              pw.Column(
                children: [
                  pw.Text('FRAUD SCORE',
                      style: const pw.TextStyle(
                          fontSize: 7, color: _textSub, letterSpacing: 1)),
                  pw.SizedBox(height: 4),
                  pw.Container(
                    width: 64,
                    height: 64,
                    decoration: pw.BoxDecoration(
                      shape: pw.BoxShape.circle,
                      border: pw.Border.all(
                          color: _scoreColor(fraudScore), width: 3),
                      color: PdfColors.white,
                    ),
                    child: pw.Center(
                      child: pw.Column(
                        mainAxisSize: pw.MainAxisSize.min,
                        children: [
                          pw.Text('$fraudScore',
                              style: pw.TextStyle(
                                  fontSize: 18,
                                  fontWeight: pw.FontWeight.bold,
                                  color: _scoreColor(fraudScore))),
                          pw.Text('/100',
                              style: const pw.TextStyle(
                                  fontSize: 7, color: _textSub)),
                        ],
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(_riskLabel(fraudScore),
                      style: pw.TextStyle(
                          fontSize: 7,
                          fontWeight: pw.FontWeight.bold,
                          color: _scoreColor(fraudScore),
                          letterSpacing: 0.8)),
                ],
              ),
            ],
          ),
        ),

        pw.SizedBox(height: 16),

        // ── Stats row ──────────────────────────────────────────────────
        pw.Row(
          children: [
            _statBox('DOCUMENTS', '${docs.length}',
                const PdfColor.fromInt(0xFF1E3A5F), PdfColors.white),
            pw.SizedBox(width: 8),
            _statBox(
                'GENUINE',
                '${docs.where((d) => d["docStatus"] == "REAL").length}',
                const PdfColor.fromInt(0xFF065F46),
                _green),
            pw.SizedBox(width: 8),
            _statBox(
                'FLAGGED',
                '${docs.where((d) => d["docStatus"] != "REAL").length}',
                const PdfColor.fromInt(0xFF7F1D1D),
                _red),
            pw.SizedBox(width: 8),
            _statBox('SCAN DATE', date,
                const PdfColor.fromInt(0xFF312E81), PdfColors.white),
          ],
        ),

        pw.SizedBox(height: 24),

        // ── Per-document breakdown ──────────────────────────────────────
        pw.Text('DOCUMENT ANALYSIS BREAKDOWN',
            style: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: _textSub,
                letterSpacing: 2)),
        pw.SizedBox(height: 2),
        pw.Divider(color: _divider, thickness: 0.5),
        pw.SizedBox(height: 12),

        ...docs.asMap().entries.expand((entry) {
          final idx          = entry.key;
          final d            = entry.value;
          final Map ocr      = d['ocrData'] is Map ? d['ocrData'] as Map : {};
          final List reasons = d['reasons'] is List ? List.from(d['reasons'] as List) : [];
          final bool isR     = d['docStatus'] == 'REAL';
          final int sc       = d['fraudScore'] is int ? d['fraudScore'] as int : 0;
          final String dtLabel = d['documentType']?.toString() ?? 'Document ${idx + 1}';
          final statusAccent = isR ? _green : _red;

          final ocrMap = <String, String>{
            'Name':         ocr['name']     as String? ?? '',
            'Date of Birth': ocr['dob']     as String? ?? '',
            'Gender':       ocr['gender']   as String? ?? '',
            'ID Number':    ocr['idNumber'] as String? ?? '',
          }..removeWhere((_, v) => v.isEmpty);

          return [
            // Header card
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              decoration: pw.BoxDecoration(
                color: _sectionBg,
                borderRadius:
                    const pw.BorderRadius.all(pw.Radius.circular(6)),
                border: pw.Border(
                    left: pw.BorderSide(
                        color: statusAccent, width: 4)),
              ),
              child: pw.Row(
                mainAxisAlignment:
                    pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment:
                        pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('DOCUMENT ${idx + 1}',
                          style: pw.TextStyle(
                              fontSize: 7,
                              color: _textSub,
                              letterSpacing: 1.5)),
                      pw.SizedBox(height: 2),
                      pw.Text(dtLabel,
                          style: pw.TextStyle(
                              fontSize: 12,
                              fontWeight: pw.FontWeight.bold,
                              color: _textMain)),
                    ],
                  ),
                  pw.Row(
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: pw.BoxDecoration(
                          color: statusAccent,
                          borderRadius: const pw.BorderRadius.all(
                              pw.Radius.circular(4)),
                        ),
                        child: pw.Text(
                          isR ? 'GENUINE' : 'FRAUDULENT',
                          style: pw.TextStyle(
                              fontSize: 8,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.white,
                              letterSpacing: 0.5),
                        ),
                      ),
                      pw.SizedBox(width: 8),
                      pw.Text('Score: $sc/100',
                          style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                              color: _scoreColor(sc))),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 8),

            // Extracted OCR table
            if (ocrMap.isNotEmpty) ...[
              pw.Text('EXTRACTED DATA',
                  style: const pw.TextStyle(
                      fontSize: 7, color: _textSub, letterSpacing: 1.5)),
              pw.SizedBox(height: 4),
              pw.TableHelper.fromTextArray(
                headers: ['Field', 'Extracted Value'],
                headerStyle: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 8,
                    color: PdfColors.white),
                headerDecoration:
                    const pw.BoxDecoration(color: _tableBg),
                cellStyle:
                    const pw.TextStyle(fontSize: 9, color: _textMain),
                oddRowDecoration:
                    const pw.BoxDecoration(color: _sectionBg),
                headerHeight: 20,
                cellHeight: 18,
                cellAlignments: {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.centerLeft,
                },
                cellPadding: const pw.EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                data: ocrMap.entries
                    .map((e) => [e.key, e.value])
                    .toList(),
              ),
              pw.SizedBox(height: 8),
            ],

            // Fraud indicators
            if (reasons.isNotEmpty) ...[
              pw.Text('FRAUD INDICATORS',
                  style: const pw.TextStyle(
                      fontSize: 7, color: _red, letterSpacing: 1.5)),
              pw.SizedBox(height: 4),
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: const pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFFFFF5F5),
                  borderRadius:
                      pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: reasons
                      .map((r) => pw.Padding(
                            padding:
                                const pw.EdgeInsets.only(bottom: 3),
                            child: pw.Row(
                              crossAxisAlignment:
                                  pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text('• ',
                                    style: const pw.TextStyle(
                                        fontSize: 9, color: _red)),
                                pw.Expanded(
                                    child: pw.Text(r,
                                        style: const pw.TextStyle(
                                            fontSize: 9,
                                            color: _textMain))),
                              ],
                            ),
                          ))
                      .toList(),
                ),
              ),
              pw.SizedBox(height: 8),
            ],

            pw.SizedBox(height: 10),
            pw.Divider(color: _divider, thickness: 0.5),
            pw.SizedBox(height: 10),
          ];
        }),

        // ── Disclaimer ─────────────────────────────────────────────────
        pw.SizedBox(height: 8),
        pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: const pw.BoxDecoration(
            color: PdfColor.fromInt(0xFFF0F9FF),
            borderRadius:
                pw.BorderRadius.all(pw.Radius.circular(6)),
            border: pw.Border(
                left: pw.BorderSide(
                    color: PdfColor.fromInt(0xFF0EA5E9), width: 3)),
          ),
          child: pw.Text(
            'DISCLAIMER: This report is generated by an AI-based fraud detection system. '
            'Results are for informational purposes only and should not be the sole basis '
            'for legal or financial decisions. DocVerify is not liable for actions taken '
            'based solely on this report.',
            style: const pw.TextStyle(fontSize: 7.5, color: _textSub),
          ),
        ),
      ],
    ));

    final bytes = await pdf.save();
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'DocVerify_Report_$date.pdf',
    );
  }

  static String _p(int n) => n.toString().padLeft(2, '0');
}
