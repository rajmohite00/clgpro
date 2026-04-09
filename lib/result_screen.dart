import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'widgets/image_viewer_screen.dart';
import 'providers/settings_provider.dart';
import 'providers/document_provider.dart';
import 'utils/animations.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  RESULT SCREEN  ·  Minimal Government-Style
// ─────────────────────────────────────────────────────────────────────────────

class ResultScreen extends StatelessWidget {
  final Map<String, dynamic> resultData;
  const ResultScreen({super.key, required this.resultData});

  // ── Data helpers ─────────────────────────────────────────────────────────
  List<Map<String, dynamic>> get _docs {
    final raw = resultData['documents'];
    if (raw == null || raw is! List) return [];
    return List<Map<String, dynamic>>.from(
        raw.map((e) => Map<String, dynamic>.from(e as Map)));
  }

  int    get _score  => (resultData['fraudScore'] as int?)  ?? 0;
  String get _status => (resultData['status']    as String?) ?? 'UNKNOWN';
  bool   get _isReal => _status == 'REAL';

  // Mismatch helpers (only meaningful when >1 document)
  int get _fakeCount => _docs.where((d) => (d['docStatus'] as String?) != 'REAL').length;
  int get _mismatchPercent {
    final total = _docs.length;
    if (total == 0) return 0;
    return ((_fakeCount / total) * 100).round();
  }

  Color _scoreColor(int s) {
    if (s <= 30) return const Color(0xFF10B981);
    if (s <= 70) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  String _riskLabel(int s) {
    if (s <= 30) return 'Low Risk';
    if (s <= 70) return 'Medium Risk';
    return 'High Risk';
  }

  // ── OCR field-level mismatch comparison ────────────────────────────────
  // Returns a map of { fieldLabel → [ {docIndex, value} ] } for every field
  // that does NOT have the same non-empty value across all documents.
  Map<String, List<Map<String, String>>> _ocrFieldMismatches(
      List<Map<String, dynamic>> docs) {
    const fields = {
      'name':     'Name',
      'dob':      'Date of Birth',
      'gender':   'Gender',
      'idNumber': 'ID Number',
    };

    final result = <String, List<Map<String, String>>>{};

    for (final entry in fields.entries) {
      final key   = entry.key;
      final label = entry.value;
      final values = <String>[];

      for (final d in docs) {
        final ocr = d['ocrData'] as Map? ?? {};
        values.add((ocr[key] as String? ?? '').trim());
      }

      // Only non-empty values matter; skip if all empty
      final nonEmpty = values.where((v) => v.isNotEmpty).toList();
      if (nonEmpty.isEmpty) continue;

      // If not all identical → mismatch
      final unique = nonEmpty.toSet();
      if (unique.length > 1) {
        result[label] = docs.asMap().entries.map((e) {
          final val = values[e.key];
          return {'doc': 'Doc ${e.key + 1}', 'value': val.isEmpty ? '—' : val};
        }).toList();
      }
    }
    return result;
  }

  Color _mismatchColor(int pct) {
    if (pct == 0)   return const Color(0xFF10B981);
    if (pct <= 50)  return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  // ── PDF ───────────────────────────────────────────────────────────────────
  Future<void> _generatePdf(BuildContext context) async {
    final doc  = pw.Document();
    final docs = _docs;
    final date = DateTime.now().toString().split(' ')[0];

    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(36),
      build: (pw.Context c) => [
        pw.Row(children: [
          pw.Text('DocVerify — Fraud Analysis Report',
              style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.indigo900)),
          pw.Spacer(),
          pw.Text(date,
              style: const pw.TextStyle(
                  fontSize: 10, color: PdfColors.grey600)),
        ]),
        pw.Divider(height: 20),
        pw.Text(
          'Overall: $_status   Fraud Score: $_score / 100',
          style: pw.TextStyle(
              fontSize: 13,
              fontWeight: pw.FontWeight.bold,
              color: _isReal ? PdfColors.green700 : PdfColors.red700),
        ),
        pw.SizedBox(height: 20),
        ...docs.asMap().entries.expand((entry) {
          final i   = entry.key;
          final doc = entry.value;
          final ocr  = doc['ocrData'] as Map? ?? {};
          final reas = List<String>.from(doc['reasons'] as List? ?? []);
          return [
            pw.Text('Document ${i + 1} · ${doc['documentType'] ?? ''}',
                style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 4),
            pw.Text('Status: ${doc['docStatus']}   Score: ${doc['fraudScore']}/100',
                style: pw.TextStyle(
                    fontSize: 11,
                    color: doc['docStatus'] == 'REAL'
                        ? PdfColors.green700
                        : PdfColors.red700)),
            if (reas.isNotEmpty) ...[
              pw.SizedBox(height: 6),
              pw.Text('Fraud Indicators:',
                  style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
              ...reas.map((r) => pw.Bullet(
                  text: r,
                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.red800))),
            ],
            pw.SizedBox(height: 6),
            if (['name','dob','gender','idNumber']
                .any((k) => (ocr[k] as String? ?? '').isNotEmpty)) ...[
              pw.Text('Extracted Data:',
                  style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
              for (final kv in {
                'Name': ocr['name'],
                'DOB': ocr['dob'],
                'Gender': ocr['gender'],
                'ID Number': ocr['idNumber'],
              }.entries)
                if ((kv.value as String? ?? '').isNotEmpty)
                  pw.Text('  ${kv.key}: ${kv.value}',
                      style: const pw.TextStyle(fontSize: 10)),
            ],
            pw.SizedBox(height: 16),
          ];
        }),
        pw.Divider(),
        pw.Text('Generated by DocVerify',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey400)),
      ],
    ));

    await Printing.layoutPdf(
        onLayout: (_) async => doc.save(),
        name: 'FraudReport_$date.pdf');
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  BUILD
  // ══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final isHindi     = Provider.of<SettingsProvider>(context).isHindi;
    final theme       = Theme.of(context);
    final isDark      = theme.brightness == Brightness.dark;
    final cs          = theme.colorScheme;
    final bg          = theme.scaffoldBackgroundColor;
    final card        = theme.cardColor;
    final divClr      = theme.dividerColor;
    final textPri     = cs.onSurface;
    final textSec     = cs.onSurface.withOpacity(0.5);
    final statusColor = _isReal ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    final scoreColor  = _scoreColor(_score);
    final docs        = _docs;
    final summary     = resultData['overallSummary'] as String? ?? '';
    final reportDate  = () {
      final d = resultData['date'] as String? ?? '';
      return d.isNotEmpty ? d : DateTime.now().toString().split(' ')[0];
    }();

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          backgroundColor: isDark ? const Color(0xFF0D1526) : Colors.white,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          automaticallyImplyLeading: false,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Divider(height: 1, color: divClr),
          ),
          title: Row(children: [
            GestureDetector(
              onTap: () => Navigator.popUntil(context, (r) => r.isFirst),
              child: Icon(Icons.arrow_back_ios_new_rounded,
                  size: 18.sp, color: textPri),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                tr('Analysis Report', isHindi),
                style: GoogleFonts.inter(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: textPri),
              ),
            ),
            // Actions
            _iconBtn(Icons.share_outlined, textSec, () =>
                Share.share('Result: $_status  |  Score: $_score/100\nVerified via DocVerify')),
            SizedBox(width: 4.w),
            _iconBtn(Icons.picture_as_pdf_outlined, textSec,
                () => _generatePdf(context)),
          ]),
        ),
        body: ListView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 40.h),
          children: [

            // ── VERDICT BANNER ─────────────────────────────────────────────
            SlideIn(
              begin: const Offset(0, 0.1),
              duration: const Duration(milliseconds: 480),
              child: _verdictBanner(
                statusColor: statusColor,
                scoreColor:  scoreColor,
                textPri:     textPri,
                textSec:     textSec,
                reportDate:  reportDate,
                isDark:      isDark,
              ),
            ),
            SizedBox(height: 16.h),

            // ── MISMATCH SCORE (multi-doc only) ────────────────────────────
            if (docs.length > 1) ...[
              SlideIn(
                delay: const Duration(milliseconds: 80),
                child: _mismatchBanner(
                  docs:     docs,
                  card:     card,
                  divClr:   divClr,
                  textPri:  textPri,
                  textSec:  textSec,
                  isHindi:  isHindi,
                ),
              ),
              SizedBox(height: 16.h),
            ],

            // ── SUMMARY ────────────────────────────────────────────────────
            if (summary.isNotEmpty) ...[
              SlideIn(
                delay: const Duration(milliseconds: 120),
                child: _summaryCard(summary, card, divClr, textPri, textSec, isHindi),
              ),
              SizedBox(height: 16.h),
            ],

            // ── SCANNED FILES ──────────────────────────────────────────────
            if ((resultData['imagePaths'] as List?)?.isNotEmpty == true) ...[
              SlideIn(
                delay: const Duration(milliseconds: 130),
                child: _sectionLabel('Scanned Files', textPri),
              ),
              SizedBox(height: 8.h),
              SlideIn(
                delay: const Duration(milliseconds: 160),
                child: _filesStrip(context,
                    List<String>.from(resultData['imagePaths'] as List),
                    divClr, card),
              ),
              SizedBox(height: 16.h),
            ],

            // ── PER-DOCUMENT CARDS ─────────────────────────────────────────
            if (docs.isNotEmpty) ...[
              SlideIn(
                delay: const Duration(milliseconds: 200),
                child: _sectionLabel(
                    docs.length == 1 ? 'Document Analysis' : 'Per-Document Results',
                    textPri),
              ),
              SizedBox(height: 8.h),
              ...docs.asMap().entries.map((e) => AnimatedListItem(
                index: e.key,
                delay: const Duration(milliseconds: 80),
                child: Padding(
                  padding: EdgeInsets.only(bottom: 12.h),
                  child: _docCard(
                    index:   e.key,
                    doc:     e.value,
                    card:    card,
                    divClr:  divClr,
                    textPri: textPri,
                    textSec: textSec,
                    isHindi: isHindi,
                  ),
                ),
              )),
            ],

            // ── ACTION BUTTONS ─────────────────────────────────────────────
            SizedBox(height: 8.h),
            SlideIn(
              delay: const Duration(milliseconds: 300),
              child: _actionRow(context, textPri, textSec, cs, isHindi),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  VERDICT BANNER
  // ══════════════════════════════════════════════════════════════════════════
  Widget _verdictBanner({
    required Color statusColor,
    required Color scoreColor,
    required Color textPri,
    required Color textSec,
    required String reportDate,
    required bool isDark,
  }) {
    final bg = statusColor.withOpacity(0.06);
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: statusColor.withOpacity(0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Score circle
          Container(
            width: 60.w,
            height: 60.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: scoreColor.withOpacity(0.1),
              border: Border.all(color: scoreColor, width: 2),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$_score',
                    style: GoogleFonts.inter(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w900,
                      color: scoreColor,
                      height: 1,
                    ),
                  ),
                  Text(
                    '/100',
                    style: GoogleFonts.inter(
                        fontSize: 8.sp,
                        color: scoreColor.withOpacity(0.7)),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: 12.w),

          // Text block
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(children: [
                  Container(
                    width: 7.w, height: 7.w,
                    decoration: BoxDecoration(
                        color: statusColor, shape: BoxShape.circle),
                  ),
                  SizedBox(width: 5.w),
                  Flexible(
                    child: Text(
                      _isReal ? 'GENUINE' : 'FRAUDULENT',
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w800,
                        color: statusColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ]),
                SizedBox(height: 3.h),
                Text(
                  _isReal ? 'Document Verified' : 'Fraud Detected',
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: textPri,
                  ),
                ),
                SizedBox(height: 2.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _riskLabel(_score),
                      style: GoogleFonts.inter(
                          fontSize: 11.sp, color: scoreColor),
                    ),
                    // Date
                    Text(
                      reportDate,
                      style: GoogleFonts.inter(fontSize: 9.sp, color: textSec),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  MISMATCH BANNER  (shown when ≥2 documents uploaded)
  // ══════════════════════════════════════════════════════════════════════════
  Widget _mismatchBanner({
    required List<Map<String, dynamic>> docs,
    required Color card,
    required Color divClr,
    required Color textPri,
    required Color textSec,
    required bool isHindi,
  }) {
    final total   = docs.length;
    final fake    = _fakeCount;
    final real    = total - fake;
    final pct     = _mismatchPercent;
    final clr     = _mismatchColor(pct);
    final isAllOk = pct == 0;

    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: clr.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: clr.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Header row ──────────────────────────────────────────────────
          Row(children: [
            Icon(
              isAllOk
                  ? Icons.verified_outlined
                  : Icons.compare_arrows_rounded,
              size: 15.sp,
              color: clr,
            ),
            SizedBox(width: 6.w),
            Flexible(
              child: Text(
                isHindi
                    ? 'दस्तावेज़ मिलान स्कोर'
                    : 'Document Mismatch Score',
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  color: clr,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            SizedBox(width: 8.w),
            // Big percentage badge
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: clr.withOpacity(0.12),
                borderRadius: BorderRadius.circular(6.r),
                border: Border.all(color: clr.withOpacity(0.35)),
              ),
              child: Text(
                '$pct% ${isHindi ? "बेमेल" : "Mismatch"}',
                style: GoogleFonts.inter(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w800,
                  color: clr,
                ),
              ),
            ),
          ]),
          SizedBox(height: 10.h),

          // ── Progress bar ─────────────────────────────────────────────────
          ClipRRect(
            borderRadius: BorderRadius.circular(4.r),
            child: LinearProgressIndicator(
              value: pct / 100,
              minHeight: 8.h,
              backgroundColor: clr.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(clr),
            ),
          ),
          SizedBox(height: 6.h),

          // ── Legend ───────────────────────────────────────────────────────
          Row(children: [
            _mismatchLegendDot(const Color(0xFF10B981)),
            SizedBox(width: 4.w),
            Text(
              '$real ${isHindi ? "असली" : "Genuine"}',
              style: GoogleFonts.inter(fontSize: 11.sp, color: textSec),
            ),
            SizedBox(width: 16.w),
            _mismatchLegendDot(const Color(0xFFEF4444)),
            SizedBox(width: 4.w),
            Text(
              '$fake ${isHindi ? "नकली" : "Fake"}',
              style: GoogleFonts.inter(fontSize: 11.sp, color: textSec),
            ),
            SizedBox(width: 16.w),
            _mismatchLegendDot(textSec.withOpacity(0.4)),
            SizedBox(width: 4.w),
            Text(
              '$total ${isHindi ? "कुल" : "Total"}',
              style: GoogleFonts.inter(fontSize: 11.sp, color: textSec),
            ),
          ]),
          SizedBox(height: 12.h),

          Divider(height: 1, color: divClr),
          SizedBox(height: 10.h),

          // ── Per-document chip list ───────────────────────────────────────
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: docs.asMap().entries.map((e) {
              final idx     = e.key;
              final d       = e.value;
              final docReal = (d['docStatus'] as String?) == 'REAL';
              final chipClr = docReal
                  ? const Color(0xFF10B981)
                  : const Color(0xFFEF4444);
              final docLabel = d['documentType'] as String?
                  ?? 'Doc ${idx + 1}';
              return Container(
                padding: EdgeInsets.symmetric(
                    horizontal: 10.w, vertical: 5.h),
                decoration: BoxDecoration(
                  color: chipClr.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(color: chipClr.withOpacity(0.3)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(
                    docReal
                        ? Icons.check_circle_outline_rounded
                        : Icons.cancel_outlined,
                    size: 12.sp,
                    color: chipClr,
                  ),
                  SizedBox(width: 5.w),
                  Text(
                    '#${idx + 1} · $docLabel',
                    style: GoogleFonts.inter(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: chipClr,
                    ),
                  ),
                ]),
              );
            }).toList(),
          ),

          // ── OCR Field Mismatches ─────────────────────────────────────────
          Builder(builder: (context) {
            final fieldMismatches = _ocrFieldMismatches(docs);
            if (fieldMismatches.isEmpty) return const SizedBox.shrink();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 12.h),
                Divider(height: 1, color: divClr),
                SizedBox(height: 12.h),

                // Sub-header
                Row(children: [
                  Icon(Icons.data_object_rounded,
                      size: 13.sp,
                      color: const Color(0xFFEF4444)),
                  SizedBox(width: 6.w),
                  Flexible(
                    child: Text(
                      isHindi ? 'OCR फ़ील्ड बेमेल' : 'OCR Field Mismatches',
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFEF4444),
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  SizedBox(width: 6.w),
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 6.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    child: Text(
                      '${fieldMismatches.length} ${isHindi ? "फ़ील्ड" : "field${fieldMismatches.length > 1 ? "s" : ""}" }',
                      style: GoogleFonts.inter(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFEF4444),
                      ),
                    ),
                  ),
                ]),
                SizedBox(height: 10.h),

                // Each mismatched field
                ...fieldMismatches.entries.map((fe) {
                  final fieldLabel = fe.key;
                  final entries    = fe.value;
                  return Container(
                    margin: EdgeInsets.only(bottom: 8.h),
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withOpacity(0.04),
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(
                          color: const Color(0xFFEF4444).withOpacity(0.18)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Field name row
                        Row(children: [
                          Container(
                            width: 3.w,
                            height: 14.h,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444),
                              borderRadius: BorderRadius.circular(2.r),
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Flexible(
                            child: Text(
                              isHindi
                                  ? _hindiFieldLabel(fieldLabel)
                                  : fieldLabel,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w700,
                                color: textPri,
                              ),
                            ),
                          ),
                          SizedBox(width: 6.w),
                          Text(
                            isHindi ? 'बेमेल' : 'Mismatch',
                            style: GoogleFonts.inter(
                              fontSize: 10.sp,
                              color: const Color(0xFFEF4444),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ]),
                        SizedBox(height: 8.h),

                        // Per-document values
                        ...entries.map((dv) {
                          final isEmpty = dv['value'] == '—';
                          final valColor = isEmpty ? textSec : textPri;
                          return Padding(
                            padding: EdgeInsets.only(bottom: 5.h),
                            child: Row(children: [
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 7.w, vertical: 2.h),
                                decoration: BoxDecoration(
                                  color: card,
                                  borderRadius: BorderRadius.circular(4.r),
                                  border: Border.all(color: divClr),
                                ),
                                child: Text(
                                  dv['doc']!,
                                  style: GoogleFonts.inter(
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.w700,
                                    color: textSec,
                                  ),
                                ),
                              ),
                              SizedBox(width: 8.w),
                              Icon(
                                isEmpty
                                    ? Icons.remove_circle_outline
                                    : Icons.arrow_right_alt_rounded,
                                size: 14.sp,
                                color: textSec,
                              ),
                              SizedBox(width: 6.w),
                              Expanded(
                                child: Text(
                                  dv['value']!,
                                  style: GoogleFonts.inter(
                                    fontSize: 12.sp,
                                    fontWeight: isEmpty
                                        ? FontWeight.w400
                                        : FontWeight.w600,
                                    color: valColor,
                                    fontStyle: isEmpty
                                        ? FontStyle.italic
                                        : FontStyle.normal,
                                  ),
                                ),
                              ),
                            ]),
                          );
                        }),
                      ],
                    ),
                  );
                }),
              ],
            );
          }),
        ],
      ),
    );
  }

  String _hindiFieldLabel(String label) {
    switch (label) {
      case 'Name':         return 'नाम';
      case 'Date of Birth': return 'जन्म तिथि';
      case 'Gender':       return 'लिंग';
      case 'ID Number':    return 'आईडी नंबर';
      default:             return label;
    }
  }

  Widget _mismatchLegendDot(Color color) => Container(
        width: 8.w,
        height: 8.w,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );

  // ══════════════════════════════════════════════════════════════════════════
  //  SUMMARY CARD
  // ══════════════════════════════════════════════════════════════════════════
  Widget _summaryCard(String summary, Color card, Color divClr,
      Color textPri, Color textSec, bool isHindi) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: divClr),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tr('Summary', isHindi),
              style: GoogleFonts.inter(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w700,
                  color: textSec,
                  letterSpacing: 0.4)),
          SizedBox(height: 6.h),
          Text(summary,
              style: GoogleFonts.inter(
                  fontSize: 13.sp, color: textPri, height: 1.5)),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  SCANNED FILES STRIP
  // ══════════════════════════════════════════════════════════════════════════
  Widget _filesStrip(BuildContext context, List<String> imagePaths, Color divClr, Color card) {
    return SizedBox(
      height: 76.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: imagePaths.length,
        separatorBuilder: (_, __) => SizedBox(width: 8.w),
        itemBuilder: (ctx, i) {
          final path = imagePaths[i];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ImageViewerScreen(imagePath: path),
                ),
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6.r),
              child: Hero(
                tag: path,
                child: Image.file(
                  File(path),
                  width: 60.w,
                  height: 76.h,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 60.w,
                    height: 76.h,
                    decoration: BoxDecoration(
                        color: card,
                        borderRadius: BorderRadius.circular(6.r),
                        border: Border.all(color: divClr)),
                    child: Icon(Icons.description_outlined,
                        size: 24.sp, color: divClr),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  DOCUMENT CARD
  // ══════════════════════════════════════════════════════════════════════════
  Widget _docCard({
    required int index,
    required Map<String, dynamic> doc,
    required Color card,
    required Color divClr,
    required Color textPri,
    required Color textSec,
    required bool isHindi,
  }) {
    final docStatus  = doc['docStatus'] as String? ?? '';
    final isReal     = docStatus == 'REAL';
    final statusClr  = isReal ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    final docScore   = doc['fraudScore'] as int? ?? 0;
    final scoreClr   = _scoreColor(docScore);
    final docType    = doc['documentType'] as String? ?? 'Document ${index + 1}';
    final reasons    = List<String>.from(doc['reasons'] as List? ?? []);
    final ocr        = doc['ocrData'] as Map? ?? {};
    final ocrEntries = <String, String>{
      'Name':      ocr['name']     as String? ?? '',
      'DOB':       ocr['dob']      as String? ?? '',
      'Gender':    ocr['gender']   as String? ?? '',
      'ID Number': ocr['idNumber'] as String? ?? '',
    }..removeWhere((_, v) => v.isEmpty);

    return Container(
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: divClr),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Header ──────────────────────────────────────────────────────
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: divClr)),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
              // Index badge
              Container(
                width: 22.w, height: 22.w,
                decoration: BoxDecoration(
                  color: statusClr.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text('${index + 1}',
                      style: GoogleFonts.inter(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w800,
                          color: statusClr)),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(docType,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: GoogleFonts.inter(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w700,
                            color: textPri)),
                    Text(
                      isReal
                          ? tr('Genuine — No fraud detected', isHindi)
                          : tr('Fraud indicators found', isHindi),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: GoogleFonts.inter(
                          fontSize: 10.sp, color: statusClr),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 6.w),
              // Score + status badge
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 6.w, vertical: 3.h),
                    decoration: BoxDecoration(
                      color: statusClr.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(4.r),
                      border: Border.all(color: statusClr.withOpacity(0.3)),
                    ),
                    child: Text(docStatus,
                        style: GoogleFonts.inter(
                          fontSize: 9.sp,
                          fontWeight: FontWeight.w800,
                          color: statusClr,
                          letterSpacing: 0.3,
                        )),
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    '$docScore/100',
                    style: GoogleFonts.inter(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w700,
                        color: scoreClr),
                  ),
                ],
              ),
            ]),
          ),

          // ── Score bar ───────────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(tr('Risk Score', isHindi),
                        style: GoogleFonts.inter(
                            fontSize: 11.sp,
                            color: textSec,
                            fontWeight: FontWeight.w600)),
                    Text(_riskLabel(docScore),
                        style: GoogleFonts.inter(
                            fontSize: 11.sp,
                            color: scoreClr,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
                SizedBox(height: 6.h),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3.r),
                  child: LinearProgressIndicator(
                    value: docScore / 100,
                    minHeight: 6.h,
                    backgroundColor: scoreClr.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(scoreClr),
                  ),
                ),
              ],
            ),
          ),

          // ── OCR Data ────────────────────────────────────────────────────
          if (ocrEntries.isNotEmpty) ...[
            Padding(
              padding: EdgeInsets.fromLTRB(14.w, 14.h, 14.w, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tr('EXTRACTED DATA', isHindi),
                      style: GoogleFonts.inter(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w700,
                          color: textSec,
                          letterSpacing: 0.8)),
                  SizedBox(height: 8.h),
                  ...ocrEntries.entries.map((e) => Padding(
                    padding: EdgeInsets.only(bottom: 6.h),
                    child: Row(children: [
                      SizedBox(
                        width: 80.w,
                        child: Text(e.key,
                            style: GoogleFonts.inter(
                                fontSize: 11.sp, color: textSec)),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(e.value,
                            style: GoogleFonts.inter(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                                color: textPri)),
                      ),
                    ]),
                  )),
                ],
              ),
            ),
          ],

          // ── Reasons ─────────────────────────────────────────────────────
          if (reasons.isNotEmpty) ...[
            Divider(height: 1, color: divClr,
                indent: 14.w, endIndent: 14.w),
            Container(
              margin: EdgeInsets.fromLTRB(14.w, 10.h, 14.w, 14.h),
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withOpacity(0.05),
                borderRadius: BorderRadius.circular(6.r),
                border: Border.all(
                    color: const Color(0xFFEF4444).withOpacity(0.15)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(Icons.warning_amber_rounded,
                        size: 14.sp,
                        color: const Color(0xFFEF4444)),
                    SizedBox(width: 6.w),
                    Text(tr('Fraud Indicators', isHindi),
                        style: GoogleFonts.inter(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFEF4444))),
                  ]),
                  SizedBox(height: 8.h),
                  ...reasons.map((r) => Padding(
                    padding: EdgeInsets.only(bottom: 4.h),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(top: 4.h),
                          child: Container(
                            width: 5.w, height: 5.w,
                            decoration: const BoxDecoration(
                              color: Color(0xFFEF4444),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(r,
                              style: GoogleFonts.inter(
                                  fontSize: 12.sp, color: textPri,
                                  height: 1.4)),
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          ] else
            SizedBox(height: 14.h),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  ACTION ROW
  // ══════════════════════════════════════════════════════════════════════════
  Widget _actionRow(BuildContext context, Color textPri, Color textSec,
      ColorScheme cs, bool isHindi) {
    return Builder(builder: (ctx) {
      return LayoutBuilder(builder: (_, constraints) {
        // Stack vertically on very small widths, side-by-side otherwise
        final isNarrow = constraints.maxWidth < 320;
        if (isNarrow) {
          return Column(children: [
            _shareBtn(textPri, cs, isHindi),
            SizedBox(height: 8.h),
            Row(children: [
              Expanded(child: _pdfBtn(ctx, cs, isHindi)),
              SizedBox(width: 10.w),
              Expanded(child: _homeBtn(context, isHindi)),
            ]),
          ]);
        }
        return Row(children: [
          Expanded(child: _shareBtn(textPri, cs, isHindi)),
          SizedBox(width: 8.w),
          Expanded(child: _pdfBtn(ctx, cs, isHindi)),
          SizedBox(width: 8.w),
          Expanded(child: _homeBtn(context, isHindi)),
        ]);
      });
    });
  }

  Widget _shareBtn(Color textPri, ColorScheme cs, bool isHindi) =>
      OutlinedButton.icon(
        onPressed: () => Share.share(
            'Result: $_status | Score: $_score/100\nVerified via DocVerify'),
        icon: Icon(Icons.share_outlined, size: 15.sp),
        label: Text(tr('Share', isHindi),
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
                fontSize: 12.sp, fontWeight: FontWeight.w600)),
        style: OutlinedButton.styleFrom(
          foregroundColor: textPri,
          side: BorderSide(color: cs.onSurface.withOpacity(0.2)),
          padding: EdgeInsets.symmetric(vertical: 11.h, horizontal: 8.w),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.r)),
        ),
      );

  Widget _pdfBtn(BuildContext ctx, ColorScheme cs, bool isHindi) =>
      ElevatedButton.icon(
        onPressed: () => _generatePdf(ctx),
        icon: Icon(Icons.picture_as_pdf_outlined, size: 15.sp),
        label: Text(tr('PDF', isHindi),
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white)),
        style: ElevatedButton.styleFrom(
          backgroundColor: cs.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: EdgeInsets.symmetric(vertical: 11.h, horizontal: 8.w),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.r)),
        ),
      );

  Widget _homeBtn(BuildContext context, bool isHindi) =>
      ElevatedButton.icon(
        onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
        icon: Icon(Icons.home_outlined, size: 15.sp),
        label: Text(tr('Home', isHindi),
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white)),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1A2B47),
          foregroundColor: Colors.white,
          elevation: 0,
          padding: EdgeInsets.symmetric(vertical: 11.h, horizontal: 8.w),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.r)),
        ),
      );

  // ══════════════════════════════════════════════════════════════════════════
  //  HELPERS
  // ══════════════════════════════════════════════════════════════════════════
  Widget _sectionLabel(String text, Color textPri) {
    return Text(
      text.toUpperCase(),
      style: GoogleFonts.inter(
        fontSize: 11.sp,
        fontWeight: FontWeight.w700,
        color: textPri.withOpacity(0.45),
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _iconBtn(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.all(6.w),
        child: Icon(icon, size: 20.sp, color: color),
      ),
    );
  }
}
