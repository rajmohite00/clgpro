import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'providers/user_provider.dart';
import 'providers/settings_provider.dart';
import 'utils/animations.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    _nameController = TextEditingController(text: userProvider.name);
    _emailController = TextEditingController(text: userProvider.email);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      if (!mounted) return;
      Provider.of<UserProvider>(context, listen: false).updateProfilePic(image.path);
    }
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
          tr('Edit Profile', isHindi),
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
              // Avatar preview
              StaggeredListItem(
                index: 0,
                child: Center(
                  child: Column(
                    children: [
                      Container(
                        padding: EdgeInsets.all(4.w),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [colorScheme.primary, colorScheme.secondary],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.primary.withOpacity(0.3),
                              blurRadius: 16.r,
                              spreadRadius: 2.r,
                            ),
                          ],
                        ),
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                padding: EdgeInsets.all(3.w),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: theme.scaffoldBackgroundColor,
                                ),
                                child: CircleAvatar(
                                  radius: 42.r,
                                  backgroundColor: colorScheme.primary.withOpacity(0.1),
                                  backgroundImage: userProvider.profilePicPath != null 
                                      ? FileImage(File(userProvider.profilePicPath!)) 
                                      : null,
                                  child: userProvider.profilePicPath == null ? Text(
                                    userProvider.name.isNotEmpty
                                        ? userProvider.name[0].toUpperCase()
                                        : 'U',
                                    style: GoogleFonts.inter(
                                      fontSize: 32.sp,
                                      fontWeight: FontWeight.w800,
                                      color: colorScheme.primary,
                                    ),
                                  ) : null,
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: EdgeInsets.all(6.w),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primary,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: theme.scaffoldBackgroundColor, width: 2.w),
                                  ),
                                  child: Icon(Icons.camera_alt_rounded, color: Colors.white, size: 14.sp),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 12.h),
                      Text(
                        tr('Edit Profile', isHindi),
                        style: GoogleFonts.inter(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w800,
                          color: textColor,
                          letterSpacing: -0.4,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        tr('Update your personal information', isHindi),
                        style: GoogleFonts.inter(fontSize: 13.sp, color: textDimColor),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 32.h),

              // Full Name
              StaggeredListItem(
                index: 1,
                child: _buildField(
                  controller: _nameController,
                  label: tr('Full Name', isHindi),
                  icon: Icons.person_outline_rounded,
                  keyboardType: TextInputType.name,
                  theme: theme,
                  colorScheme: colorScheme,
                  isDark: isDark,
                ),
              ),
              SizedBox(height: 16.h),

              // Email
              StaggeredListItem(
                index: 2,
                child: _buildField(
                  controller: _emailController,
                  label: tr('Email Address', isHindi),
                  icon: Icons.alternate_email_rounded,
                  keyboardType: TextInputType.emailAddress,
                  theme: theme,
                  colorScheme: colorScheme,
                  isDark: isDark,
                ),
              ),
              SizedBox(height: 40.h),

              // Save Button
              StaggeredListItem(
                index: 3,
                child: AnimatedScaleButton(
                  onTap: userProvider.isLoading
                      ? () {}
                      : () async {
                          final name = _nameController.text.trim();
                          final email = _emailController.text.trim();
                          if (name.isEmpty || email.isEmpty) {
                            _showSnackbar(
                                tr('Fields cannot be empty', isHindi),
                                isError: true);
                            return;
                          }
                          final success =
                              await userProvider.updateProfile(name, email);
                          if (success) {
                            if (mounted) {
                              _showSnackbar(
                                  tr('Profile updated successfully!', isHindi));
                              Navigator.pop(context);
                            }
                          } else {
                            _showSnackbar(
                                tr('Error updating profile. Please try again.',
                                    isHindi),
                                isError: true);
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
                              Icon(Icons.save_rounded,
                                  color: Colors.white, size: 18.sp),
                              SizedBox(width: 8.w),
                              Text(
                                tr('Save Changes', isHindi),
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

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required TextInputType keyboardType,
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
        keyboardType: keyboardType,
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
