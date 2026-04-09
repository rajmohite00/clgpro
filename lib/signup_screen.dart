import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'utils/animations.dart';
import 'providers/settings_provider.dart';
import 'providers/theme_provider.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _nameFocus.addListener(() => setState(() {}));
    _emailFocus.addListener(() => setState(() {}));
    _passwordFocus.addListener(() => setState(() {}));
    _confirmFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.error_outline, color: Colors.white, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(message, style: GoogleFonts.inter(color: Colors.white))),
      ]),
      backgroundColor: AppTheme.error,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      margin: EdgeInsets.all(16.w),
    ));
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(message, style: GoogleFonts.inter(color: Colors.white))),
      ]),
      backgroundColor: AppTheme.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      margin: EdgeInsets.all(16.w),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final settings = Provider.of<SettingsProvider>(context);
    final isHindi = settings.isHindi;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark ? AppTheme.ink : AppTheme.lightBg;
    final cardColor = isDark ? AppTheme.inkMid : Colors.white;
    final textColor = isDark ? AppTheme.textPrimary : AppTheme.lightText;
    final mutedColor = isDark ? AppTheme.textSecondary : AppTheme.lightTextSub;
    final borderColor = isDark ? AppTheme.borderLight : AppTheme.lightBorder;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: isDark ? AppTheme.ink : Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.08) : AppTheme.lightBorder.withOpacity(0.3),
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: borderColor),
            ),
            child: Icon(Icons.arrow_back_ios_new_rounded, color: textColor, size: 14.sp),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.h),
          child: Divider(height: 1, color: borderColor),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Header ─────────────────────────────────────────────
                  StaggeredListItem(
                    index: 0,
                    child: Center(
                      child: Column(
                        children: [
                          Container(
                            width: 64.w,
                            height: 64.w,
                            decoration: BoxDecoration(
                              color: AppTheme.jade,
                              borderRadius: BorderRadius.circular(18.r),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.jade.withOpacity(0.25),
                                  blurRadius: 16.r,
                                  offset: Offset(0, 6.h),
                                ),
                              ],
                            ),
                            child: Icon(Icons.person_add_rounded, size: 28.sp, color: Colors.white),
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            tr('Create Account', isHindi),
                            style: GoogleFonts.inter(
                              fontSize: 24.sp,
                              fontWeight: FontWeight.w800,
                              color: textColor,
                              letterSpacing: -0.5,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            tr('Join DocVerify to get started', isHindi),
                            style: GoogleFonts.inter(fontSize: 13.sp, color: mutedColor),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 32.h),

                  // ── Form Card ──────────────────────────────────────────
                  StaggeredListItem(
                    index: 1,
                    child: Container(
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(24.r),
                        border: Border.all(color: borderColor),
                        boxShadow: isDark
                            ? []
                            : [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 20.r,
                                  offset: Offset(0, 4.h),
                                ),
                              ],
                      ),
                      padding: EdgeInsets.all(24.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildLabel(tr('Full Name', isHindi), textColor),
                          SizedBox(height: 8.h),
                          _buildTextField(
                            controller: _nameController,
                            focusNode: _nameFocus,
                            hint: tr('Your full name', isHindi),
                            icon: Icons.person_outline_rounded,
                            isDark: isDark,
                            textColor: textColor,
                            borderColor: borderColor,
                          ),
                          SizedBox(height: 18.h),

                          _buildLabel(tr('Email Address', isHindi), textColor),
                          SizedBox(height: 8.h),
                          _buildTextField(
                            controller: _emailController,
                            focusNode: _emailFocus,
                            hint: 'you@example.com',
                            icon: Icons.alternate_email_rounded,
                            keyboardType: TextInputType.emailAddress,
                            isDark: isDark,
                            textColor: textColor,
                            borderColor: borderColor,
                          ),
                          SizedBox(height: 18.h),

                          _buildLabel(tr('Password', isHindi), textColor),
                          SizedBox(height: 8.h),
                          _buildTextField(
                            controller: _passwordController,
                            focusNode: _passwordFocus,
                            hint: '••••••••',
                            icon: Icons.lock_outline_rounded,
                            isPassword: true,
                            isConfirm: false,
                            isDark: isDark,
                            textColor: textColor,
                            borderColor: borderColor,
                          ),
                          SizedBox(height: 18.h),

                          _buildLabel(tr('Confirm Password', isHindi), textColor),
                          SizedBox(height: 8.h),
                          _buildTextField(
                            controller: _confirmPasswordController,
                            focusNode: _confirmFocus,
                            hint: '••••••••',
                            icon: Icons.lock_outline_rounded,
                            isPassword: true,
                            isConfirm: true,
                            isDark: isDark,
                            textColor: textColor,
                            borderColor: borderColor,
                          ),
                          SizedBox(height: 28.h),

                          // Submit Button
                          AnimatedScaleButton(
                            onTap: authProvider.isLoading
                                ? () {}
                                : () async {
                                    if (_passwordController.text != _confirmPasswordController.text) {
                                      _showError('Passwords do not match');
                                      return;
                                    }
                                    final success = await authProvider.signup(
                                      _nameController.text.trim(),
                                      _emailController.text.trim(),
                                      _passwordController.text,
                                    );
                                    if (success) {
                                      if (!mounted) return;
                                      _showSuccess('Account created successfully!');
                                      Navigator.pop(context);
                                    } else if (authProvider.errorMessage != null) {
                                      _showError(authProvider.errorMessage!);
                                    }
                                  },
                            child: Container(
                              height: 52.h,
                              decoration: BoxDecoration(
                                color: AppTheme.jade,
                                borderRadius: BorderRadius.circular(14.r),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.jade.withOpacity(0.30),
                                    blurRadius: 16.r,
                                    offset: Offset(0, 6.h),
                                  ),
                                ],
                              ),
                              alignment: Alignment.center,
                              child: authProvider.isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(color: AppTheme.ink, strokeWidth: 2.5),
                                    )
                                  : Text(
                                      tr('Create Account', isHindi),
                                      style: GoogleFonts.inter(
                                        fontSize: 15.sp,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.ink,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 20.h),

                  StaggeredListItem(
                    index: 2,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          tr('Already have an account? ', isHindi),
                          style: GoogleFonts.inter(fontSize: 14.sp, color: mutedColor),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Text(
                            tr('Sign in', isHindi),
                            style: GoogleFonts.inter(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.jade,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text, Color color) {
    return Text(
      text,
      style: GoogleFonts.inter(fontSize: 13.sp, fontWeight: FontWeight.w600, color: color),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required bool isDark,
    required Color textColor,
    required Color borderColor,
    FocusNode? focusNode,
    bool isPassword = false,
    bool isConfirm = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    final isFocused = focusNode?.hasFocus ?? false;
    final visible = isConfirm ? _isConfirmPasswordVisible : _isPasswordVisible;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isFocused ? AppTheme.jade : borderColor,
          width: isFocused ? 1.5 : 1,
        ),
        boxShadow: isFocused
            ? [BoxShadow(color: AppTheme.jade.withOpacity(0.10), blurRadius: 8.r)]
            : null,
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        obscureText: isPassword && !visible,
        keyboardType: keyboardType,
        style: GoogleFonts.inter(color: textColor, fontSize: 14.sp, fontWeight: FontWeight.w500),
        cursorColor: AppTheme.jade,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.inter(color: AppTheme.textMuted, fontSize: 14.sp),
          prefixIcon: Icon(
            icon,
            color: isFocused ? AppTheme.jade : AppTheme.textMuted,
            size: 18.sp,
          ),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    visible ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                    color: AppTheme.textMuted,
                    size: 18.sp,
                  ),
                  onPressed: () => setState(() {
                    if (isConfirm) {
                      _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                    } else {
                      _isPasswordVisible = !_isPasswordVisible;
                    }
                  }),
                )
              : null,
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide.none),
        ),
      ),
    );
  }
}
