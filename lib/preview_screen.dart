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

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(tr('Preview Selection', isHindi), style: GoogleFonts.inter(color: theme.appBarTheme.foregroundColor ?? colorScheme.onSurface)),
        backgroundColor: theme.appBarTheme.backgroundColor ?? theme.scaffoldBackgroundColor,
        iconTheme: IconThemeData(color: theme.appBarTheme.foregroundColor ?? colorScheme.onSurface),
      ),
      body: SafeArea(
        child: docProvider.isUploading
            ? Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 48.0.w),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(seconds: 2),
                        builder: (context, value, child) {
                          return LinearProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                            backgroundColor: theme.disabledColor.withOpacity(0.1),
                            borderRadius: BorderRadius.all(Radius.circular(8.r)),
                            minHeight: 6,
                          );
                        },
                      ),
                      SizedBox(height: 24.h),
                      Text(
                        tr('Uploading files to server...', isHindi),
                        style: GoogleFonts.inter(color: colorScheme.onSurface, fontSize: 16.sp),
                      ),
                    ],
                  ),
                ),
              )
            : Padding(
                padding: EdgeInsets.all(24.0.w),
                child: Column(
                  children: [
                    Expanded(
                      child: ListView.separated(
                        itemCount: docProvider.selectedFiles.length,
                        separatorBuilder: (_, __) => SizedBox(height: 16.h),
                        itemBuilder: (context, index) {
                          final file = docProvider.selectedFiles[index];
                          final kbSize = (file.size / 1024).toStringAsFixed(1);
                          return StaggeredListItem(
                            index: index,
                            child: Container(
                              decoration: BoxDecoration(
                                color: theme.cardColor,
                                borderRadius: BorderRadius.circular(16.r),
                              ),
                              child: ListTile(
                                contentPadding: EdgeInsets.all(12.w),
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(8.r),
                                child: Container(
                                  width: 50.w,
                                  height: 50.h,
                                  color: theme.dividerColor.withOpacity(0.1),
                                  child: file.isPdf
                                      ? Icon(Icons.picture_as_pdf, color: colorScheme.error)
                                      : Image.file(
                                          File(file.path),
                                          fit: BoxFit.cover,
                                          errorBuilder: (ctx, err, stack) => Icon(Icons.image, color: colorScheme.primary),
                                        ),
                                ),
                              ),
                              title: Text(
                                file.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  color: colorScheme.onSurface,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              subtitle: Text(
                                '$kbSize KB',
                                style: GoogleFonts.inter(color: colorScheme.onSurface.withOpacity(0.54)),
                              ),
                              trailing: IconButton(
                                icon: Icon(Icons.delete_outline, color: colorScheme.error),
                                onPressed: () => docProvider.removeFile(index),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    ),
                    SizedBox(height: 24.h),
                    
                    // Buttons
                    Row(
                      children: [
                        Expanded(
                          child: AnimatedScaleButton(
                            onTap: () {
                              Navigator.pop(context); // Go back to add more
                            },
                            child: Container(
                              alignment: Alignment.center,
                              padding: EdgeInsets.symmetric(vertical: 16.h),
                              decoration: BoxDecoration(
                                border: Border.all(color: colorScheme.primary),
                                borderRadius: BorderRadius.circular(16.r),
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  tr('Add More', isHindi),
                                  style: GoogleFonts.inter(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.primary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 16.w),
                        Expanded(
                          child: AnimatedScaleButton(
                            onTap: () async {
                              debugPrint('[Upload API] Initiating document upload process...');
                              final docId = await docProvider.uploadDocuments();
                              debugPrint('[Upload API Response] docId: $docId');
                              
                              if (docId != null) {
                                debugPrint('[Navigation Trigger] Proceeding to ProcessingScreen dynamically.');
                                if (!context.mounted) return;
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ProcessingScreen(docId: docId),
                                  ),
                                );
                              } else if (docProvider.uploadError != null) {
                                debugPrint('[Upload API Error] Encountered error: ${docProvider.uploadError}');
                                if (!context.mounted) return;
                                _showError(context, docProvider.uploadError!);
                              }
                            },
                            child: Container(
                              alignment: Alignment.center,
                              padding: EdgeInsets.symmetric(vertical: 16.h),
                              decoration: BoxDecoration(
                                color: colorScheme.primary,
                                borderRadius: BorderRadius.circular(16.r),
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  tr('Continue', isHindi),
                                  style: GoogleFonts.inter(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.onPrimary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
