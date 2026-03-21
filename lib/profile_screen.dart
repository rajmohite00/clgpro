import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'login_screen.dart';
import 'onboarding_screen.dart';
import 'settings_screen.dart';
import 'edit_profile_screen.dart';
import 'change_password_screen.dart';
import 'providers/user_provider.dart';
import 'providers/settings_provider.dart';
import 'utils/animations.dart';

class ProfileScreen extends StatelessWidget {
  final bool isTab;
  const ProfileScreen({super.key, this.isTab = false});

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final settings = Provider.of<SettingsProvider>(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final textColor = colorScheme.onSurface;
    final textDimColor = colorScheme.onSurface.withOpacity(0.54);

    final String displayName = settings.privacyMode ? 'R**' : userProvider.name;
    final String displayEmail = settings.privacyMode ? 'r**@example.com' : userProvider.email;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: isTab
          ? null
          : AppBar(
              backgroundColor: theme.appBarTheme.backgroundColor ?? theme.scaffoldBackgroundColor,
              title: Text(tr('Profile', settings.isHindi), style: GoogleFonts.inter(color: textColor, fontWeight: FontWeight.w600)),
              elevation: 0,
              iconTheme: IconThemeData(color: textColor),
            ),
      body: SafeArea(
        child: userProvider.isLoading
            ? Center(child: CircularProgressIndicator(color: theme.primaryColor))
            : Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
                    child: Column(
                      children: [
                        StaggeredListItem(
                          index: 0,
                          child: Center(
                            child: Column(
                              children: [
                                 Container(
                                  padding: EdgeInsets.all(24.w),
                                  decoration: BoxDecoration(
                                    color: theme.cardColor,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: colorScheme.onSurface.withOpacity(0.08), width: 1.w),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                                        blurRadius: 20.r,
                                        offset: Offset(0, 8.h),
                                      ),
                                    ],
                                  ),
                                  child: Icon(Icons.person_rounded, size: 64.sp, color: colorScheme.primary),
                                ),
                                SizedBox(height: 24.h),
                                Text(
                                  displayName,
                                  style: GoogleFonts.inter(fontSize: 26.sp, fontWeight: FontWeight.bold, color: textColor, letterSpacing: -0.5),
                                ),
                                SizedBox(height: 4.h),
                                Text(
                                  displayEmail,
                                  style: GoogleFonts.inter(fontSize: 16.sp, color: textDimColor),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 48.h),
                  
                        StaggeredListItem(
                          index: 1,
                          child: _buildActionTile(
                            context,
                            icon: Icons.edit_outlined,
                            title: tr('Edit Profile Information', settings.isHindi),
                            theme: theme,
                            textColor: textColor,
                            textDimColor: textDimColor,
                            isDark: isDark,
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen()));
                            },
                          ),
                        ),
                        SizedBox(height: 16.h),
                        StaggeredListItem(
                          index: 2,
                          child: _buildActionTile(
                            context,
                            icon: Icons.lock_outline,
                            title: tr('Change Password', settings.isHindi),
                            theme: theme,
                            textColor: textColor,
                            textDimColor: textDimColor,
                            isDark: isDark,
                            onTap: () {
                               Navigator.push(context, MaterialPageRoute(builder: (_) => const ChangePasswordScreen()));
                            },
                          ),
                        ),
                        SizedBox(height: 16.h),
                        StaggeredListItem(
                          index: 3,
                          child: _buildActionTile(
                            context,
                            icon: Icons.settings_outlined,
                            title: tr('Settings', settings.isHindi),
                            theme: theme,
                            textColor: textColor,
                            textDimColor: textDimColor,
                            isDark: isDark,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const SettingsScreen()),
                              );
                            },
                          ),
                        ),
                        SizedBox(height: 48.h),
                  
                        StaggeredListItem(
                          index: 4,
                          child: AnimatedScaleButton(
                            onTap: () => _logout(context),
                            child: SizedBox(
                              width: double.infinity,
                              child: Container(
                                padding: EdgeInsets.symmetric(vertical: 18.h),
                                decoration: BoxDecoration(
                                  color: colorScheme.error.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(16.r),
                                  border: Border.all(color: colorScheme.error.withOpacity(0.3), width: 1.w),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.logout, color: colorScheme.error, size: 20.sp),
                                    SizedBox(width: 8.w),
                                    Text(
                                      tr('Log Out', settings.isHindi),
                                      style: GoogleFonts.inter(fontSize: 16.sp, fontWeight: FontWeight.w600, color: colorScheme.error),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildActionTile(BuildContext context, {required IconData icon, required String title, required VoidCallback onTap, required ThemeData theme, required Color textColor, required Color textDimColor, required bool isDark}) {
    return AnimatedScaleButton(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: theme.colorScheme.onSurface.withOpacity(0.05), width: 1.w),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.02),
              blurRadius: 10.r,
              offset: Offset(0, 4.h),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(icon, color: theme.primaryColor, size: 22.sp),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Text(title, style: GoogleFonts.inter(fontSize: 15.sp, fontWeight: FontWeight.w600, color: textColor)),
            ),
            Icon(Icons.chevron_right, color: textDimColor, size: 20.sp),
          ],
        ),
      ),
    );
  }
}
