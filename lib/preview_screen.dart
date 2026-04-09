import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'providers/document_provider.dart';
import 'processing_screen.dart';
import 'providers/settings_provider.dart';
import 'utils/animations.dart';

class PreviewScreen extends StatelessWidget {
  const PreviewScreen({super.key});

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text(message, style: GoogleFonts.inter(color: Colors.white))),
          ],
        ),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        margin: EdgeInsets.all(16.w),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final docProvider = Provider.of<DocumentProvider>(context);
    final settings = Provider.of<SettingsProvider>(context);
    final isHindi = settings.isHindi;

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final textColor = colorScheme.onSurface;
    final textDimColor = colorScheme.onSurface.withOpacity(0.52);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: colorScheme.onSurface.withOpacity(0.06),
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: colorScheme.onSurface.withOpacity(0.08)),
            ),
            child: Icon(Icons.arrow_back_ios_new_rounded, color: textColor, size: 15.sp),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          tr('Preview Selection', isHindi),
          style: GoogleFonts.inter(color: textColor, fontWeight: FontWeight.w700, fontSize: 18.sp),
        ),
      ),
      body: SafeArea(
        child: docProvider.isUploading
            ? _buildUploadingState(colorScheme, isDark, textColor, textDimColor, isHindi)
            : Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Info bar
                          StaggeredListItem(
                            index: 0,
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    colorScheme.primary.withOpacity(isDark ? 0.12 : 0.07),
                                    colorScheme.secondary.withOpacity(isDark ? 0.08 : 0.04),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(14.r),
                                border: Border.all(color: colorScheme.primary.withOpacity(0.15)),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.info_outline_rounded,
                                      color: colorScheme.primary, size: 18.sp),
                                  SizedBox(width: 10.w),
                                  Expanded(
                                    child: Text(
                                      '${docProvider.selectedFiles.length} ${tr("document(s) ready for analysis", isHindi)}',
                                      style: GoogleFonts.inter(
                                        fontSize: 13.sp,
                                        fontWeight: FontWeight.w600,
                                        color: colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 20.h),

                          // File list
                          ...List.generate(docProvider.selectedFiles.length, (index) {
                            final file = docProvider.selectedFiles[index];
                            final kbSize = (file.size / 1024).toStringAsFixed(1);
                            final isPdf = file.isPdf;

                            return StaggeredListItem(
                              index: index + 1,
                              child: Padding(
                                padding: EdgeInsets.only(bottom: 12.h),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: theme.cardColor,
                                    borderRadius: BorderRadius.circular(20.r),
                                    border: Border.all(
                                        color: colorScheme.primary.withOpacity(0.1)),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black
                                            .withOpacity(isDark ? 0.15 : 0.04),
                                        blurRadius: 10.r,
                                        offset: Offset(0, 3.h),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      // Image preview area (only for images)
                                      if (!isPdf)
                                        ClipRRect(
                                          borderRadius: BorderRadius.vertical(
                                            top: Radius.circular(20.r),
                                          ),
                                          child: SizedBox(
                                            height: 160.h,
                                            child: Image.file(
                                              File(file.path),
                                              fit: BoxFit.cover,
                                              errorBuilder: (ctx, err, stack) => Container(
                                                color: colorScheme.primary.withOpacity(0.05),
                                                child: Icon(Icons.image_rounded,
                                                    color: colorScheme.primary, size: 48.sp),
                                              ),
                                            ),
                                          ),
                                        )
                                      else
                                        Container(
                                          height: 120.h,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFEF4444).withOpacity(0.07),
                                            borderRadius: BorderRadius.vertical(
                                              top: Radius.circular(20.r),
                                            ),
                                          ),
                                          child: Center(
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.picture_as_pdf_rounded,
                                                    color: const Color(0xFFEF4444),
                                                    size: 40.sp),
                                                SizedBox(height: 6.h),
                                                Text(
                                                  tr('PDF Document', isHindi),
                                                  style: GoogleFonts.inter(
                                                    fontSize: 12.sp,
                                                    color: const Color(0xFFEF4444)
                                                        .withOpacity(0.7),
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),

                                      // File info row
                                      Padding(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 14.w, vertical: 12.h),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    file.name,
                                                    style: GoogleFonts.inter(
                                                      fontSize: 13.sp,
                                                      fontWeight: FontWeight.w700,
                                                      color: textColor,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  SizedBox(height: 3.h),
                                                  Text(
                                                    '$kbSize KB • ${isPdf ? 'PDF' : 'Image'}',
                                                    style: GoogleFonts.inter(
                                                      fontSize: 11.sp,
                                                      color: textDimColor,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            // Remove button
                                            GestureDetector(
                                              onTap: () => docProvider.removeFile(index),
                                              child: Container(
                                                padding: EdgeInsets.symmetric(
                                                    horizontal: 10.w, vertical: 6.h),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFEF4444)
                                                      .withOpacity(0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(8.r),
                                                  border: Border.all(
                                                    color: const Color(0xFFEF4444)
                                                        .withOpacity(0.2),
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(Icons.delete_rounded,
                                                        color: const Color(0xFFEF4444),
                                                        size: 14.sp),
                                                    SizedBox(width: 4.w),
                                                    Text(
                                                      tr('Remove', isHindi),
                                                      style: GoogleFonts.inter(
                                                        fontSize: 11.sp,
                                                        fontWeight: FontWeight.w600,
                                                        color: const Color(0xFFEF4444),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                          SizedBox(height: 100.h),
                        ],
                      ),
                    ),
                  ),

                  // Bottom Action Bar
                  Container(
                    padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 20.h),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F0E1A) : Colors.white,
                      border:
                          Border(top: BorderSide(color: colorScheme.onSurface.withOpacity(0.07))),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
                          blurRadius: 16.r,
                          offset: Offset(0, -4.h),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      top: false,
                      child: Row(
                        children: [
                          // Add More
                          AnimatedScaleButton(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 20.w, vertical: 16.h),
                              decoration: BoxDecoration(
                                border: Border.all(
                                    color: colorScheme.primary.withOpacity(0.4),
                                    width: 1.5.w),
                                borderRadius: BorderRadius.circular(16.r),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.add_rounded,
                                      color: colorScheme.primary, size: 18.sp),
                                  SizedBox(width: 6.w),
                                  Text(
                                    tr('Add More', isHindi),
                                    style: GoogleFonts.inter(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w700,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(width: 12.w),

                          // Continue Button
                          Expanded(
                            child: AnimatedScaleButton(
                              onTap: () {
                                // Navigate to ProcessingScreen — the API call
                                // happens inside ProcessingScreen._startAnalysis()
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const ProcessingScreen(docId: ''),
                                  ),
                                );
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(vertical: 16.h),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [colorScheme.primary, colorScheme.secondary],
                                  ),
                                  borderRadius: BorderRadius.circular(16.r),
                                  boxShadow: [
                                    BoxShadow(
                                      color: colorScheme.primary.withOpacity(0.4),
                                      blurRadius: 16.r,
                                      offset: Offset(0, 6.h),
                                      spreadRadius: -2,
                                    ),
                                  ],
                                ),
                                alignment: Alignment.center,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.analytics_rounded,
                                        color: Colors.white, size: 18.sp),
                                    SizedBox(width: 8.w),
                                    Text(
                                      tr('Continue', isHindi),
                                      style: GoogleFonts.inter(
                                        fontSize: 15.sp,
                                        fontWeight: FontWeight.w700,
                                        color: colorScheme.onPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildUploadingState(ColorScheme colorScheme, bool isDark, Color textColor,
      Color textDimColor, bool isHindi) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 40.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            PulseGlow(
              color: colorScheme.primary,
              radius: 40,
              child: Container(
                width: 80.w,
                height: 80.w,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [colorScheme.primary, colorScheme.secondary],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.cloud_upload_rounded, color: Colors.white, size: 36.sp),
              ),
            ),
            SizedBox(height: 32.h),
            Text(
              tr('Uploading files to server...', isHindi),
              style: GoogleFonts.inter(
                  color: textColor, fontSize: 18.sp, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8.h),
            Text(
              tr('Please wait, this may take a moment', isHindi),
              style: GoogleFonts.inter(color: textDimColor, fontSize: 13.sp),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32.h),
            Container(
              height: 4.h,
              decoration: BoxDecoration(
                color: colorScheme.onSurface.withOpacity(0.08),
                borderRadius: BorderRadius.circular(2.r),
              ),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(seconds: 3),
                builder: (context, value, child) {
                  return FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: value,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [colorScheme.primary, colorScheme.secondary],
                        ),
                        borderRadius: BorderRadius.circular(2.r),
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.primary.withOpacity(0.5),
                            blurRadius: 6.r,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
