import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'providers/document_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/theme_provider.dart';
import 'preview_screen.dart';
import 'utils/animations.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  UPLOAD SCREEN  — Minimal Government UI
// ─────────────────────────────────────────────────────────────────────────────
class UploadScreen extends StatelessWidget {
  const UploadScreen({super.key});

  void _showErr(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style: GoogleFonts.inter(color: Colors.white, fontSize: 13.sp)),
      backgroundColor: AppTheme.error,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6.r)),
      margin: EdgeInsets.all(16.w),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final doc      = Provider.of<DocumentProvider>(context);
    final settings = Provider.of<SettingsProvider>(context);
    final isHindi  = settings.isHindi;
    final theme    = Theme.of(context);
    final cs       = theme.colorScheme;
    final isDark   = theme.brightness == Brightness.dark;
    final textPri  = cs.onSurface;
    final textSec  = cs.onSurface.withOpacity(0.5);
    final divClr   = theme.dividerColor;
    final cardBg   = isDark ? const Color(0xFF1E2A3D) : Colors.white;
    final border   = isDark ? AppTheme.borderDark : AppTheme.borderLight;
    final hasFiles = doc.selectedFiles.isNotEmpty;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (doc.uploadError != null) {
        _showErr(context, doc.uploadError!);
        doc.clearError();
      }
    });

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF0D1526) : Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: divClr),
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back_rounded, color: textPri, size: 20.sp),
        ),
        title: Text(
          tr('Upload Documents', isHindi),
          style: GoogleFonts.inter(
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            color: textPri,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [

                  // ── Info banner ─────────────────────────────────────────
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 14.w, vertical: 12.h),
                    decoration: BoxDecoration(
                      color: cs.primary.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(
                          color: cs.primary.withOpacity(0.15)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline_rounded,
                            size: 15.sp,
                            color: cs.primary.withOpacity(0.7)),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: Text(
                            tr('Supported formats: JPG, PNG, PDF (max 10 MB per file)', isHindi),
                            style: GoogleFonts.inter(
                              fontSize: 12.sp,
                              color: cs.primary.withOpacity(0.85),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20.h),

                  // ── Upload options ─────────────────────────────────────
                  Text(
                    tr('Select Documents', isHindi),
                    style: GoogleFonts.inter(
                      fontSize: 12.5.sp,
                      fontWeight: FontWeight.w700,
                      color: textSec,
                      letterSpacing: 0.3,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Row(
                    children: [
                      _uploadBtn(
                        context: context,
                        icon: Icons.camera_alt_outlined,
                        label: tr('Take Photo', isHindi),
                        onTap: () => doc.takePhoto(),
                        cs: cs, isDark: isDark,
                        cardBg: cardBg, border: border,
                        textPri: textPri, textSec: textSec,
                      ),
                      SizedBox(width: 12.w),
                      _uploadBtn(
                        context: context,
                        icon: Icons.folder_open_outlined,
                        label: tr('Browse Files', isHindi),
                        onTap: () => doc.pickFiles(),
                        cs: cs, isDark: isDark,
                        cardBg: cardBg, border: border,
                        textPri: textPri, textSec: textSec,
                      ),
                    ],
                  ),
                  SizedBox(height: 28.h),

                  // ── Tips ───────────────────────────────────────────────
                  Text(
                    'Guidelines',
                    style: GoogleFonts.inter(
                      fontSize: 12.5.sp,
                      fontWeight: FontWeight.w700,
                      color: textSec,
                      letterSpacing: 0.3,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Container(
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(color: border),
                    ),
                    child: Column(
                      children: [
                        _guideRow('Ensure good lighting and clear focus', true, divClr, textPri, textSec),
                        _guideRow('Document must fully fit in frame', true, divClr, textPri, textSec),
                        _guideRow('Avoid reflections and shadows', true, divClr, textPri, textSec),
                        _guideRow('File size must not exceed 10 MB', false, divClr, textPri, textSec),
                      ],
                    ),
                  ),
                  SizedBox(height: 28.h),

                  // ── Selected files ─────────────────────────────────────
                  if (hasFiles) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          tr('Selected Files', isHindi),
                          style: GoogleFonts.inter(
                            fontSize: 12.5.sp,
                            fontWeight: FontWeight.w700,
                            color: textSec,
                            letterSpacing: 0.3,
                          ),
                        ),
                        Text(
                          '${doc.selectedFiles.length} file${doc.selectedFiles.length == 1 ? '' : 's'}',
                          style: GoogleFonts.inter(
                              fontSize: 12.sp,
                              color: cs.primary,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    SizedBox(height: 10.h),
                    Container(
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(color: border),
                      ),
                      child: Column(
                        children: List.generate(
                          doc.selectedFiles.length,
                          (i) {
                            final f     = doc.selectedFiles[i];
                            final isPdf = f.isPdf;
                            final kb    = (f.size / 1024).toStringAsFixed(1);
                            final isLast = i == doc.selectedFiles.length - 1;
                            return _fileRow(
                              name: f.name,
                              size: '$kb KB · ${isPdf ? 'PDF' : 'Image'}',
                              isPdf: isPdf,
                              onRemove: () => doc.removeFile(i),
                              divClr: divClr,
                              cs: cs,
                              textPri: textPri,
                              textSec: textSec,
                              isLast: isLast,
                            );
                          },
                        ),
                      ),
                    ),
                    SizedBox(height: 80.h),
                  ],
                ],
              ),
            ),
          ),

          // ── Bottom action ───────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0D1526) : Colors.white,
              border: Border(top: BorderSide(color: divClr)),
            ),
            padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 24.h),
            child: SafeArea(
              top: false,
              child: TapScale(
                onTap: hasFiles
                    ? () => Navigator.push(context,
                        FadeSlideRoute(page: const PreviewScreen()))
                    : null,
                child: SizedBox(
                  width: double.infinity,
                  height: 46.h,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          hasFiles ? cs.primary : cs.onSurface.withOpacity(0.12),
                      foregroundColor:
                          hasFiles ? Colors.white : textSec,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r)),
                    ),
                    onPressed: hasFiles
                        ? () => Navigator.push(context,
                            FadeSlideRoute(page: const PreviewScreen()))
                        : null,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          hasFiles
                              ? tr('Review & Continue', isHindi)
                              : tr('Select a document to continue', isHindi),
                          style: GoogleFonts.inter(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w700,
                            color: hasFiles ? Colors.white : textSec,
                          ),
                        ),
                        if (hasFiles) ...[
                          SizedBox(width: 8.w),
                          Icon(Icons.arrow_forward_rounded,
                              size: 16.sp, color: Colors.white),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _uploadBtn({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required ColorScheme cs,
    required bool isDark,
    required Color cardBg,
    required Color border,
    required Color textPri,
    required Color textSec,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8.r),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 24.h),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: border),
          ),
          child: Column(
            children: [
              Icon(icon, size: 26.sp, color: cs.primary),
              SizedBox(height: 10.h),
              Text(label,
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: textPri,
                  ),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  Widget _guideRow(String text, bool hasDivider, Color divClr,
      Color textPri, Color textSec) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 11.h),
          child: Row(
            children: [
              Icon(Icons.check_rounded,
                  size: 15.sp, color: AppTheme.success),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(text,
                    style: GoogleFonts.inter(
                        fontSize: 12.5.sp, color: textPri)),
              ),
            ],
          ),
        ),
        if (hasDivider) Divider(color: divClr, height: 1, indent: 38.w),
      ],
    );
  }

  Widget _fileRow({
    required String name,
    required String size,
    required bool isPdf,
    required VoidCallback onRemove,
    required Color divClr,
    required ColorScheme cs,
    required Color textPri,
    required Color textSec,
    required bool isLast,
  }) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 11.h),
          child: Row(
            children: [
              Icon(
                isPdf
                    ? Icons.picture_as_pdf_outlined
                    : Icons.image_outlined,
                size: 18.sp,
                color: isPdf ? AppTheme.error : cs.primary,
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: GoogleFonts.inter(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: textPri,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    SizedBox(height: 2.h),
                    Text(size,
                        style: GoogleFonts.inter(
                            fontSize: 11.sp, color: textSec)),
                  ],
                ),
              ),
              IconButton(
                onPressed: onRemove,
                icon: Icon(Icons.close_rounded,
                    size: 17.sp, color: textSec),
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(
                    minWidth: 28.w, minHeight: 28.w),
              ),
            ],
          ),
        ),
        if (!isLast) Divider(color: divClr, height: 1, indent: 42.w),
      ],
    );
  }
}
