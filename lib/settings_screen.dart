import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'providers/theme_provider.dart';
import 'providers/settings_provider.dart';

import 'utils/animations.dart';

// Preset accent colors
const _accentColors = [
  Color(0xFF3B82F6), // Blue (default)
  Color(0xFF6366F1), // Indigo
  Color(0xFF8B5CF6), // Purple
  Color(0xFFEC4899), // Pink
  Color(0xFFEF4444), // Red
  Color(0xFFF59E0B), // Amber
  Color(0xFF10B981), // Emerald
  Color(0xFF06B6D4), // Cyan
  Color(0xFF0EA5E9), // Sky
  Color(0xFF14B8A6), // Teal
];

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final settings = Provider.of<SettingsProvider>(context);
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
        title: Text(
          tr('Settings', settings.isHindi),
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontSize: 18.sp,
            color: textColor,
          ),
        ),
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
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
          children: [
            // ── Preferences ────────────────────────────────────────────
            StaggeredListItem(
              index: 0,
              child: _sectionHeader('PREFERENCES', AppTheme.jade),
            ),
            SizedBox(height: 12.h),

            StaggeredListItem(
              index: 1,
              child: _buildSwitchTile(
                title: tr('Language', settings.isHindi),
                subtitle: tr('Switch between English and Hindi', settings.isHindi),
                value: settings.isHindi,
                onChanged: (val) => settings.toggleLanguage(val),
                icon: Icons.language_rounded,
                iconColor: AppTheme.jade,
                cardColor: cardColor,
                textColor: textColor,
                mutedColor: mutedColor,
                borderColor: borderColor,
                isDark: isDark,
              ),
            ),
            SizedBox(height: 10.h),

            StaggeredListItem(
              index: 2,
              child: _buildSwitchTile(
                title: tr('Dark Mode', settings.isHindi),
                subtitle: tr('Toggle dark and light themes', settings.isHindi),
                value: themeProvider.isDarkMode,
                onChanged: (val) => themeProvider.toggleTheme(val),
                icon: isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                iconColor: const Color(0xFFF59E0B),
                cardColor: cardColor,
                textColor: textColor,
                mutedColor: mutedColor,
                borderColor: borderColor,
                isDark: isDark,
              ),
            ),
            SizedBox(height: 10.h),

            StaggeredListItem(
              index: 3,
              child: _buildSwitchTile(
                title: tr('Push Notifications', settings.isHindi),
                subtitle: tr('Alert when analysis finishes', settings.isHindi),
                value: settings.notificationsEnabled,
                onChanged: (val) => settings.toggleNotifications(val),
                icon: Icons.notifications_rounded,
                iconColor: AppTheme.success,
                cardColor: cardColor,
                textColor: textColor,
                mutedColor: mutedColor,
                borderColor: borderColor,
                isDark: isDark,
              ),
            ),
            SizedBox(height: 10.h),

            SizedBox(height: 28.h),

            // ── Appearance ──────────────────────────────────────────────
            StaggeredListItem(
              index: 5,
              child: _sectionHeader('APPEARANCE', AppTheme.jade),
            ),
            SizedBox(height: 12.h),

            // Accent Color Picker
            StaggeredListItem(
              index: 6,
              child: Container(
                padding: EdgeInsets.all(16.w),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(10.w),
                          decoration: BoxDecoration(
                            color: themeProvider.accentColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Icon(Icons.palette_rounded,
                              color: themeProvider.accentColor, size: 18.sp),
                        ),
                        SizedBox(width: 14.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(tr('Accent Color', settings.isHindi),
                                  style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w700,
                                      color: textColor,
                                      fontSize: 14.sp)),
                              SizedBox(height: 2.h),
                              Text(tr('Personalize your app color', settings.isHindi),
                                  style: GoogleFonts.inter(fontSize: 12.sp, color: mutedColor)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),
                    Wrap(
                      spacing: 10.w,
                      runSpacing: 10.h,
                      children: _accentColors.map((color) {
                        final isSelected = themeProvider.accentColor.value == color.value;
                        return GestureDetector(
                          onTap: () {
                            themeProvider.setAccentColor(color);
                            settings.setAccentColor(color);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 36.w,
                            height: 36.w,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: isSelected
                                  ? Border.all(
                                      color: isDark ? AppTheme.jade : AppTheme.inkLight,
                                      width: 3,
                                    )
                                  : null,
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: color.withOpacity(0.5),
                                        blurRadius: 8.r,
                                        spreadRadius: 1,
                                      )
                                    ]
                                  : [],
                            ),
                            child: isSelected
                                ? Icon(Icons.check_rounded, color: Colors.white, size: 18.sp)
                                : null,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 28.h),

            // ── Data Management ────────────────────────────────────────
            StaggeredListItem(
              index: 9,
              child: _sectionHeader('DATA MANAGEMENT', AppTheme.error),
            ),
            SizedBox(height: 12.h),

            StaggeredListItem(
              index: 10,
              child: AnimatedScaleButton(
                onTap: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: cardColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
                      title: Text(tr('Clear History?', settings.isHindi),
                          style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: textColor)),
                      content: Text(
                          'This cannot be undone. All local scan records will be deleted.',
                          style: GoogleFonts.inter(color: mutedColor)),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: Text('Cancel', style: GoogleFonts.inter(color: mutedColor)),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.error,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                          ),
                          child: Text(tr('Delete', settings.isHindi),
                              style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await settings.clearHistory();
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(tr('History cleared.', settings.isHindi), style: GoogleFonts.inter(color: Colors.white)),
                      backgroundColor: AppTheme.success,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                      margin: EdgeInsets.all(16.w),
                    ));
                  }
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 16.h),
                  decoration: BoxDecoration(
                    color: AppTheme.error.withOpacity(isDark ? 0.10 : 0.05),
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: AppTheme.error.withOpacity(0.25)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(10.w),
                        decoration: BoxDecoration(
                          color: AppTheme.error.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Icon(Icons.delete_forever_rounded, color: AppTheme.error, size: 20.sp),
                      ),
                      SizedBox(width: 14.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(tr('Clear All History', settings.isHindi),
                                style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w700, color: AppTheme.error, fontSize: 14.sp)),
                            SizedBox(height: 2.h),
                            Text(tr('Permanently delete scan history', settings.isHindi),
                                style: GoogleFonts.inter(color: AppTheme.error.withOpacity(0.7), fontSize: 12.sp)),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded, color: AppTheme.error.withOpacity(0.6), size: 20.sp),
                    ],
                  ),
                ),
              ),
            ),

            SizedBox(height: 28.h),

            // ── About ──────────────────────────────────────────────────
            StaggeredListItem(
              index: 11,
              child: _sectionHeader('ABOUT', AppTheme.jade),
            ),
            SizedBox(height: 12.h),

            StaggeredListItem(
              index: 12,
              child: _buildInfoTile(
                title: tr('Data Privacy Policy', settings.isHindi),
                subtitle: 'How we secure your documents',
                icon: Icons.privacy_tip_rounded,
                iconColor: AppTheme.jade,
                cardColor: cardColor,
                textColor: textColor,
                mutedColor: mutedColor,
                borderColor: borderColor,
                isDark: isDark,
              ),
            ),
            SizedBox(height: 10.h),

            StaggeredListItem(
              index: 13,
              child: _buildInfoTile(
                title: tr('Terms of Service', settings.isHindi),
                icon: Icons.description_rounded,
                iconColor: const Color(0xFF8B5CF6),
                cardColor: cardColor,
                textColor: textColor,
                mutedColor: mutedColor,
                borderColor: borderColor,
                isDark: isDark,
              ),
            ),
            SizedBox(height: 10.h),

            StaggeredListItem(
              index: 14,
              child: _buildInfoTile(
                title: tr('Application Version', settings.isHindi),
                subtitle: 'v1.2.0',
                icon: Icons.info_rounded,
                iconColor: AppTheme.success,
                cardColor: cardColor,
                textColor: textColor,
                mutedColor: mutedColor,
                borderColor: borderColor,
                isDark: isDark,
              ),
            ),

            SizedBox(height: 48.h),

            // ── Footer ─────────────────────────────────────────────────
            StaggeredListItem(
              index: 15,
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      color: AppTheme.jade.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.document_scanner_rounded, size: 14.sp, color: AppTheme.jade),
                        SizedBox(width: 6.w),
                        Text(
                          'Smart Document Detective',
                          style: GoogleFonts.inter(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.jade,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Built with ❤️ by Team',
                    style: GoogleFonts.inter(fontSize: 11.sp, color: mutedColor),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String label, Color color) {
    return Padding(
      padding: EdgeInsets.only(left: 4.w, bottom: 0),
      child: Row(
        children: [
          Container(
            width: 3.w,
            height: 14.h,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2.r),
            ),
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

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
    required Color iconColor,
    required Color cardColor,
    required Color textColor,
    required Color mutedColor,
    required Color borderColor,
    required bool isDark,
  }) {
    return Container(
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
                        fontWeight: FontWeight.w700, color: textColor, fontSize: 14.sp)),
                SizedBox(height: 2.h),
                Text(subtitle,
                    style: GoogleFonts.inter(fontSize: 12.sp, color: mutedColor)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: iconColor,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile({
    required String title,
    String? subtitle,
    required IconData icon,
    required Color iconColor,
    required Color cardColor,
    required Color textColor,
    required Color mutedColor,
    required Color borderColor,
    required bool isDark,
  }) {
    return AnimatedScaleButton(
      onTap: () {},
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
                          fontWeight: FontWeight.w700, color: textColor, fontSize: 14.sp)),
                  if (subtitle != null) ...[
                    SizedBox(height: 2.h),
                    Text(subtitle,
                        style: GoogleFonts.inter(fontSize: 12.sp, color: mutedColor)),
                  ],
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
