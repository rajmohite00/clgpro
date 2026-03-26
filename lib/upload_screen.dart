import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'providers/document_provider.dart';
import 'providers/settings_provider.dart';
import 'preview_screen.dart';
import 'utils/animations.dart';

class UploadScreen extends StatelessWidget {
  const UploadScreen({super.key});

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (docProvider.uploadError != null) {
        _showError(context, docProvider.uploadError!);
        docProvider.clearError();
      }
    });

    final hasFiles = docProvider.selectedFiles.isNotEmpty;

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
          tr('Upload Documents', isHindi),
          style: GoogleFonts.inter(color: textColor, fontWeight: FontWeight.w700, fontSize: 18.sp),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Section
                    StaggeredListItem(
                      index: 0,
                      child: Container(
                        padding: EdgeInsets.all(20.w),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              colorScheme.primary.withOpacity(isDark ? 0.15 : 0.08),
                              colorScheme.secondary.withOpacity(isDark ? 0.1 : 0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20.r),
                          border: Border.all(color: colorScheme.primary.withOpacity(0.15)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(14.w),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [colorScheme.primary, colorScheme.secondary],
                                ),
                                borderRadius: BorderRadius.circular(16.r),
                                boxShadow: [
                                  BoxShadow(
                                    color: colorScheme.primary.withOpacity(0.35),
                                    blurRadius: 12.r,
                                    offset: Offset(0, 4.h),
                                  ),
                                ],
                              ),
                              child: Icon(Icons.document_scanner_rounded, color: Colors.white, size: 24.sp),
                            ),
                            SizedBox(width: 16.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tr('Select Documents', isHindi),
                                    style: GoogleFonts.inter(
                                      fontSize: 18.sp,
                                      fontWeight: FontWeight.w800,
                                      color: textColor,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  SizedBox(height: 4.h),
                                  Text(
                                    tr('Add images or PDFs (max 10MB per file)', isHindi),
                                    style: GoogleFonts.inter(fontSize: 12.sp, color: textDimColor),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 24.h),

                    // Upload Options
                    StaggeredListItem(
                      index: 1,
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildUploadOption(
                              context: context,
                              icon: Icons.camera_alt_rounded,
                              label: tr('Take Photo', isHindi),
                              subtitle: 'Camera',
                              accentColor: const Color(0xFF6366F1),
                              isDark: isDark,
                              onTap: () => docProvider.takePhoto(),
                            ),
                          ),
                          SizedBox(width: 14.w),
                          Expanded(
                            child: _buildUploadOption(
                              context: context,
                              icon: Icons.folder_open_rounded,
                              label: tr('Select Files', isHindi),
                              subtitle: 'Gallery / Files',
                              accentColor: const Color(0xFF8B5CF6),
                              isDark: isDark,
                              onTap: () => docProvider.pickFiles(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 28.h),

                    // Tips section
                    StaggeredListItem(
                      index: 2,
                      child: Container(
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(color: colorScheme.onSurface.withOpacity(0.06)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.tips_and_updates_rounded,
                                    color: const Color(0xFFF59E0B), size: 16.sp),
                                SizedBox(width: 8.w),
                                Text(
                                  'Tips for best results',
                                  style: GoogleFonts.inter(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFFF59E0B),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 10.h),
                            ...[
                              'Ensure good lighting and sharp focus',
                              'Documents must be clearly visible',
                              'Supported: JPG, PNG, PDF (max 10MB)',
                            ].map((tip) => Padding(
                                  padding: EdgeInsets.only(bottom: 6.h),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        margin: EdgeInsets.only(top: 5.h),
                                        width: 5.w,
                                        height: 5.w,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: textDimColor.withOpacity(0.5),
                                        ),
                                      ),
                                      SizedBox(width: 8.w),
                                      Expanded(
                                        child: Text(
                                          tip,
                                          style: GoogleFonts.inter(fontSize: 12.sp, color: textDimColor),
                                        ),
                                      ),
                                    ],
                                  ),
                                )),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 24.h),

                    // Selected Files Section
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 350),
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
                        child: SlideTransition(
                          position: Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
                              .animate(animation),
                          child: child,
                        ),
                      ),
                      child: hasFiles
                          ? Column(
                              key: const ValueKey('files_list'),
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      tr('Selected Files', isHindi),
                                      style: GoogleFonts.inter(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.w700,
                                        color: textColor,
                                      ),
                                    ),
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [colorScheme.primary, colorScheme.secondary],
                                        ),
                                        borderRadius: BorderRadius.circular(20.r),
                                      ),
                                      child: Text(
                                        '${docProvider.selectedFiles.length} file${docProvider.selectedFiles.length == 1 ? '' : 's'}',
                                        style: GoogleFonts.inter(
                                          fontSize: 12.sp,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 12.h),
                                ...List.generate(docProvider.selectedFiles.length, (index) {
                                  final file = docProvider.selectedFiles[index];
                                  final kbSize = (file.size / 1024).toStringAsFixed(1);
                                  final isPdf = file.isPdf;
                                  return Padding(
                                    padding: EdgeInsets.only(bottom: 10.h),
                                    child: Container(
                                      padding: EdgeInsets.all(14.w),
                                      decoration: BoxDecoration(
                                        color: theme.cardColor,
                                        borderRadius: BorderRadius.circular(16.r),
                                        border: Border.all(
                                          color: colorScheme.primary.withOpacity(0.12),
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(isDark ? 0.15 : 0.03),
                                            blurRadius: 8.r,
                                            offset: Offset(0, 2.h),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 46.w,
                                            height: 46.w,
                                            decoration: BoxDecoration(
                                              color: (isPdf ? const Color(0xFFEF4444) : colorScheme.primary)
                                                  .withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(12.r),
                                            ),
                                            child: Icon(
                                              isPdf ? Icons.picture_as_pdf_rounded : Icons.image_rounded,
                                              color: isPdf ? const Color(0xFFEF4444) : colorScheme.primary,
                                              size: 22.sp,
                                            ),
                                          ),
                                          SizedBox(width: 12.w),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  file.name,
                                                  style: GoogleFonts.inter(
                                                    fontSize: 13.sp,
                                                    fontWeight: FontWeight.w600,
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
                                          IconButton(
                                            onPressed: () => docProvider.removeFile(index),
                                            icon: Container(
                                              padding: EdgeInsets.all(6.w),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFEF4444).withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(8.r),
                                              ),
                                              child: Icon(
                                                Icons.delete_rounded,
                                                color: const Color(0xFFEF4444),
                                                size: 16.sp,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }),
                              ],
                            )
                          : const SizedBox.shrink(key: ValueKey('empty')),
                    ),
                    SizedBox(height: 100.h),
                  ],
                ),
              ),
            ),

            // Bottom Action
            Container(
              padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 24.h),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F0E1A) : Colors.white,
                border: Border(
                  top: BorderSide(color: colorScheme.onSurface.withOpacity(0.07)),
                ),
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
                child: AnimatedScaleButton(
                  onTap: hasFiles
                      ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const PreviewScreen()),
                          );
                        }
                      : () {},
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 18.h),
                    decoration: BoxDecoration(
                      gradient: hasFiles
                          ? LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [colorScheme.primary, colorScheme.secondary],
                            )
                          : null,
                      color: hasFiles ? null : colorScheme.onSurface.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(18.r),
                      boxShadow: hasFiles
                          ? [
                              BoxShadow(
                                color: colorScheme.primary.withOpacity(0.4),
                                blurRadius: 20.r,
                                offset: Offset(0, 8.h),
                                spreadRadius: -2,
                              ),
                            ]
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: hasFiles ? Colors.white : textDimColor,
                          size: 18.sp,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          tr('Next', isHindi),
                          style: GoogleFonts.inter(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w700,
                            color: hasFiles ? Colors.white : textDimColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadOption({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String subtitle,
    required Color accentColor,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return AnimatedScaleButton(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 32.h, horizontal: 16.w),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: accentColor.withOpacity(0.2),
            width: 1.5.w,
          ),
          boxShadow: [
            BoxShadow(
              color: accentColor.withOpacity(isDark ? 0.12 : 0.06),
              blurRadius: 16.r,
              offset: Offset(0, 4.h),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(18.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [accentColor, accentColor.withBlue(255)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withOpacity(0.4),
                    blurRadius: 16.r,
                    offset: Offset(0, 4.h),
                  ),
                ],
              ),
              child: Icon(icon, size: 28.sp, color: Colors.white),
            ),
            SizedBox(height: 14.h),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4.h),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 11.sp,
                color: theme.colorScheme.onSurface.withOpacity(0.45),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
