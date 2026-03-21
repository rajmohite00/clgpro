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
                        tr('Create Account', isHindi),
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
                        tr('Join us to get started', isHindi),
                        style: GoogleFonts.inter(fontSize: 16.sp, color: colorScheme.onSurface.withOpacity(0.54)),
                      ),
                    ),
                    SizedBox(height: 48.h),

                    StaggeredListItem(
                      index: 2,
                      child: _buildTextField(
                        controller: _nameController,
                        label: tr('Full Name', isHindi),
                        icon: Icons.person_outline,
                      ),
                    ),
                    SizedBox(height: 16.h),

                    StaggeredListItem(
                      index: 3,
                      child: _buildTextField(
                        controller: _emailController,
                        label: tr('Email Address', isHindi),
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                      ),
                    ),
                    SizedBox(height: 16.h),

                    StaggeredListItem(
                      index: 4,
                      child: _buildTextField(
                        controller: _passwordController,
                        label: tr('Password', isHindi),
                        icon: Icons.lock_outline,
                        isPassword: true,
                      ),
                    ),
                    SizedBox(height: 16.h),

                    StaggeredListItem(
                      index: 5,
                      child: _buildTextField(
                        controller: _confirmPasswordController,
                        label: tr('Confirm Password', isHindi),
                        icon: Icons.lock_outline,
                        isPassword: true,
                      ),
                    ),
                    SizedBox(height: 48.h),

                    StaggeredListItem(
                      index: 6,
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
                                  Navigator.pop(context); // Go back to login
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
                                  tr('Sign Up', isHindi),
                                  style: GoogleFonts.inter(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    SizedBox(height: 24.h),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return TextField(
      controller: controller,
      obscureText: isPassword && !_isPasswordVisible,
      keyboardType: keyboardType,
      style: GoogleFonts.inter(color: colorScheme.onSurface),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(color: colorScheme.onSurface.withOpacity(0.54)),
        prefixIcon: Icon(icon, color: colorScheme.onSurface.withOpacity(0.54)),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                  color: colorScheme.onSurface.withOpacity(0.54),
                ),
                onPressed: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
              )
            : null,
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
    );
  }
}
