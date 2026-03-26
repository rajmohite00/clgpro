import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'utils/animations.dart';
import 'providers/settings_provider.dart';

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
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

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

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text(message, style: GoogleFonts.inter(color: Colors.white))),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        margin: EdgeInsets.all(16.w),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: colorScheme.onSurface.withOpacity(0.06),
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: colorScheme.onSurface.withOpacity(0.1)),
            ),
            child: Icon(Icons.arrow_back_ios_new_rounded, color: colorScheme.onSurface, size: 16.sp),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FloatingOrbsBackground(
        orbColors: isDark
            ? [const Color(0xFF6366F1), const Color(0xFF8B5CF6), const Color(0xFF06B6D4)]
            : [const Color(0xFF818CF8), const Color(0xFFA78BFA), const Color(0xFF67E8F9)],
        child: AnimatedGradientBackground(
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 24.0.w, vertical: 20.h),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 450),
                  child: GlassContainer(
                    padding: EdgeInsets.all(32.w),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Logo — 3-ring premium design
                        StaggeredListItem(
                          index: 0,
                          child: Center(
                            child: SizedBox(
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
                                      Icons.person_add_rounded,
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
                                        Icons.star_rounded,
                                        size: 11.sp,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 16.h),

                        StaggeredListItem(
                          index: 1,
                          child: Text(
                            tr('Create Account', isHindi),
                            style: GoogleFonts.inter(
                              fontSize: 28.sp,
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
                            tr('Join us to get started', isHindi),
                            style: GoogleFonts.inter(
                              fontSize: 14.sp,
                              color: colorScheme.onSurface.withOpacity(0.5),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        SizedBox(height: 32.h),

                        StaggeredListItem(
                          index: 3,
                          child: _buildTextField(
                            controller: _nameController,
                            label: tr('Full Name', isHindi),
                            icon: Icons.person_outline_rounded,
                            theme: theme,
                            colorScheme: colorScheme,
                          ),
                        ),
                        SizedBox(height: 14.h),

                        StaggeredListItem(
                          index: 4,
                          child: _buildTextField(
                            controller: _emailController,
                            label: tr('Email Address', isHindi),
                            icon: Icons.alternate_email_rounded,
                            keyboardType: TextInputType.emailAddress,
                            theme: theme,
                            colorScheme: colorScheme,
                          ),
                        ),
                        SizedBox(height: 14.h),

                        StaggeredListItem(
                          index: 5,
                          child: _buildTextField(
                            controller: _passwordController,
                            label: tr('Password', isHindi),
                            icon: Icons.lock_outline_rounded,
                            isPassword: true,
                            isConfirm: false,
                            theme: theme,
                            colorScheme: colorScheme,
                          ),
                        ),
                        SizedBox(height: 14.h),

                        StaggeredListItem(
                          index: 6,
                          child: _buildTextField(
                            controller: _confirmPasswordController,
                            label: tr('Confirm Password', isHindi),
                            icon: Icons.lock_outline_rounded,
                            isPassword: true,
                            isConfirm: true,
                            theme: theme,
                            colorScheme: colorScheme,
                          ),
                        ),
                        SizedBox(height: 32.h),

                        StaggeredListItem(
                          index: 7,
                          child: AnimatedScaleButton(
                            onTap: authProvider.isLoading
                                ? () {}
                                : () async {
                                    if (_passwordController.text != _confirmPasswordController.text) {
                                      _showError("Passwords do not match");
                                      return;
                                    }
                                    final success = await authProvider.signup(
                                      _nameController.text.trim(),
                                      _emailController.text.trim(),
                                      _passwordController.text,
                                    );
                                    if (success) {
                                      if (!mounted) return;
                                      _showSuccess("Account created successfully!");
                                      Navigator.pop(context);
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
                                  colors: [colorScheme.primary, colorScheme.secondary],
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
                                      height: 24.h,
                                      width: 24.w,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5.w),
                                    )
                                  : Text(
                                      tr('Sign Up', isHindi),
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
                        SizedBox(height: 20.h),
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
    required ThemeData theme,
    required ColorScheme colorScheme,
    bool isPassword = false,
    bool isConfirm = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    final isDark = theme.brightness == Brightness.dark;
    final visible = isConfirm ? _isConfirmPasswordVisible : _isPasswordVisible;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.06) : Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: colorScheme.onSurface.withOpacity(0.1)),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword && !visible,
        keyboardType: keyboardType,
        style: GoogleFonts.inter(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w500,
          fontSize: 15.sp,
        ),
        cursorColor: colorScheme.primary,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.inter(color: colorScheme.onSurface.withOpacity(0.45), fontSize: 14.sp),
          prefixIcon: Container(
            padding: EdgeInsets.all(14.w),
            child: Icon(icon, color: colorScheme.primary.withOpacity(0.7), size: 20.sp),
          ),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    visible ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                    color: colorScheme.onSurface.withOpacity(0.4),
                    size: 20.sp,
                  ),
                  onPressed: () {
                    setState(() {
                      if (isConfirm) {
                        _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                      } else {
                        _isPasswordVisible = !_isPasswordVisible;
                      }
                    });
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 18.h),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16.r), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16.r), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16.r),
            borderSide: BorderSide(color: colorScheme.primary.withOpacity(0.7), width: 1.5.w),
          ),
        ),
      ),
    );
  }
}
