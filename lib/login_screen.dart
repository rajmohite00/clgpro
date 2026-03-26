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
        backgroundColor: const Color(0xFFEF4444),
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

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: FloatingOrbsBackground(
        orbColors: isDark
            ? [const Color(0xFF6366F1), const Color(0xFF8B5CF6), const Color(0xFF06B6D4)]
            : [const Color(0xFF818CF8), const Color(0xFFA78BFA), const Color(0xFF67E8F9)],
        child: AnimatedGradientBackground(
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 24.0.w, vertical: 48.0.h),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: GlassContainer(
                    padding: EdgeInsets.all(36.w),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Logo + App Name
                        StaggeredListItem(
                          index: 0,
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Logo widget — 3 rings + icon + badge
                                SizedBox(
                                  width: 110.w,
                                  height: 110.w,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      // Outer glow ring
                                      Container(
                                        width: 110.w,
                                        height: 110.w,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: RadialGradient(
                                            colors: [
                                              colorScheme.primary.withOpacity(0.22),
                                              colorScheme.secondary.withOpacity(0.08),
                                              Colors.transparent,
                                            ],
                                          ),
                                        ),
                                      ),
                                      // Middle border ring
                                      Container(
                                        width: 86.w,
                                        height: 86.w,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: colorScheme.primary.withOpacity(0.3),
                                            width: 1.5,
                                          ),
                                        ),
                                      ),
                                      // Core gradient circle + icon
                                      Container(
                                        width: 64.w,
                                        height: 64.w,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              colorScheme.primary,
                                              colorScheme.secondary,
                                            ],
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: colorScheme.primary.withOpacity(0.45),
                                              blurRadius: 22.r,
                                              spreadRadius: 3.r,
                                            ),
                                            BoxShadow(
                                              color: colorScheme.secondary.withOpacity(0.25),
                                              blurRadius: 44.r,
                                              spreadRadius: 8.r,
                                            ),
                                          ],
                                        ),
                                        child: Icon(
                                          Icons.document_scanner_rounded,
                                          size: 28.sp,
                                          color: Colors.white,
                                        ),
                                      ),
                                      // Verified badge bottom-right
                                      Positioned(
                                        right: 8.w,
                                        bottom: 8.w,
                                        child: Container(
                                          padding: EdgeInsets.all(3.w),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: const Color(0xFF10B981),
                                            border: Border.all(
                                              color: isDark
                                                  ? const Color(0xFF0F0E1A)
                                                  : Colors.white,
                                              width: 2,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(0xFF10B981)
                                                    .withOpacity(0.45),
                                                blurRadius: 8.r,
                                              ),
                                            ],
                                          ),
                                          child: Icon(
                                            Icons.verified_rounded,
                                            size: 11.sp,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 14.h),
                                // App name gradient text
                                ShaderMask(
                                  shaderCallback: (bounds) => LinearGradient(
                                    colors: [
                                      colorScheme.primary,
                                      colorScheme.secondary,
                                    ],
                                  ).createShader(bounds),
                                  child: Text(
                                    'Smart Document Detective',
                                    style: GoogleFonts.inter(
                                      fontSize: 17.sp,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                ),
                                SizedBox(height: 5.h),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 12.w, vertical: 4.h),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primary.withOpacity(0.09),
                                    borderRadius: BorderRadius.circular(20.r),
                                    border: Border.all(
                                        color: colorScheme.primary.withOpacity(0.18)),
                                  ),
                                  child: Text(
                                    'AI  •  Secure  •  Fast',
                                    style: GoogleFonts.inter(
                                      fontSize: 10.sp,
                                      fontWeight: FontWeight.w600,
                                      color: colorScheme.primary.withOpacity(0.8),
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 28.h),

                        // Header
                        StaggeredListItem(
                          index: 1,
                          child: Text(
                            tr('Welcome Back', isHindi),
                            style: GoogleFonts.inter(
                              fontSize: 30.sp,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.8,
                              color: colorScheme.onSurface,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        SizedBox(height: 6.h),
                        StaggeredListItem(
                          index: 2,
                          child: Text(
                            tr('Please enter your details to sign in.', isHindi),
                            style: GoogleFonts.inter(
                              fontSize: 14.sp,
                              color: colorScheme.onSurface.withOpacity(0.55),
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        SizedBox(height: 36.h),

                        // Email Field
                        StaggeredListItem(
                          index: 3,
                          child: _buildTextField(
                            controller: _emailController,
                            focusNode: _emailFocus,
                            label: tr('Email', isHindi),
                            icon: Icons.alternate_email_rounded,
                            keyboardType: TextInputType.emailAddress,
                            colorScheme: colorScheme,
                            theme: theme,
                          ),
                        ),
                        SizedBox(height: 16.h),

                        // Password Field
                        StaggeredListItem(
                          index: 4,
                          child: _buildTextField(
                            controller: _passwordController,
                            focusNode: _passwordFocus,
                            label: tr('Password', isHindi),
                            icon: Icons.lock_outline_rounded,
                            isPassword: true,
                            colorScheme: colorScheme,
                            theme: theme,
                          ),
                        ),

                        // Forgot Password
                        StaggeredListItem(
                          index: 5,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const ForgotPasswordScreen(),
                                  ),
                                );
                              },
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
                                minimumSize: Size.zero,
                              ),
                              child: Text(
                                tr('Forgot password?', isHindi),
                                style: GoogleFonts.inter(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13.sp,
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 24.h),

                        // Login Button
                        StaggeredListItem(
                          index: 6,
                          child: AnimatedScaleButton(
                            onTap: authProvider.isLoading
                                ? () {}
                                : () async {
                                    final success = await authProvider.login(
                                      _emailController.text.trim(),
                                      _passwordController.text,
                                    );
                                    if (success) {
                                      if (!mounted) return;
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const DashboardScreen(),
                                        ),
                                      );
                                    } else if (authProvider.errorMessage != null) {
                                      _showError(authProvider.errorMessage!);
                                    }
                                  },
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: 18.h),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    colorScheme.primary,
                                    colorScheme.secondary,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16.r),
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
                              child: authProvider.isLoading
                                  ? SizedBox(
                                      height: 20.h,
                                      width: 20.w,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5.w,
                                      ),
                                    )
                                  : Text(
                                      tr('Sign in', isHindi),
                                      style: GoogleFonts.inter(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                        SizedBox(height: 28.h),

                        // Signup Navigation
                        StaggeredListItem(
                          index: 7,
                          child: Center(
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      child: Container(
                                        height: 1.h,
                                        color: colorScheme.onSurface.withOpacity(0.1),
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 12.w),
                                      child: Text(
                                        tr('New here?', isHindi),
                                        style: GoogleFonts.inter(
                                          color: colorScheme.onSurface.withOpacity(0.4),
                                          fontSize: 12.sp,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Container(
                                        height: 1.h,
                                        color: colorScheme.onSurface.withOpacity(0.1),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 14.h),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const SignupScreen(),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 28.w, vertical: 14.h),
                                    decoration: BoxDecoration(
                                      color: colorScheme.onSurface.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(14.r),
                                      border: Border.all(
                                          color: colorScheme.primary.withOpacity(0.25)),
                                    ),
                                    child: RichText(
                                      text: TextSpan(
                                        style: GoogleFonts.inter(
                                            fontSize: 14.sp),
                                        children: [
                                          TextSpan(
                                            text: tr("Don't have an account? ", isHindi),
                                            style: TextStyle(
                                              color: colorScheme.onSurface
                                                  .withOpacity(0.55),
                                            ),
                                          ),
                                          TextSpan(
                                            text: tr('Sign up', isHindi),
                                            style: TextStyle(
                                              color: colorScheme.primary,
                                              fontWeight: FontWeight.w800,
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
                        SizedBox(height: 8.h),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required ColorScheme colorScheme,
    required ThemeData theme,
    FocusNode? focusNode,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    final isDark = theme.brightness == Brightness.dark;
    final isFocused = focusNode?.hasFocus ?? false;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.07) : Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isFocused
              ? colorScheme.primary.withOpacity(0.7)
              : colorScheme.onSurface.withOpacity(0.1),
          width: isFocused ? 1.5.w : 1.w,
        ),
        boxShadow: isFocused
            ? [
                BoxShadow(
                  color: colorScheme.primary.withOpacity(0.12),
                  blurRadius: 12.r,
                  spreadRadius: 0,
                ),
              ]
            : null,
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        obscureText: isPassword && !_isPasswordVisible,
        keyboardType: keyboardType,
        style: GoogleFonts.inter(
          color: colorScheme.onSurface,
          fontSize: 15.sp,
          fontWeight: FontWeight.w500,
        ),
        cursorColor: colorScheme.primary,
        onTap: () => setState(() {}),
        onEditingComplete: () => setState(() {}),
        decoration: InputDecoration(
          // hintText never moves — fixes the "label goes inline" bug
          hintText: label,
          hintStyle: GoogleFonts.inter(
            color: colorScheme.onSurface.withOpacity(0.38),
            fontSize: 14.sp,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: Padding(
            padding: EdgeInsets.symmetric(horizontal: 14.w),
            child: Icon(
              icon,
              color: isFocused
                  ? colorScheme.primary
                  : colorScheme.onSurface.withOpacity(0.4),
              size: 20.sp,
            ),
          ),
          prefixIconConstraints: BoxConstraints(minWidth: 52.w, minHeight: 0),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility_rounded
                        : Icons.visibility_off_rounded,
                    color: colorScheme.onSurface.withOpacity(0.4),
                    size: 20.sp,
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16.r),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16.r),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16.r),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

