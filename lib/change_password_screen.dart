import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'providers/user_provider.dart';
import 'providers/settings_provider.dart';
import 'utils/animations.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});
  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _currentPassController = TextEditingController();
  final _newPassController = TextEditingController();
  final _confirmPassController = TextEditingController();

  bool _showCurrent = false;
  bool _showNew = false;
  bool _showConfirm = false;

  @override
  void dispose() {
    _currentPassController.dispose();
    _newPassController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  void _showSnackbar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(isError ? Icons.error_outline : Icons.check_circle_outline,
                color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Expanded(child: Text(msg, style: GoogleFonts.inter(color: Colors.white))),
          ],
        ),
        backgroundColor:
            isError ? const Color(0xFFEF4444) : const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        margin: EdgeInsets.all(16.w),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
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
          tr('Change Password', isHindi),
          style: GoogleFonts.inter(
              color: textColor, fontWeight: FontWeight.w700, fontSize: 18.sp),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header card
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
                    border:
                        Border.all(color: colorScheme.primary.withOpacity(0.15)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(14.w),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [colorScheme.primary, colorScheme.secondary],
                          ),
                          borderRadius: BorderRadius.circular(14.r),
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.primary.withOpacity(0.3),
                              blurRadius: 12.r,
                              offset: Offset(0, 4.h),
                            ),
                          ],
                        ),
                        child:
                            Icon(Icons.lock_rounded, color: Colors.white, size: 22.sp),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tr('Change Password', isHindi),
                              style: GoogleFonts.inter(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w800,
                                color: textColor,
                                letterSpacing: -0.3,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              tr('Use a strong password to keep your account secure.',
                                  isHindi),
                              style: GoogleFonts.inter(
                                fontSize: 12.sp,
                                color: textDimColor,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 28.h),

              // Current Password
              StaggeredListItem(
                index: 1,
                child: _buildPasswordField(
                  controller: _currentPassController,
                  label: tr('Current Password', isHindi),
                  isVisible: _showCurrent,
                  onToggle: () => setState(() => _showCurrent = !_showCurrent),
                  icon: Icons.lock_outline_rounded,
                  theme: theme,
                  colorScheme: colorScheme,
                  isDark: isDark,
                ),
              ),
              SizedBox(height: 16.h),

              // New Password
              StaggeredListItem(
                index: 2,
                child: _buildPasswordField(
                  controller: _newPassController,
                  label: tr('New Password', isHindi),
                  isVisible: _showNew,
                  onToggle: () => setState(() => _showNew = !_showNew),
                  icon: Icons.lock_reset_rounded,
                  theme: theme,
                  colorScheme: colorScheme,
                  isDark: isDark,
                ),
              ),
              SizedBox(height: 16.h),

              // Confirm New Password
              StaggeredListItem(
                index: 3,
                child: _buildPasswordField(
                  controller: _confirmPassController,
                  label: tr('Confirm New Password', isHindi),
                  isVisible: _showConfirm,
                  onToggle: () => setState(() => _showConfirm = !_showConfirm),
                  icon: Icons.check_circle_outline_rounded,
                  theme: theme,
                  colorScheme: colorScheme,
                  isDark: isDark,
                ),
              ),

              // Password strength hint
              SizedBox(height: 12.h),
              StaggeredListItem(
                index: 4,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withOpacity(isDark ? 0.08 : 0.05),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                        color: const Color(0xFFF59E0B).withOpacity(0.2)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.tips_and_updates_rounded,
                          color: const Color(0xFFF59E0B), size: 14.sp),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          tr('Password must be at least 6 characters long.', isHindi),
                          style: GoogleFonts.inter(
                            fontSize: 12.sp,
                            color: const Color(0xFFF59E0B).withOpacity(0.85),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 36.h),

              // Update Button
              StaggeredListItem(
                index: 5,
                child: AnimatedScaleButton(
                  onTap: userProvider.isLoading
                      ? () {}
                      : () async {
                          if (_currentPassController.text.isEmpty ||
                              _newPassController.text.isEmpty ||
                              _confirmPassController.text.isEmpty) {
                            _showSnackbar(
                                tr('Fields cannot be empty', isHindi),
                                isError: true);
                            return;
                          }
                          if (_newPassController.text !=
                              _confirmPassController.text) {
                            _showSnackbar(
                                tr('Passwords do not match', isHindi),
                                isError: true);
                            return;
                          }
                          final errorMessage =
                              await userProvider.changePassword(
                            _currentPassController.text,
                            _newPassController.text,
                            _confirmPassController.text,
                          );
                          if (errorMessage == null) {
                            if (mounted) {
                              _showSnackbar(
                                  tr('Password changed successfully!', isHindi));
                              Navigator.pop(context);
                            }
                          } else {
                            _showSnackbar(errorMessage, isError: true);
                          }
                        },
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 18.h),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [colorScheme.primary, colorScheme.secondary],
                      ),
                      borderRadius: BorderRadius.circular(18.r),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withOpacity(0.4),
                          blurRadius: 20.r,
                          offset: Offset(0, 8.h),
                          spreadRadius: -2,
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: userProvider.isLoading
                        ? SizedBox(
                            height: 22.h,
                            width: 22.w,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.5.w))
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.lock_reset_rounded,
                                  color: Colors.white, size: 18.sp),
                              SizedBox(width: 8.w),
                              Text(
                                tr('Update Password', isHindi),
                                style: GoogleFonts.inter(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
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
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool isVisible,
    required VoidCallback onToggle,
    required IconData icon,
    required ThemeData theme,
    required ColorScheme colorScheme,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.06) : Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: colorScheme.onSurface.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.1 : 0.03),
            blurRadius: 8.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: !isVisible,
        style: GoogleFonts.inter(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w500,
          fontSize: 15.sp,
        ),
        cursorColor: colorScheme.primary,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.inter(
            color: colorScheme.onSurface.withOpacity(0.45),
            fontSize: 14.sp,
          ),
          prefixIcon: Container(
            padding: EdgeInsets.all(14.w),
            child: Icon(icon, color: colorScheme.primary.withOpacity(0.7), size: 20.sp),
          ),
          suffixIcon: IconButton(
            icon: Icon(
              isVisible ? Icons.visibility_rounded : Icons.visibility_off_rounded,
              color: colorScheme.onSurface.withOpacity(0.35),
              size: 20.sp,
            ),
            onPressed: onToggle,
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding:
              EdgeInsets.symmetric(horizontal: 16.w, vertical: 18.h),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.r),
              borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.r),
              borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16.r),
            borderSide:
                BorderSide(color: colorScheme.primary.withOpacity(0.6), width: 1.5.w),
          ),
        ),
      ),
    );
  }
}
