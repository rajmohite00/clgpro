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
import 'providers/theme_provider.dart';
import 'utils/animations.dart';

class ProfileScreen extends StatelessWidget {
  final bool isTab;
  const ProfileScreen({super.key, this.isTab = false});

  Future<void> _logout(BuildContext context, bool isHindi) async {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark ? AppTheme.surfaceDark : Colors.white;
    final textColor = isDark ? Colors.white : AppTheme.textPrimary;
    final mutedColor = isDark ? Colors.white54 : AppTheme.textSecondary;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: Text(tr('Confirm Logout', isHindi),
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: textColor)),
        content: Text(tr('Are you sure you want to log out?', isHindi),
            style: GoogleFonts.inter(color: mutedColor)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(tr('Cancel', isHindi),
                style: GoogleFonts.inter(color: AppTheme.secondary, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(tr('Log Out', isHindi),
                style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.check_circle_outlined, color: Colors.white, size: 16),
        const SizedBox(width: 8),
        Text(tr('Logged out successfully', isHindi), style: GoogleFonts.inter(color: Colors.white)),
      ]),
      backgroundColor: AppTheme.success,
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
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark ? AppTheme.primary : AppTheme.neutral;
    final cardColor = isDark ? AppTheme.surfaceDark : Colors.white;
    final textColor = isDark ? Colors.white : AppTheme.textPrimary;
    final mutedColor = isDark ? Colors.white54 : AppTheme.textSecondary;
    final borderColor = isDark ? AppTheme.borderDark : AppTheme.borderLight;

    final String displayName = settings.privacyMode ? 'R**' : userProvider.name;
    final String displayEmail = settings.privacyMode ? 'r**@example.com' : userProvider.email;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: isTab
          ? null
          : AppBar(
              backgroundColor: isDark ? AppTheme.primary : Colors.white,
              elevation: 0,
              surfaceTintColor: Colors.transparent,
              title: Text(tr('Profile', settings.isHindi),
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18.sp, color: textColor)),
              bottom: PreferredSize(
                preferredSize: Size.fromHeight(1.h),
                child: Divider(height: 1, color: borderColor),
              ),
            ),
      body: SafeArea(
        child: userProvider.isLoading
            ? Center(child: CircularProgressIndicator(color: AppTheme.secondary))
            : Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
                    child: Column(
                      children: [
                        // ── Avatar Section ─────────────────────────────────
                        StaggeredListItem(
                          index: 0,
                          child: Center(
                            child: Column(
                              children: [
                                // Avatar with blue ring
                                Container(
                                  padding: EdgeInsets.all(3.w),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: AppTheme.secondary, width: 2.5),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.secondary.withOpacity(0.20),
                                        blurRadius: 14.r,
                                      ),
                                    ],
                                  ),
                                  child: CircleAvatar(
                                    radius: 44.r,
                                    backgroundColor: AppTheme.blueLight,
                                    child: Text(
                                      displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                                      style: GoogleFonts.inter(
                                        fontSize: 32.sp,
                                        fontWeight: FontWeight.w800,
                                        color: AppTheme.secondary,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 14.h),
                                Text(
                                  displayName,
                                  style: GoogleFonts.inter(
                                    fontSize: 22.sp,
                                    fontWeight: FontWeight.w800,
                                    color: textColor,
                                    letterSpacing: -0.4,
                                  ),
                                ),
                                SizedBox(height: 4.h),
                                Text(displayEmail,
                                    style: GoogleFonts.inter(fontSize: 13.sp, color: mutedColor)),
                                SizedBox(height: 12.h),
                                // Verified badge
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
                                  decoration: BoxDecoration(
                                    color: AppTheme.blueLight,
                                    borderRadius: BorderRadius.circular(20.r),
                                    border: Border.all(color: AppTheme.blueMid),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.verified_rounded, color: AppTheme.secondary, size: 13.sp),
                                      SizedBox(width: 5.w),
                                      Text(
                                        'Verified User',
                                        style: GoogleFonts.inter(
                                          fontSize: 11.sp,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.secondary,
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

                        // ── Stats Card ─────────────────────────────────────
                        StaggeredListItem(
                          index: 1,
                          child: Container(
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(20.r),
                              border: Border.all(color: borderColor),
                              boxShadow: isDark
                                  ? []
                                  : [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.04),
                                        blurRadius: 12.r,
                                        offset: Offset(0, 4.h),
                                      ),
                                    ],
                            ),
                            child: Row(
                              children: [
                                _buildStat('42', 'Total Scans', Icons.document_scanner_rounded,
                                    AppTheme.secondary, textColor, mutedColor),
                                Container(width: 1, height: 48.h, color: borderColor),
                                _buildStat('38', 'Verified', Icons.verified_rounded,
                                    AppTheme.success, textColor, mutedColor),
                                Container(width: 1, height: 48.h, color: borderColor),
                                _buildStat('4', 'Flagged', Icons.flag_rounded,
                                    AppTheme.error, textColor, mutedColor),
                              ],
                            ),
                          ),
                        ),

                        SizedBox(height: 28.h),

                        // ── Account Section ────────────────────────────────
                        _sectionHeader('ACCOUNT', AppTheme.secondary),
                        SizedBox(height: 10.h),

                        StaggeredListItem(
                          index: 2,
                          child: _buildActionTile(
                            icon: Icons.edit_rounded,
                            title: tr('Edit Profile', settings.isHindi),
                            subtitle: tr('Update name, email and bio', settings.isHindi),
                            iconColor: AppTheme.secondary,
                            cardColor: cardColor,
                            textColor: textColor,
                            mutedColor: mutedColor,
                            borderColor: borderColor,
                            isDark: isDark,
                            onTap: () => Navigator.push(
                                context, MaterialPageRoute(builder: (_) => const EditProfileScreen())),
                          ),
                        ),
                        SizedBox(height: 10.h),

                        StaggeredListItem(
                          index: 3,
                          child: _buildActionTile(
                            icon: Icons.lock_rounded,
                            title: tr('Change Password', settings.isHindi),
                            subtitle: tr('Update your security credentials', settings.isHindi),
                            iconColor: const Color(0xFF8B5CF6),
                            cardColor: cardColor,
                            textColor: textColor,
                            mutedColor: mutedColor,
                            borderColor: borderColor,
                            isDark: isDark,
                            onTap: () => Navigator.push(
                                context, MaterialPageRoute(builder: (_) => const ChangePasswordScreen())),
                          ),
                        ),
                        SizedBox(height: 10.h),

                        StaggeredListItem(
                          index: 4,
                          child: _buildActionTile(
                            icon: Icons.settings_rounded,
                            title: tr('Settings', settings.isHindi),
                            subtitle: tr('Theme, language and preferences', settings.isHindi),
                            iconColor: AppTheme.success,
                            cardColor: cardColor,
                            textColor: textColor,
                            mutedColor: mutedColor,
                            borderColor: borderColor,
                            isDark: isDark,
                            onTap: () => Navigator.push(
                                context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
                          ),
                        ),

                        SizedBox(height: 28.h),

                        // ── Logout Button ──────────────────────────────────
                        StaggeredListItem(
                          index: 5,
                          child: AnimatedScaleButton(
                            onTap: () => _logout(context, settings.isHindi),
                            child: Container(
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(vertical: 16.h),
                              decoration: BoxDecoration(
                                color: AppTheme.error.withOpacity(isDark ? 0.10 : 0.06),
                                borderRadius: BorderRadius.circular(16.r),
                                border: Border.all(color: AppTheme.error.withOpacity(0.25)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.logout_rounded, color: AppTheme.error, size: 18.sp),
                                  SizedBox(width: 10.w),
                                  Text(
                                    tr('Log Out', settings.isHindi),
                                    style: GoogleFonts.inter(
                                      fontSize: 15.sp,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.error,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 80.h),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _sectionHeader(String label, Color color) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          Container(
            width: 3.w,
            height: 14.h,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2.r)),
          ),
          SizedBox(width: 8.w),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(
      String value, String label, IconData icon, Color color, Color textColor, Color mutedColor) {
    return Expanded(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 18.h),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18.sp),
            SizedBox(height: 6.h),
            Text(value,
                style: GoogleFonts.inter(fontSize: 20.sp, fontWeight: FontWeight.w800, color: textColor)),
            SizedBox(height: 2.h),
            Text(label,
                style: GoogleFonts.inter(fontSize: 11.sp, color: mutedColor),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color iconColor,
    required Color cardColor,
    required Color textColor,
    required Color mutedColor,
    required Color borderColor,
    required bool isDark,
  }) {
    return AnimatedScaleButton(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: borderColor),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8.r,
                    offset: Offset(0, 2.h),
                  ),
                ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.10),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(icon, color: iconColor, size: 18.sp),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.inter(
                          fontSize: 14.sp, fontWeight: FontWeight.w700, color: textColor)),
                  SizedBox(height: 2.h),
                  Text(subtitle,
                      style: GoogleFonts.inter(fontSize: 12.sp, color: mutedColor)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: mutedColor, size: 20.sp),
          ],
        ),
      ),
    );
  }
}
