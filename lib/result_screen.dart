import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'utils/animations.dart';
import 'providers/settings_provider.dart';
import 'providers/document_provider.dart';

class ResultScreen extends StatelessWidget {
  final Map<String, dynamic> resultData;

  const ResultScreen({super.key, required this.resultData});

  Future<void> _generatePdf(BuildContext context) async {
    final pdf = pw.Document();
    
    final bool isMatch = resultData['status'] == 'Match';
    final String dateStr = DateTime.now().toString().split(' ')[0];

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context pdfContext) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(level: 0, child: pw.Text('Identity Analysis Report - $dateStr', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900))),
              pw.SizedBox(height: 20),
              pw.Text('Overall Status: ${resultData['status']}', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: isMatch ? PdfColors.green600 : PdfColors.red600)),
              pw.SizedBox(height: 40),
              pw.Text('Detailed Field Comparisons', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.TableHelper.fromTextArray(
                context: pdfContext,
                headers: ['Field', 'Document 1', 'Document 2', 'Status'],
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
                cellHeight: 30,
                cellAlignments: {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.centerLeft,
                  2: pw.Alignment.centerLeft,
                  3: pw.Alignment.center,
                },
                data: List<List<String>>.generate(
                  resultData['comparisons'].length,
                  (index) {
                    final comp = resultData['comparisons'][index];
                    return [
                      comp['field'],
                      comp['doc1'],
                      comp['doc2'],
                      comp['status'],
                    ];
                  },
                ),
              ),
              pw.SizedBox(height: 40),
              pw.Text('Generated automatically by AntiGravity Verifier', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Verification_Report_$dateStr.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final isHindi = settings.isHindi;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    bool isMatch = resultData['status'] == 'Match';
    Color statusColor = isMatch ? Colors.green : colorScheme.error;
    IconData statusIcon = isMatch ? Icons.check_circle_outline : Icons.cancel_outlined;

    return PopScope(
      canPop: false, // Prevent physical back navigation into the processing buffer
      child: Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: theme.appBarTheme.backgroundColor ?? theme.scaffoldBackgroundColor,
            title: Text(tr('Analysis Report', isHindi), style: GoogleFonts.inter(color: theme.appBarTheme.foregroundColor ?? colorScheme.onSurface)),
            iconTheme: IconThemeData(color: theme.appBarTheme.foregroundColor ?? colorScheme.onSurface),
            automaticallyImplyLeading: false, 
          ),
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth > 800;

                // Shared Banner Content
                final statusBanner = TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOutBack,
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: 0.8 + (0.2 * value), // Scale from 0.8 to 1.0
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 32.h, horizontal: 16.w),
                        decoration: BoxDecoration(
                          color: Color.lerp(Colors.grey.withOpacity(0.1), statusColor.withOpacity(0.05), value),
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(
                            color: Color.lerp(Colors.grey.withOpacity(0.3), statusColor.withOpacity(0.3), value)!,
                            width: 2.w,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(statusIcon, size: 72.sp, color: Color.lerp(Colors.grey, statusColor, value)),
                            SizedBox(height: 16.h),
                            Text(
                              isMatch ? tr('Documents Match', isHindi) : tr('Mismatch Detected', isHindi),
                              style: GoogleFonts.inter(
                                fontSize: 26.sp,
                                fontWeight: FontWeight.bold,
                                color: Color.lerp(Colors.grey, statusColor, value),
                              ),
                            ),
                            SizedBox(height: 12.h),
                            Text(
                              isMatch 
                                  ? tr('All verified fields align properly.', isHindi) 
                                  : tr('We found discrepancies between the provided documents.', isHindi),
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(color: colorScheme.onSurface.withOpacity(0.7), fontSize: 16.sp),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );

                // Shared Actions Content
                final actionButtons = Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _generatePdf(context),
                      icon: Icon(Icons.download_rounded, color: colorScheme.onPrimary),
                      label: Text(tr('Download Report', isHindi), style: GoogleFonts.inter(fontSize: 16.sp, color: colorScheme.onPrimary, fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                      ),
                    ),
                    SizedBox(height: 16.h),
                    OutlinedButton(
                      onPressed: () {
                        // Navigate entirely back to the Dashboard
                        Navigator.popUntil(context, (route) => route.isFirst);
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: colorScheme.primary),
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                      ),
                      child: Text(tr('Back to Dashboard', isHindi), style: GoogleFonts.inter(fontSize: 16.sp, color: colorScheme.primary, fontWeight: FontWeight.w600)),
                    ),
                    SizedBox(height: 16.h),
                    TextButton(
                      onPressed: () {
                        Navigator.popUntil(context, (route) => route.isFirst);
                      },
                      child: Text(tr('Re-upload Documents', isHindi), style: GoogleFonts.inter(fontSize: 16.sp, color: colorScheme.onSurface.withOpacity(0.54))),
                    )
                  ],
                );

                // Shared Detailed Comparisons Content
                final detailedComparisons = Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      tr('Detailed Comparison', isHindi),
                      style: GoogleFonts.inter(fontSize: 20.sp, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                    ),
                    SizedBox(height: 16.h),
                    ...List.generate(resultData['comparisons'].length, (index) {
                      final comp = resultData['comparisons'][index];
                      return StaggeredListItem(
                        index: index,
                        child: _buildComparisonCard(
                          context: context,
                          field: comp['field'],
                          doc1Value: comp['doc1'],
                          doc2Value: comp['doc2'],
                          status: comp['status'],
                        ),
                      );
                    }),
                  ],
                );

                // Uploaded Images Preview
                final docProvider = Provider.of<DocumentProvider>(context, listen: false);
                final imagePreview = docProvider.selectedFiles.isEmpty
                    ? const SizedBox.shrink()
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            tr('Uploaded Documents', isHindi),
                            style: GoogleFonts.inter(fontSize: 20.sp, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                          ),
                          SizedBox(height: 16.h),
                          SizedBox(
                            height: 120.h,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: docProvider.selectedFiles.length,
                              separatorBuilder: (_, __) => SizedBox(width: 16.w),
                              itemBuilder: (context, index) {
                                final file = docProvider.selectedFiles[index];
                                return GestureDetector(
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      builder: (_) => Dialog(
                                        backgroundColor: Colors.transparent,
                                        insetPadding: EdgeInsets.zero,
                                        child: Stack(
                                          fit: StackFit.expand,
                                          children: [
                                            InteractiveViewer(
                                              minScale: 0.5,
                                              maxScale: 4.0,
                                              child: file.isPdf
                                                  ? Center(child: Icon(Icons.picture_as_pdf, size: 80.sp, color: Colors.white))
                                                  : Image.file(File(file.path), fit: BoxFit.contain),
                                            ),
                                            Positioned(
                                              top: 40.h,
                                              right: 20.w,
                                              child: IconButton(
                                                icon: Icon(Icons.close, color: Colors.white, size: 30.sp),
                                                onPressed: () => Navigator.pop(context),
                                              ),
                                            )
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    width: 100.w,
                                    decoration: BoxDecoration(
                                      color: theme.cardColor,
                                      borderRadius: BorderRadius.circular(12.r),
                                      border: Border.all(color: colorScheme.primary.withOpacity(0.3)),
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: file.isPdf
                                        ? Center(child: Icon(Icons.picture_as_pdf, color: colorScheme.primary, size: 40.sp))
                                        : Image.file(File(file.path), fit: BoxFit.cover),
                                  ),
                                );
                              },
                            ),
                          ),
                          SizedBox(height: 40.h),
                        ],
                      );

                final int fraudScore = resultData['fraudScore'] ?? 0;

                if (isDesktop) {
                  return Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: 1200),
                      child: Padding(
                        padding: EdgeInsets.all(32.0.w),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 1,
                              child: SingleChildScrollView(
                                child: Column(
                                  children: [
                                    statusBanner,
                                    SizedBox(height: 24.h),
                                    _buildFraudMeter(context, fraudScore),
                                    SizedBox(height: 40.h),
                                    actionButtons,
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(width: 40.w),
                            Expanded(
                              flex: 2,
                              child: SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    imagePreview,
                                    detailedComparisons,
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                return SingleChildScrollView(
                  padding: EdgeInsets.all(24.0.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      statusBanner,
                      SizedBox(height: 32.h),
                      _buildFraudMeter(context, fraudScore),
                      SizedBox(height: 40.h),
                      imagePreview,
                      detailedComparisons,
                      SizedBox(height: 48.h),
                      actionButtons,
                    ],
                  ),
                );
              },
            ),
          ),
      ),
    );
  }

  Widget _buildFraudMeter(BuildContext context, int score) {
    final settings = Provider.of<SettingsProvider>(context);
    final isHindi = settings.isHindi;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    Color meterColor;
    String meterLabel;
    if (score <= 30) {
      meterColor = Colors.green;
      meterLabel = 'Low Risk';
    } else if (score <= 70) {
      meterColor = Colors.yellow.shade700;
      meterLabel = 'Medium Risk';
    } else {
      meterColor = colorScheme.error;
      meterLabel = 'High Risk';
    }

    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: colorScheme.onSurface.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Text(
            tr('Fraud Risk Score', isHindi),
            style: GoogleFonts.inter(fontSize: 18.sp, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
          ),
          SizedBox(height: 24.h),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 120.w,
                height: 120.w,
                child: CircularProgressIndicator(
                  value: score / 100,
                  strokeWidth: 12.w,
                  backgroundColor: colorScheme.onSurface.withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(meterColor),
                ),
              ),
              Column(
                children: [
                  Text(
                    '$score%',
                    style: GoogleFonts.inter(fontSize: 28.sp, fontWeight: FontWeight.bold, color: meterColor),
                  ),
                  Text(
                    tr(meterLabel, isHindi),
                    style: GoogleFonts.inter(fontSize: 12.sp, fontWeight: FontWeight.w600, color: meterColor),
                  ),
                ],
              )
            ],
          )
        ],
      ),
    );
  }

  void _showCardOptions(BuildContext context, String field, String doc1Value, String doc2Value, String status) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isHindi = Provider.of<SettingsProvider>(context, listen: false).isHindi;
    final String textToCopy = 'Field: $field\nDocument 1: $doc1Value\nDocument 2: $doc2Value\nStatus: $status';

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24.r))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 24.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(tr('Comparison Options', isHindi), style: GoogleFonts.inter(fontSize: 18.sp, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
              SizedBox(height: 16.h),
              ListTile(
                leading: Icon(Icons.copy_rounded, color: colorScheme.primary),
                title: Text(tr('Copy Details', isHindi), style: GoogleFonts.inter(color: colorScheme.onSurface)),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: textToCopy));
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(tr('Copied to clipboard!', isHindi)),
                    backgroundColor: Colors.green,
                  ));
                },
              ),
              ListTile(
                leading: Icon(Icons.share_rounded, color: colorScheme.primary),
                title: Text(tr('Share', isHindi), style: GoogleFonts.inter(color: colorScheme.onSurface)),
                onTap: () {
                  Navigator.pop(ctx);
                  Share.share(textToCopy);
                },
              ),
              ListTile(
                leading: Icon(Icons.bookmark_border_rounded, color: colorScheme.primary),
                title: Text(tr('Save Field', isHindi), style: GoogleFonts.inter(color: colorScheme.onSurface)),
                onTap: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(tr('Field saved for reference.', isHindi)),
                    backgroundColor: colorScheme.primary,
                  ));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildComparisonCard({required BuildContext context, required String field, required String doc1Value, required String doc2Value, required String status}) {
    final settings = Provider.of<SettingsProvider>(context);
    final isHindi = settings.isHindi;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    Color badgeColor;
    if (status == 'Match') badgeColor = Colors.green;
    else if (status == 'Partial') badgeColor = Colors.yellow.shade700;
    else badgeColor = colorScheme.error;

    return GestureDetector(
      onLongPress: () {
        HapticFeedback.lightImpact();
        _showCardOptions(context, field, doc1Value, doc2Value, status);
      },
      child: Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  field,
                  style: GoogleFonts.inter(fontSize: 16.sp, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                ),
              ),
              SizedBox(width: 8.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: badgeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: badgeColor.withOpacity(0.5)),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: GoogleFonts.inter(fontSize: 12.sp, fontWeight: FontWeight.bold, color: badgeColor, letterSpacing: 0.5),
                ),
              )
            ],
          ),
          SizedBox(height: 20.h),
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tr('DOCUMENT 1', isHindi), style: GoogleFonts.inter(fontSize: 11.sp, color: colorScheme.onSurface.withOpacity(0.54), letterSpacing: 1.0, fontWeight: FontWeight.bold)),
                      SizedBox(height: 6.h),
                      Text(doc1Value, style: GoogleFonts.inter(fontSize: 14.sp, color: colorScheme.onSurface, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                VerticalDivider(
                  width: 32.w,
                  thickness: 1.w,
                  color: colorScheme.onSurface.withOpacity(0.24),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tr('DOCUMENT 2', isHindi), style: GoogleFonts.inter(fontSize: 11.sp, color: colorScheme.onSurface.withOpacity(0.54), letterSpacing: 1.0, fontWeight: FontWeight.bold)),
                      SizedBox(height: 6.h),
                      Text(doc2Value, style: GoogleFonts.inter(fontSize: 14.sp, color: colorScheme.onSurface, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ],
            ),
          )
        ],
      ),
      ),
    );
  }
}
