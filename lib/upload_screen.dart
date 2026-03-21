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
      SnackBar(content: Text(message), backgroundColor: Theme.of(context).colorScheme.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    final docProvider = Provider.of<DocumentProvider>(context);
    final settings = Provider.of<SettingsProvider>(context);
    final isHindi = settings.isHindi;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Show error if exists
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (docProvider.uploadError != null) {
        _showError(context, docProvider.uploadError!);
        docProvider.clearError();
      }
    });

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(tr('Upload Documents', isHindi), style: GoogleFonts.inter(color: theme.appBarTheme.foregroundColor ?? colorScheme.onSurface)),
        backgroundColor: theme.appBarTheme.backgroundColor ?? theme.scaffoldBackgroundColor,
        iconTheme: IconThemeData(color: theme.appBarTheme.foregroundColor ?? colorScheme.onSurface),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24.0.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                tr('Select Documents', isHindi),
                style: GoogleFonts.inter(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                tr('Add images or PDFs (max 10MB per file)', isHindi),
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  color: colorScheme.onSurface.withOpacity(0.54),
                ),
              ),
              SizedBox(height: 32.h),

              // Upload Cards
              Row(
                children: [
                  Expanded(
                    child: _buildUploadOption(
                      context: context,
                      icon: Icons.camera_alt_outlined,
                      label: tr('Take Photo', isHindi),
                      onTap: () => docProvider.takePhoto(),
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: _buildUploadOption(
                      context: context,
                      icon: Icons.folder_open_outlined,
                      label: tr('Select Files', isHindi),
                      onTap: () => docProvider.pickFiles(),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 48.h),

              // Selected Count indicator
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(scale: animation, child: child),
                  );
                },
                child: docProvider.selectedFiles.isEmpty
                    ? const SizedBox.shrink()
                    : Container(
                        key: const ValueKey('count_container'),
                        padding: EdgeInsets.symmetric(vertical: 24.h, horizontal: 16.w),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(color: theme.disabledColor.withOpacity(0.1)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.file_copy_outlined, color: colorScheme.primary),
                                SizedBox(width: 12.w),
                                Text(
                                  tr('Selected Files', isHindi),
                                  style: GoogleFonts.inter(
                                    fontSize: 16.sp,
                                    color: colorScheme.onSurface,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                              decoration: BoxDecoration(
                                color: colorScheme.primary.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: Text(
                                '${docProvider.selectedFiles.length}',
                                style: GoogleFonts.inter(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),

              const Spacer(),

              // Next Button
              AnimatedScaleButton(
                onTap: docProvider.selectedFiles.isEmpty
                    ? () {} // Disabled handled below visually, but AnimatedScaleButton wants a non-null callback or we can give null
                    : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const PreviewScreen()),
                        );
                      },
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  decoration: BoxDecoration(
                    color: docProvider.selectedFiles.isEmpty ? theme.disabledColor.withOpacity(0.5) : colorScheme.primary,
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    tr('Next', isHindi),
                    style: GoogleFonts.inter(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: docProvider.selectedFiles.isEmpty ? colorScheme.onSurface.withOpacity(0.54) : colorScheme.onPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUploadOption({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return InteractiveCard(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 40.h),
        decoration: BoxDecoration(
          color: theme.cardColor.withOpacity(0.6),
          border: Border.all(color: colorScheme.primary.withOpacity(0.5)),
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Column(
          children: [
            Icon(icon, size: 40.sp, color: colorScheme.primary),
            SizedBox(height: 16.h),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
