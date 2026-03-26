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

  Future<void> _logout(BuildContext context, bool isHindi) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: Text(tr('Confirm Logout', isHindi),
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
        content: Text(tr('Are you sure you want to log out?', isHindi),
            style: GoogleFonts.inter(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.65))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(tr('Cancel', isHindi),
                style: GoogleFonts.inter(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(tr('Log Out', isHindi),
                style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
          )
        ],
      ),
    );

    if (confirm != true) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(
        children: [
          const Icon(Icons.check_circle_outlined, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Text(tr('Logged out successfully', isHindi), style: GoogleFonts.inter(color: Colors.white)),
        ],
      ),
      backgroundColor: const Color(0xFF10B981),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      margin: EdgeInsets.all(16.w),
    ));

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
    final textDimColor = colorScheme.onSurface.withOpacity(0.52);

    final String displayName = settings.privacyMode ? 'R**' : userProvider.name;
    final String displayEmail = settings.privacyMode ? 'r**@example.com' : userProvider.email;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: isTab
          ? null
          : AppBar(
              backgroundColor: theme.scaffoldBackgroundColor,
              title: Text(tr('Profile', settings.isHindi),
                  style: GoogleFonts.inter(color: textColor, fontWeight: FontWeight.w700)),
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
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
                    child: Column(
                      children: [
                        // Avatar Section
                        StaggeredListItem(
                          index: 0,
                          child: Center(
                            child: Column(
                              children: [
                                // Gradient ring avatar
                                Container(
                                  padding: EdgeInsets.all(4.w),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        colorScheme.primary,
                                        colorScheme.secondary,
                                        isDark ? const Color(0xFF06B6D4) : const Color(0xFF8B5CF6),
                                      ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: colorScheme.primary.withOpacity(0.35),
                                        blurRadius: 20.r,
                                        spreadRadius: 2.r,
                                      ),
                                    ],
                                  ),
                                  child: Container(
                                    padding: EdgeInsets.all(3.w),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: theme.scaffoldBackgroundColor,
                                    ),
                                    child: CircleAvatar(
                                      radius: 48.r,
                                      backgroundColor: isDark
                                          ? colorScheme.primary.withOpacity(0.1)
                                          : colorScheme.primary.withOpacity(0.08),
                                      child: Text(
                                        displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                                        style: GoogleFonts.inter(
                                          fontSize: 36.sp,
                                          fontWeight: FontWeight.w800,
                                          color: colorScheme.primary,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 16.h),
                                Text(
                                  displayName,
                                  style: GoogleFonts.inter(
                                    fontSize: 24.sp,
                                    fontWeight: FontWeight.w800,
                                    color: textColor,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                SizedBox(height: 4.h),
                                Text(
                                  displayEmail,
                                  style: GoogleFonts.inter(fontSize: 14.sp, color: textDimColor),
                                ),
                                SizedBox(height: 12.h),
                                // Badge
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        colorScheme.primary.withOpacity(0.15),
                                        colorScheme.secondary.withOpacity(0.15),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(20.r),
                                    border: Border.all(color: colorScheme.primary.withOpacity(0.2)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.verified_rounded, color: colorScheme.primary, size: 14.sp),
                                      SizedBox(width: 6.w),
                                      Text(
                                        'Verified User',
                                        style: GoogleFonts.inter(
                                          fontSize: 12.sp,
                                          fontWeight: FontWeight.w600,
                                          color: colorScheme.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 32.h),

                        // Quick Stats
                        StaggeredListItem(
                          index: 1,
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 16.w),
                            decoration: BoxDecoration(
                              color: theme.cardColor,
                              borderRadius: BorderRadius.circular(20.r),
                              border: Border.all(color: colorScheme.onSurface.withOpacity(0.06)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                                  blurRadius: 12.r,
                                  offset: Offset(0, 4.h),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                _buildMiniStat('42', 'Total Scans', Icons.document_scanner_rounded, colorScheme),
                                _buildDivider(isDark),
                                _buildMiniStat('38', 'Verified', Icons.verified_rounded, colorScheme),
                                _buildDivider(isDark),
                                _buildMiniStat('4', 'Flagged', Icons.flag_rounded, colorScheme, isAlert: true),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 24.h),

                        // Section Header
                        StaggeredListItem(
                          index: 2,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Account',
                              style: GoogleFonts.inter(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w600,
                                color: textDimColor,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 10.h),

                        StaggeredListItem(
                          index: 3,
                          child: _buildActionTile(
                            context,
                            icon: Icons.edit_rounded,
                            title: tr('Edit Profile Information', settings.isHindi),
                            iconColor: const Color(0xFF6366F1),
                            theme: theme,
                            textColor: textColor,
                            textDimColor: textDimColor,
                            isDark: isDark,
                            onTap: () {
                              Navigator.push(context,
                                  MaterialPageRoute(builder: (_) => const EditProfileScreen()));
                            },
                          ),
                        ),
                        SizedBox(height: 10.h),
                        StaggeredListItem(
                          index: 4,
                          child: _buildActionTile(
                            context,
                            icon: Icons.lock_rounded,
                            title: tr('Change Password', settings.isHindi),
                            iconColor: const Color(0xFF8B5CF6),
                            theme: theme,
                            textColor: textColor,
                            textDimColor: textDimColor,
                            isDark: isDark,
                            onTap: () {
                              Navigator.push(context,
                                  MaterialPageRoute(builder: (_) => const ChangePasswordScreen()));
                            },
                          ),
                        ),
                        SizedBox(height: 10.h),
                        StaggeredListItem(
                          index: 5,
                          child: _buildActionTile(
                            context,
                            icon: Icons.settings_rounded,
                            title: tr('Settings', settings.isHindi),
                            iconColor: const Color(0xFF10B981),
                            theme: theme,
                            textColor: textColor,
                            textDimColor: textDimColor,
                            isDark: isDark,
                            onTap: () {
                              Navigator.push(
                                  context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
                            },
                          ),
                        ),

                        SizedBox(height: 32.h),

                        // Logout Button
                        StaggeredListItem(
                          index: 6,
                          child: AnimatedScaleButton(
                            onTap: () => _logout(context, settings.isHindi),
                            child: Container(
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(vertical: 18.h),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEF4444).withOpacity(isDark ? 0.1 : 0.06),
                                borderRadius: BorderRadius.circular(18.r),
                                border: Border.all(
                                    color: const Color(0xFFEF4444).withOpacity(0.25), width: 1.w),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.logout_rounded,
                                      color: const Color(0xFFEF4444), size: 20.sp),
                                  SizedBox(width: 10.w),
                                  Text(
                                    tr('Log Out', settings.isHindi),
                                    style: GoogleFonts.inter(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFFEF4444)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 100.h),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildMiniStat(String value, String label, IconData icon, ColorScheme colorScheme, {bool isAlert = false}) {
    final color = isAlert ? const Color(0xFFEF4444) : colorScheme.primary;
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 20.sp),
          SizedBox(height: 6.h),
          Text(value,
              style: GoogleFonts.inter(fontSize: 20.sp, fontWeight: FontWeight.w800, color: color)),
          SizedBox(height: 2.h),
          Text(label,
              style: GoogleFonts.inter(fontSize: 11.sp, color: colorScheme.onSurface.withOpacity(0.5)),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Container(
      height: 40.h,
      width: 1,
      color: Colors.grey.withOpacity(isDark ? 0.15 : 0.2),
    );
  }

  Widget _buildActionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required ThemeData theme,
    required Color textColor,
    required Color textDimColor,
    required bool isDark,
    required Color iconColor,
  }) {
    return AnimatedScaleButton(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 16.h),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(color: theme.colorScheme.onSurface.withOpacity(0.06)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.15 : 0.03),
              blurRadius: 10.r,
              offset: Offset(0, 3.h),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(icon, color: iconColor, size: 20.sp),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Text(title,
                  style: GoogleFonts.inter(
                      fontSize: 15.sp, fontWeight: FontWeight.w600, color: textColor)),
            ),
            Icon(Icons.chevron_right_rounded, color: textDimColor, size: 20.sp),
          ],
        ),
      ),
    );
  }
}
