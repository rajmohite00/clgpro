import 'dart:io';
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

// ─────────────────────────────────────────────────────────────────────────────
//  PROFILE SCREEN  — Minimal Government UI
// ─────────────────────────────────────────────────────────────────────────────

class ProfileScreen extends StatelessWidget {
  final bool isTab;
  const ProfileScreen({super.key, this.isTab = false});

  Future<void> _logout(BuildContext context, bool isHindi) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('Confirm Logout', isHindi),
            style: GoogleFonts.inter(
                fontWeight: FontWeight.w700, fontSize: 16.sp)),
        content: Text(tr('Are you sure you want to log out?', isHindi),
            style: GoogleFonts.inter(fontSize: 13.sp)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(tr('Cancel', isHindi),
                style: GoogleFonts.inter(fontSize: 13.sp)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(tr('Log Out', isHindi),
                style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13.sp)),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(tr('Logged out successfully', isHindi),
          style: GoogleFonts.inter(color: Colors.white, fontSize: 13.sp)),
      backgroundColor: AppTheme.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6.r)),
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
    final user     = Provider.of<UserProvider>(context);
    final settings = Provider.of<SettingsProvider>(context);
    final theme    = Theme.of(context);
    final cs       = theme.colorScheme;
    final isDark   = theme.brightness == Brightness.dark;
    final isHindi  = settings.isHindi;

    final textPri = cs.onSurface;
    final textSec = cs.onSurface.withOpacity(0.5);
    final divClr  = theme.dividerColor;
    final bgCard  = isDark ? const Color(0xFF1E2A3D) : Colors.white;
    final border  = isDark ? AppTheme.borderDark : AppTheme.borderLight;

    final displayName  = user.name;
    final displayEmail = user.email;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: isTab
          ? null
          : AppBar(
              backgroundColor: isDark ? const Color(0xFF0D1526) : Colors.white,
              elevation: 0,
              surfaceTintColor: Colors.transparent,
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(1),
                child: Divider(height: 1, color: divClr),
              ),
              leading: IconButton(
                icon: Icon(Icons.arrow_back_rounded,
                    color: textPri, size: 20.sp),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(tr('Profile', isHindi),
                  style: GoogleFonts.inter(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: textPri)),
            ),
      body: SafeArea(
        child: user.isLoading
            ? Center(
                child: CircularProgressIndicator(
                    color: cs.primary, strokeWidth: 2))
            : SingleChildScrollView(
                padding: EdgeInsets.all(20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [

                    // ── Avatar + Name ───────────────────────────────────────
                    Center(
                      child: Column(children: [
                        // Avatar
                        CircleAvatar(
                          radius: 38.r,
                          backgroundColor: cs.primary.withOpacity(0.1),
                          backgroundImage: user.profilePicPath != null
                              ? FileImage(File(user.profilePicPath!))
                              : null,
                          child: user.profilePicPath == null
                              ? Text(
                                  displayName.isNotEmpty
                                      ? displayName[0].toUpperCase()
                                      : 'U',
                                  style: GoogleFonts.inter(
                                    fontSize: 26.sp,
                                    fontWeight: FontWeight.w800,
                                    color: cs.primary,
                                  ),
                                )
                              : null,
                        ),
                        SizedBox(height: 12.h),
                        Text(displayName,
                            style: GoogleFonts.inter(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w800,
                              color: textPri,
                              letterSpacing: -0.3,
                            )),
                        SizedBox(height: 3.h),
                        Text(displayEmail,
                            style: GoogleFonts.inter(
                                fontSize: 13.sp, color: textSec)),
                      ]),
                    ),
                    SizedBox(height: 24.h),

                    // ── Stats strip ─────────────────────────────────────────
                    Container(
                      decoration: BoxDecoration(
                        color: bgCard,
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(color: border),
                      ),
                      child: Row(children: [
                        _statCell(
                            '${user.totalScans}', 'Scans',
                            textPri, textSec, divClr, false),
                        _statCell(
                            '${user.streakDays}d', 'Streak',
                            textPri, textSec, divClr, true),
                      ]),
                    ),
                    SizedBox(height: 28.h),

                    // ── Account section ─────────────────────────────────────
                    _sectionLabel('ACCOUNT', textSec),
                    SizedBox(height: 8.h),
                    _menuGroup(
                      bgCard: bgCard,
                      border: border,
                      divClr: divClr,
                      items: [
                        _MenuItem(
                          icon: Icons.person_outline_rounded,
                          label: tr('Edit Profile', isHindi),
                          onTap: () => Navigator.push(context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const EditProfileScreen())),
                          cs: cs, textPri: textPri, textSec: textSec,
                        ),
                        _MenuItem(
                          icon: Icons.lock_outline_rounded,
                          label: tr('Change Password', isHindi),
                          onTap: () => Navigator.push(context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const ChangePasswordScreen())),
                          cs: cs, textPri: textPri, textSec: textSec,
                        ),
                        _MenuItem(
                          icon: Icons.settings_outlined,
                          label: tr('Settings', isHindi),
                          onTap: () => Navigator.push(context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const SettingsScreen())),
                          cs: cs, textPri: textPri, textSec: textSec,
                          isLast: true,
                        ),
                      ],
                    ),
                    SizedBox(height: 28.h),

                    // ── Danger section ───────────────────────────────────────
                    _sectionLabel('DANGER ZONE', textSec),
                    SizedBox(height: 8.h),
                    _menuGroup(
                      bgCard: bgCard,
                      border: border,
                      divClr: divClr,
                      items: [
                        _MenuItem(
                          icon: Icons.logout_rounded,
                          label: tr('Log Out', isHindi),
                          onTap: () => _logout(context, isHindi),
                          cs: cs, textPri: textPri, textSec: textSec,
                          isLast: true,
                          isDanger: true,
                        ),
                      ],
                    ),

                    SizedBox(height: 60.h),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _sectionLabel(String text, Color textSec) => Text(text,
      style: GoogleFonts.inter(
          fontSize: 11.sp,
          fontWeight: FontWeight.w700,
          color: textSec,
          letterSpacing: 0.8));

  Widget _statCell(String value, String label, Color textPri, Color textSec,
      Color divClr, bool hasDivider) {
    return Expanded(
      child: Row(children: [
        if (hasDivider)
          Container(width: 1, height: 44.h, color: divClr),
        Expanded(
          child: Padding(
            padding:
                EdgeInsets.symmetric(vertical: 16.h),
            child: Column(children: [
              Text(value,
                  style: GoogleFonts.inter(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w800,
                      color: textPri)),
              SizedBox(height: 2.h),
              Text(label,
                  style: GoogleFonts.inter(
                      fontSize: 11.sp, color: textSec)),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _menuGroup({
    required Color bgCard,
    required Color border,
    required Color divClr,
    required List<_MenuItem> items,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: border),
      ),
      child: Column(children: items.map((item) {
        return Column(children: [
          _menuTile(item),
          if (!item.isLast) Divider(color: divClr, height: 1, indent: 44.w),
        ]);
      }).toList()),
    );
  }

  Widget _menuTile(_MenuItem item) {
    final color = item.isDanger ? AppTheme.error : item.cs.primary;
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(8.r),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        child: Row(children: [
          Icon(item.icon, size: 19.sp, color: color.withOpacity(0.75)),
          SizedBox(width: 14.w),
          Expanded(
            child: Text(item.label,
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: item.isDanger ? AppTheme.error : item.textPri,
                )),
          ),
          Icon(Icons.chevron_right_rounded,
              size: 18.sp, color: item.textSec),
        ]),
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final ColorScheme cs;
  final Color textPri;
  final Color textSec;
  final bool isLast;
  final bool isDanger;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.cs,
    required this.textPri,
    required this.textSec,
    this.isLast = false,
    this.isDanger = false,
  });
}
