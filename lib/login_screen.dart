import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'signup_screen.dart';
import 'forgot_password_screen.dart';
import 'dashboard_screen.dart';
import 'utils/animations.dart';
import 'providers/settings_provider.dart';
import 'providers/theme_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _emailFocus.addListener(() => setState(() {}));
    _passwordFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text(message, style: GoogleFonts.inter(color: Colors.white))),
          ],
        ),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        margin: EdgeInsets.all(16.w),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final settings = Provider.of<SettingsProvider>(context);
    final isHindi = settings.isHindi;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark ? AppTheme.primary : AppTheme.neutral;
    final cardColor = isDark ? AppTheme.surfaceDark : Colors.white;
    final textColor = isDark ? Colors.white : AppTheme.textPrimary;
    final mutedColor = isDark ? Colors.white54 : AppTheme.textSecondary;
    final borderColor = isDark ? AppTheme.borderDark : AppTheme.borderLight;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Logo & Brand ────────────────────────────────────────
                  StaggeredListItem(
                    index: 0,
                    child: Center(
                      child: Column(
                        children: [
                          // Logo icon
                          Container(
                            width: 72.w,
                            height: 72.w,
                            decoration: BoxDecoration(
                              color: AppTheme.secondary,
                              borderRadius: BorderRadius.circular(20.r),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.secondary.withOpacity(0.25),
                                  blurRadius: 20.r,
                                  offset: Offset(0, 8.h),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.document_scanner_rounded,
                              size: 32.sp,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            'DocVerify',
                            style: GoogleFonts.inter(
                              fontSize: 26.sp,
                              fontWeight: FontWeight.w800,
                              color: textColor,
                              letterSpacing: -0.5,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            tr('AI-Powered Document Analysis', isHindi),
                            style: GoogleFonts.inter(
                              fontSize: 13.sp,
                              color: mutedColor,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 40.h),

                  // ── Card ──────────────────────────────────────────────
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
                      padding: EdgeInsets.all(28.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            tr('Welcome back', isHindi),
                            style: GoogleFonts.inter(
                              fontSize: 22.sp,
                              fontWeight: FontWeight.w700,
                              color: textColor,
                              letterSpacing: -0.3,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            tr('Sign in to your account', isHindi),
                            style: GoogleFonts.inter(
                              fontSize: 14.sp,
                              color: mutedColor,
                            ),
                          ),
                          SizedBox(height: 28.h),

                          // Email
                          _buildLabel(tr('Email address', isHindi), textColor),
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
                          SizedBox(height: 20.h),

                          // Password
                          _buildLabel(tr('Password', isHindi), textColor),
                          SizedBox(height: 8.h),
                          _buildTextField(
                            controller: _passwordController,
                            focusNode: _passwordFocus,
                            hint: '••••••••',
                            icon: Icons.lock_outline_rounded,
                            isPassword: true,
                            isDark: isDark,
                            textColor: textColor,
                            borderColor: borderColor,
                          ),

                          SizedBox(height: 12.h),
                          Align(
                            alignment: Alignment.centerRight,
                            child: GestureDetector(
                              onTap: () => Navigator.push(context,
                                  MaterialPageRoute(builder: (_) => const ForgotPasswordScreen())),
                              child: Text(
                                tr('Forgot password?', isHindi),
                                style: GoogleFonts.inter(
                                  color: AppTheme.secondary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13.sp,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 28.h),

                          // Sign In Button
                          AnimatedScaleButton(
                            onTap: authProvider.isLoading
                                ? () {}
                                : () async {
                                    final success = await authProvider.login(
                                      _emailController.text.trim(),
                                      _passwordController.text,
                                    );
                                    if (success) {
                                      if (!mounted) return;
                                      Navigator.pushReplacement(context,
                                          MaterialPageRoute(builder: (_) => const DashboardScreen()));
                                    } else if (authProvider.errorMessage != null) {
                                      _showError(authProvider.errorMessage!);
                                    }
                                  },
                            child: Container(
                              height: 52.h,
                              decoration: BoxDecoration(
                                color: AppTheme.secondary,
                                borderRadius: BorderRadius.circular(14.r),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.secondary.withOpacity(0.30),
                                    blurRadius: 16.r,
                                    offset: Offset(0, 6.h),
                                  ),
                                ],
                              ),
                              alignment: Alignment.center,
                              child: authProvider.isLoading
                                  ? SizedBox(
                                      height: 20.h,
                                      width: 20.w,
                                      child: const CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : Text(
                                      tr('Sign in', isHindi),
                                      style: GoogleFonts.inter(
                                        fontSize: 15.sp,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
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

                  // ── Sign Up Link ──────────────────────────────────────
                  StaggeredListItem(
                    index: 2,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          tr("Don't have an account? ", isHindi),
                          style: GoogleFonts.inter(
                            fontSize: 14.sp,
                            color: mutedColor,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const SignupScreen())),
                          child: Text(
                            tr('Sign up', isHindi),
                            style: GoogleFonts.inter(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.secondary,
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
      style: GoogleFonts.inter(
        fontSize: 13.sp,
        fontWeight: FontWeight.w600,
        color: color,
      ),
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
    TextInputType keyboardType = TextInputType.text,
  }) {
    final isFocused = focusNode?.hasFocus ?? false;
    final fillColor = isDark
        ? Colors.white.withOpacity(0.05)
        : AppTheme.neutral;

    return Container(
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isFocused ? AppTheme.secondary : borderColor,
          width: isFocused ? 1.5 : 1,
        ),
        boxShadow: isFocused
            ? [
                BoxShadow(
                  color: AppTheme.secondary.withOpacity(0.10),
                  blurRadius: 8.r,
                )
              ]
            : null,
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        obscureText: isPassword && !_isPasswordVisible,
        keyboardType: keyboardType,
        style: GoogleFonts.inter(
          color: textColor,
          fontSize: 14.sp,
          fontWeight: FontWeight.w500,
        ),
        cursorColor: AppTheme.secondary,
        onTap: () => setState(() {}),
        onEditingComplete: () => setState(() {}),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.inter(
            color: AppTheme.textMuted,
            fontSize: 14.sp,
          ),
          prefixIcon: Icon(
            icon,
            color: isFocused ? AppTheme.secondary : AppTheme.textMuted,
            size: 18.sp,
          ),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    _isPasswordVisible ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                    color: AppTheme.textMuted,
                    size: 18.sp,
                  ),
                  onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                )
              : null,
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
