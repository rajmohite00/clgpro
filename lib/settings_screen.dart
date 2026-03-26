import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'providers/theme_provider.dart';
import 'providers/settings_provider.dart';
import 'utils/animations.dart';

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
    final colorScheme = theme.colorScheme;
    final textColor = colorScheme.onSurface;
    final textDimColor = colorScheme.onSurface.withOpacity(0.52);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        title: Text(tr('Settings', settings.isHindi),
            style: GoogleFonts.inter(color: textColor, fontWeight: FontWeight.w700, fontSize: 18.sp)),
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
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
      ),
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
          children: [
            SizedBox(height: 8.h),
            StaggeredListItem(
              index: 0,
              child: _buildSectionLabel(tr('Preferences', settings.isHindi), colorScheme.primary),
            ),
            SizedBox(height: 12.h),
            StaggeredListItem(
              index: 1,
              child: _buildSwitchTile(
                title: tr('Language', settings.isHindi),
                subtitle: tr('Switch language between English and Hindi.', settings.isHindi),
                value: settings.isHindi,
                onChanged: (val) => settings.toggleLanguage(val),
                iconData: Icons.language_rounded,
                iconColor: const Color(0xFF6366F1),
                theme: theme,
                isDark: isDark,
                textColor: textColor,
                textDimColor: textDimColor,
              ),
            ),
            SizedBox(height: 10.h),
            StaggeredListItem(
              index: 2,
              child: _buildSwitchTile(
                title: tr('Dark Mode', settings.isHindi),
                subtitle: tr('Toggle dark and light themes dynamically.', settings.isHindi),
                value: themeProvider.isDarkMode,
                onChanged: (val) => themeProvider.toggleTheme(val),
                iconData: isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                iconColor: const Color(0xFFF59E0B),
                theme: theme,
                isDark: isDark,
                textColor: textColor,
                textDimColor: textDimColor,
              ),
            ),
            SizedBox(height: 10.h),
            StaggeredListItem(
              index: 3,
              child: _buildSwitchTile(
                title: tr('Push Notifications', settings.isHindi),
                subtitle: tr('Alert me instantly when remote analysis finishes.', settings.isHindi),
                value: settings.notificationsEnabled,
                onChanged: (val) => settings.toggleNotifications(val),
                iconData: Icons.notifications_rounded,
                iconColor: const Color(0xFF10B981),
                theme: theme,
                isDark: isDark,
                textColor: textColor,
                textDimColor: textDimColor,
              ),
            ),
            SizedBox(height: 10.h),
            StaggeredListItem(
              index: 4,
              child: _buildSwitchTile(
                title: tr('Privacy Mode', settings.isHindi),
                subtitle: tr('Hide sensitive data on dashboards and reports.', settings.isHindi),
                value: settings.privacyMode,
                onChanged: (val) => settings.togglePrivacyMode(val),
                iconData: Icons.privacy_tip_rounded,
                iconColor: const Color(0xFF8B5CF6),
                theme: theme,
                isDark: isDark,
                textColor: textColor,
                textDimColor: textDimColor,
              ),
            ),
            SizedBox(height: 28.h),

            StaggeredListItem(
              index: 5,
              child: _buildSectionLabel(tr('Data Management', settings.isHindi), const Color(0xFFEF4444)),
            ),
            SizedBox(height: 12.h),

            StaggeredListItem(
              index: 6,
              child: AnimatedScaleButton(
                onTap: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: theme.cardColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
                      title: Text('Clear History?',
                          style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: textColor)),
                      content: Text(
                          'This action cannot be undone. Are you sure you want to delete all local scan records?',
                          style: GoogleFonts.inter(color: textDimColor)),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text('Cancel', style: GoogleFonts.inter(color: textDimColor)),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEF4444),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                          ),
                          child: Text('Delete',
                              style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    await settings.clearHistory();
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('History cleared successfully.'),
                        backgroundColor: const Color(0xFF10B981),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                        margin: EdgeInsets.all(16.w),
                      ),
                    );
                  }
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 18.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withOpacity(isDark ? 0.08 : 0.05),
                    borderRadius: BorderRadius.circular(18.r),
                    border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.25)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(10.w),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Icon(Icons.delete_forever_rounded, color: const Color(0xFFEF4444), size: 20.sp),
                      ),
                      SizedBox(width: 14.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tr('Clear All History', settings.isHindi),
                              style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFFEF4444),
                                  fontSize: 15.sp),
                            ),
                            SizedBox(height: 3.h),
                            Text(
                              tr('Permanently delete entire scan history from device.', settings.isHindi),
                              style: GoogleFonts.inter(
                                  color: const Color(0xFFEF4444).withOpacity(0.65), fontSize: 12.sp),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded,
                          color: const Color(0xFFEF4444).withOpacity(0.6), size: 20.sp),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 28.h),

            StaggeredListItem(
              index: 7,
              child: _buildSectionLabel(tr('About & Privacy', settings.isHindi), colorScheme.primary),
            ),
            SizedBox(height: 12.h),

            StaggeredListItem(
              index: 8,
              child: _buildInfoTile(
                title: tr('Data Privacy Policy', settings.isHindi),
                subtitle: 'How we secure your documents',
                icon: Icons.privacy_tip_rounded,
                iconColor: const Color(0xFF6366F1),
                theme: theme,
                textColor: textColor,
                textDimColor: textDimColor,
                isDark: isDark,
              ),
            ),
            SizedBox(height: 10.h),
            StaggeredListItem(
              index: 9,
              child: _buildInfoTile(
                title: tr('Terms of Service', settings.isHindi),
                icon: Icons.description_rounded,
                iconColor: const Color(0xFF8B5CF6),
                theme: theme,
                textColor: textColor,
                textDimColor: textDimColor,
                isDark: isDark,
              ),
            ),
            SizedBox(height: 10.h),
            StaggeredListItem(
              index: 10,
              child: _buildInfoTile(
                title: tr('Application Version', settings.isHindi),
                subtitle: 'v1.1.0',
                icon: Icons.info_rounded,
                iconColor: const Color(0xFF10B981),
                theme: theme,
                textColor: textColor,
                textDimColor: textDimColor,
                isDark: isDark,
              ),
            ),
            SizedBox(height: 48.h),

            // Footer
            StaggeredListItem(
              index: 11,
              child: Center(
                child: Text(
                  'Smart Document Detective',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    color: textDimColor.withOpacity(0.5),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            SizedBox(height: 8.h),
            StaggeredListItem(
              index: 12,
              child: Center(
                child: Text(
                  'Built with ❤️ by Team',
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    color: textDimColor.withOpacity(0.35),
                  ),
                ),
              ),
            ),
            SizedBox(height: 48.h),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label, Color color) {
    return Padding(
      padding: EdgeInsets.only(left: 4.w),
      child: Row(
        children: [
          Container(
            width: 4.w,
            height: 16.h,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          SizedBox(width: 8.w),
          Text(
            label.toUpperCase(),
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
    required IconData iconData,
    required Color iconColor,
    required ThemeData theme,
    required bool isDark,
    required Color textColor,
    required Color textDimColor,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
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
            child: Icon(iconData, color: iconColor, size: 20.sp),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700, color: textColor, fontSize: 14.sp)),
                SizedBox(height: 3.h),
                Text(subtitle,
                    style: GoogleFonts.inter(fontSize: 12.sp, color: textDimColor)),
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
    required ThemeData theme,
    required Color textColor,
    required Color textDimColor,
    required bool isDark,
  }) {
    return AnimatedScaleButton(
      onTap: () {},
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
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
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700, color: textColor, fontSize: 14.sp)),
                  if (subtitle != null) ...[
                    SizedBox(height: 3.h),
                    Text(subtitle, style: GoogleFonts.inter(color: textDimColor, fontSize: 12.sp)),
                  ]
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: textDimColor, size: 20.sp),
          ],
        ),
      ),
    );
  }
}
