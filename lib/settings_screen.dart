import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'providers/theme_provider.dart';
import 'providers/settings_provider.dart';

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
    final textColor = isDark ? Colors.white : Colors.black87;
    final textDimColor = isDark ? Colors.white54 : Colors.black54;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(tr('Settings', settings.isHindi), style: GoogleFonts.inter(color: textColor)),
        backgroundColor: theme.appBarTheme.backgroundColor,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.all(24.0.w),
          children: [
            Text(
              tr('Preferences', settings.isHindi),
              style: GoogleFonts.inter(fontSize: 18.sp, fontWeight: FontWeight.bold, color: theme.primaryColor),
            ),
            SizedBox(height: 16.h),
            _buildSwitchTile(
              title: tr('Language', settings.isHindi),
              subtitle: tr('Switch language between English and Hindi.', settings.isHindi),
              value: settings.isHindi,
              onChanged: (val) => settings.toggleLanguage(val),
              theme: theme,
              textColor: textColor,
              textDimColor: textDimColor,
            ),
            SizedBox(height: 16.h),
            _buildSwitchTile(
              title: tr('Dark Mode', settings.isHindi),
              subtitle: tr('Toggle dark and light themes dynamically.', settings.isHindi),
              value: themeProvider.isDarkMode,
              onChanged: (val) => themeProvider.toggleTheme(val),
              theme: theme,
              textColor: textColor,
              textDimColor: textDimColor,
            ),
            SizedBox(height: 16.h),
            _buildSwitchTile(
              title: tr('Push Notifications', settings.isHindi),
              subtitle: tr('Alert me instantly when remote analysis finishes.', settings.isHindi),
              value: settings.notificationsEnabled,
              onChanged: (val) => settings.toggleNotifications(val),
              theme: theme,
              textColor: textColor,
              textDimColor: textDimColor,
            ),
            SizedBox(height: 16.h),
            _buildSwitchTile(
              title: tr('Privacy Mode', settings.isHindi),
              subtitle: tr('Hide sensitive data on dashboards and reports.', settings.isHindi),
              value: settings.privacyMode,
              onChanged: (val) => settings.togglePrivacyMode(val),
              theme: theme,
              textColor: textColor,
              textDimColor: textDimColor,
            ),
            SizedBox(height: 48.h),
            Text(
              tr('Data Management', settings.isHindi),
              style: GoogleFonts.inter(fontSize: 18.sp, fontWeight: FontWeight.bold, color: Colors.redAccent),
            ),
            SizedBox(height: 16.h),
            Container(
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: Colors.redAccent.withOpacity(0.2)),
              ),
              child: ListTile(
                contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
                leading: Icon(Icons.delete_forever_rounded, color: Colors.redAccent),
                title: Text(tr('Clear All History', settings.isHindi), style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.redAccent)),
                subtitle: Text(tr('Permanently delete entire scan history from device.', settings.isHindi), style: GoogleFonts.inter(color: Colors.redAccent.withOpacity(0.8), fontSize: 13.sp)),
                onTap: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: theme.cardColor,
                      title: Text('Clear History?', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: textColor)),
                      content: Text('This action cannot be undone. Are you sure you want to delete all local scan records?', style: GoogleFonts.inter(color: textDimColor)),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text('Cancel', style: GoogleFonts.inter(color: textDimColor)),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                          child: Text('Delete', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    await settings.clearHistory();
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('History cleared successfully.'), backgroundColor: Colors.green),
                    );
                  }
                },
              ),
            ),
            SizedBox(height: 48.h),
            Text(
              tr('About & Privacy', settings.isHindi),
              style: GoogleFonts.inter(fontSize: 18.sp, fontWeight: FontWeight.bold, color: theme.primaryColor),
            ),
            SizedBox(height: 16.h),
            _buildInfoTile(title: tr('Data Privacy Policy', settings.isHindi), subtitle: 'How we secure your documents', icon: Icons.privacy_tip_outlined, theme: theme, textColor: textColor, textDimColor: textDimColor),
            SizedBox(height: 16.h),
            _buildInfoTile(title: tr('Terms of Service', settings.isHindi), icon: Icons.description_outlined, theme: theme, textColor: textColor, textDimColor: textDimColor),
            SizedBox(height: 16.h),
            _buildInfoTile(title: tr('Application Version', settings.isHindi), subtitle: 'v1.1.0', icon: Icons.info_outline, theme: theme, textColor: textColor, textDimColor: textDimColor),
            SizedBox(height: 40.h),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile({required String title, required String subtitle, required bool value, required ValueChanged<bool> onChanged, required ThemeData theme, required Color textColor, required Color textDimColor}) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 16.w),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: textColor)),
        subtitle: Text(subtitle, style: GoogleFonts.inter(fontSize: 13.sp, color: textDimColor)),
        value: value,
        activeColor: theme.primaryColor,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildInfoTile({required String title, String? subtitle, required IconData icon, required ThemeData theme, required Color textColor, required Color textDimColor}) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
        leading: Container(
           padding: EdgeInsets.all(8.w),
           decoration: BoxDecoration(
             color: theme.primaryColor.withOpacity(0.1),
             borderRadius: BorderRadius.circular(8.r),
           ),
           child: Icon(icon, color: theme.primaryColor),
        ),
        title: Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: textColor)),
        subtitle: subtitle != null ? Text(subtitle, style: GoogleFonts.inter(color: textDimColor, fontSize: 13.sp)) : null,
        trailing: Icon(Icons.chevron_right, color: textDimColor),
        onTap: () {},
      ),
    );
  }
}
