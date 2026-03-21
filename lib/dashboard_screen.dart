import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import 'upload_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';
import 'utils/animations.dart';
import 'package:provider/provider.dart';
import 'providers/settings_provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const _HomeView(),
    const HistoryScreen(isTab: true),
    const ProfileScreen(isTab: true),
  ];

  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = Provider.of<SettingsProvider>(context);
    final bool isHindi = settings.isHindi;

    return Scaffold(
      extendBody: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      body: AnimatedSwitcher(duration: const Duration(milliseconds: 300), child: _pages[_currentIndex]),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: theme.bottomNavigationBarTheme.backgroundColor,
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.shadow.withOpacity(0.1),
              blurRadius: 20.r,
              offset: Offset(0.w, -5.h),
            )
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            child: BottomNavigationBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              selectedItemColor: theme.bottomNavigationBarTheme.selectedItemColor,
              unselectedItemColor: theme.bottomNavigationBarTheme.unselectedItemColor,
              currentIndex: _currentIndex,
              onTap: _onTabTapped,
              type: BottomNavigationBarType.fixed,
              selectedLabelStyle: GoogleFonts.inter(fontSize: 12.sp, fontWeight: FontWeight.w600),
              unselectedLabelStyle: GoogleFonts.inter(fontSize: 12.sp),
              items: [
                BottomNavigationBarItem(icon: const Icon(Icons.home_outlined), activeIcon: const Icon(Icons.home_rounded), label: tr('Home', isHindi)),
                BottomNavigationBarItem(icon: const Icon(Icons.history_outlined), activeIcon: const Icon(Icons.history_rounded), label: tr('History', isHindi)),
                BottomNavigationBarItem(icon: const Icon(Icons.person_outline), activeIcon: const Icon(Icons.person_rounded), label: tr('Profile', isHindi)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final textColor = colorScheme.onSurface;
    final textDimColor = colorScheme.onSurface.withOpacity(0.54);
    final cardColor = theme.cardColor;

    final settings = Provider.of<SettingsProvider>(context);
    final bool isHindi = settings.isHindi;
    final String userName = settings.privacyMode ? 'R**' : 'Raj';

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0.w, vertical: 24.0.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  StaggeredListItem(
                    index: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            tr('Hi, Raj 👋', isHindi).replaceAll('Raj', userName),
                            style: GoogleFonts.inter(fontSize: 28.sp, fontWeight: FontWeight.w700, letterSpacing: -0.5, color: textColor),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: 16.w),
                        AnimatedScaleButton(
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen(isTab: false)));
                          },
                          child: Container(
                            padding: EdgeInsets.all(8.w),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: theme.cardColor,
                              border: Border.all(color: colorScheme.onSurface.withOpacity(0.08)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                                  blurRadius: 10.r,
                                  offset: Offset(0, 4.h),
                                ),
                              ]
                            ),
                            child: CircleAvatar(radius: 20.r, backgroundColor: Colors.transparent, child: Icon(Icons.person_outline, color: theme.primaryColor)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 48.h),

                  StaggeredListItem(
                    index: 1,
                    child: AnimatedScaleButton(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UploadScreen())),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 40.h, horizontal: 24.w),
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          borderRadius: BorderRadius.circular(24.r),
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.primary.withOpacity(0.3),
                              blurRadius: 20.r, 
                              offset: Offset(0.w, 10.h)
                            )
                          ],
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: EdgeInsets.all(16.w),
                              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                              child: Icon(Icons.document_scanner_rounded, size: 40.sp, color: Colors.white),
                            ),
                            SizedBox(height: 20.h),
                            Text(tr('Upload Documents', isHindi), style: GoogleFonts.inter(fontSize: 22.sp, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: -0.5)),
                            SizedBox(height: 8.h),
                            Text(tr('Tap to start a new analysis', isHindi), style: GoogleFonts.inter(fontSize: 14.sp, color: Colors.white.withOpacity(0.8))),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 40.h),

                  StaggeredListItem(
                    index: 2,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStatCard(tr('Last Scan', isHindi), tr('Today', isHindi), cardColor, textColor, textDimColor, isDark, colorScheme),
                        SizedBox(width: 12.w),
                        _buildStatCard(tr('Total', isHindi), '42', cardColor, textColor, textDimColor, isDark, colorScheme),
                        SizedBox(width: 12.w),
                        _buildStatCard(tr('Matches', isHindi), '94%', cardColor, textColor, textDimColor, isDark, colorScheme),
                      ],
                    ),
                  ),
                  SizedBox(height: 40.h),

                  StaggeredListItem(
                    index: 3,
                    child: Text(tr('Recent Activity', isHindi), style: GoogleFonts.inter(fontSize: 18.sp, fontWeight: FontWeight.bold, letterSpacing: -0.5, color: textColor)),
                  ),
                  SizedBox(height: 16.h),
                  
                  StaggeredListItem(
                    index: 4,
                    child: _buildRecentActivityItem('Passport Verification', '17 Mar 2026', true, cardColor, textColor, textDimColor, isDark, colorScheme),
                  ),
                  StaggeredListItem(
                    index: 5,
                    child: _buildRecentActivityItem('Utility Bill Check', '15 Mar 2026', false, cardColor, textColor, textDimColor, isDark, colorScheme),
                  ),
                  StaggeredListItem(
                    index: 6,
                    child: _buildRecentActivityItem('Driver License', '10 Mar 2026', true, cardColor, textColor, textDimColor, isDark, colorScheme),
                  ),
                  SizedBox(height: 24.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color cardColor, Color textColor, Color textDimColor, bool isDark, ColorScheme colorScheme) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 12.w),
        decoration: BoxDecoration(
          color: cardColor, 
          borderRadius: BorderRadius.circular(16.r), 
          border: Border.all(color: colorScheme.onSurface.withOpacity(0.05), width: 1.w),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.02),
              blurRadius: 10.r,
              offset: Offset(0, 4.h),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: GoogleFonts.inter(fontSize: 12.sp, color: textDimColor, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
            SizedBox(height: 8.h),
            Text(value, style: GoogleFonts.inter(fontSize: 16.sp, color: textColor, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivityItem(String title, String date, bool isMatch, Color cardColor, Color textColor, Color textDimColor, bool isDark, ColorScheme colorScheme) {
    final color = isMatch ? const Color(0xFF10B981) : Colors.redAccent;
    final status = isMatch ? 'Match' : 'Mismatch';

    return Padding(
      padding: EdgeInsets.only(bottom: 12.0.h),
      child: AnimatedScaleButton(
        onTap: () {}, // would go to result ideally
        child: Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: cardColor, 
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: colorScheme.onSurface.withOpacity(0.05), width: 1.w),
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
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(color: colorScheme.onSurface.withOpacity(0.04), borderRadius: BorderRadius.circular(12.r)),
                child: Icon(Icons.description_outlined, color: textDimColor, size: 24.sp),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: GoogleFonts.inter(fontSize: 15.sp, fontWeight: FontWeight.w600, color: textColor)),
                    SizedBox(height: 4.h),
                    Text(date, style: GoogleFonts.inter(fontSize: 13.sp, color: textDimColor, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20.r), border: Border.all(color: color.withOpacity(0.2))),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 6.w, height: 6.h, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                    SizedBox(width: 6.w),
                    Text(status, style: GoogleFonts.inter(fontSize: 12.sp, fontWeight: FontWeight.bold, color: color)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
