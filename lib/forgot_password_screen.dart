import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'utils/animations.dart';
import 'providers/settings_provider.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Theme.of(context).colorScheme.error),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final settings = Provider.of<SettingsProvider>(context);
    final isHindi = settings.isHindi;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
      ),
      body: AnimatedGradientBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 24.0.w, vertical: 32.h),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 450),
                child: GlassContainer(
                  padding: EdgeInsets.all(32.w),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    StaggeredListItem(
                      index: 0,
                      child: Text(
                        tr('Reset Password', isHindi),
                        style: GoogleFonts.inter(
                          fontSize: 32.sp,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    StaggeredListItem(
                      index: 1,
                      child: Text(
                        tr('Enter your email address to receive a password reset link.', isHindi),
                        style: GoogleFonts.inter(fontSize: 16.sp, color: colorScheme.onSurface.withOpacity(0.54)),
                      ),
                    ),
                    SizedBox(height: 48.h),

                    StaggeredListItem(
                      index: 2,
                      child: TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: GoogleFonts.inter(color: colorScheme.onSurface),
                        decoration: InputDecoration(
                          labelText: tr('Email Address', isHindi),
                          labelStyle: GoogleFonts.inter(color: colorScheme.onSurface.withOpacity(0.54)),
                          prefixIcon: Icon(Icons.email_outlined, color: colorScheme.onSurface.withOpacity(0.54)),
                          filled: true,
                          fillColor: theme.cardColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16.r),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16.r),
                            borderSide: const BorderSide(color: Colors.transparent),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16.r),
                            borderSide: BorderSide(color: colorScheme.primary, width: 2.w),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 48.h),

                    StaggeredListItem(
                      index: 3,
                      child: AnimatedScaleButton(
                        onTap: authProvider.isLoading
                            ? () {}
                            : () async {
                                final success = await authProvider.resetPassword(
                                  _emailController.text.trim(),
                                );
                                if (success) {
                                  if (!mounted) return;
                                  _showSuccess("Password reset link sent!");
                                  Navigator.pop(context);
                                } else if (authProvider.errorMessage != null) {
                                  _showError(authProvider.errorMessage!);
                                }
                              },
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 16.h),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [colorScheme.primary, colorScheme.secondary],
                            ),
                            borderRadius: BorderRadius.circular(16.r),
                            boxShadow: [
                              BoxShadow(
                                color: colorScheme.primary.withOpacity(0.4),
                                blurRadius: 10.r,
                                offset: Offset(0, 4.h),
                              ),
                            ]
                          ),
                          alignment: Alignment.center,
                          child: authProvider.isLoading
                              ? SizedBox(
                                  height: 24.h,
                                  width: 24.w,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.w),
                                )
                              : Text(
                                  tr('Send Reset Link', isHindi),
                                  style: GoogleFonts.inter(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ), // Column
              ), // GlassContainer
            ), // ConstrainedBox
          ), // SingleChildScrollView
        ), // Center
      ), // SafeArea
    ), // AnimatedGradientBackground
  ); // Scaffold
  }
}

