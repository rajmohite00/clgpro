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

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _tabIndicatorController;

  final List<Widget> _pages = [
    const _HomeView(),
    const HistoryScreen(isTab: true),
    const ProfileScreen(isTab: true),
  ];

  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);
    _tabIndicatorController.reset();
    _tabIndicatorController.forward();
  }

  @override
  void initState() {
    super.initState();
    _tabIndicatorController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _tabIndicatorController.forward();
  }

  @override
  void dispose() {
    _tabIndicatorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = Provider.of<SettingsProvider>(context);
    final bool isHindi = settings.isHindi;
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    final navItems = [
      {'icon': Icons.home_outlined, 'activeIcon': Icons.home_rounded, 'label': tr('Home', isHindi)},
      {'icon': Icons.history_outlined, 'activeIcon': Icons.history_rounded, 'label': tr('History', isHindi)},
      {'icon': Icons.person_outline_rounded, 'activeIcon': Icons.person_rounded, 'label': tr('Profile', isHindi)},
    ];

    return Scaffold(
      extendBody: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: child,
        ),
        child: KeyedSubtree(key: ValueKey(_currentIndex), child: _pages[_currentIndex]),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F0E1A) : Colors.white,
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black.withOpacity(0.4) : Colors.black.withOpacity(0.08),
              blurRadius: 24.r,
              offset: Offset(0, -4.h),
            ),
          ],
          border: Border(
            top: BorderSide(
              color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.05),
            ),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 10.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(navItems.length, (i) {
                final item = navItems[i];
                final isSelected = _currentIndex == i;
                return GestureDetector(
                  onTap: () => _onTabTapped(i),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    padding: EdgeInsets.symmetric(horizontal: isSelected ? 20.w : 16.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      color: isSelected ? colorScheme.primary.withOpacity(0.12) : Colors.transparent,
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            isSelected ? (item['activeIcon'] as IconData) : (item['icon'] as IconData),
                            key: ValueKey(isSelected),
                            color: isSelected ? colorScheme.primary : colorScheme.onSurface.withOpacity(0.45),
                            size: 24.sp,
                          ),
                        ),
                        if (isSelected) ...[
                          SizedBox(width: 8.w),
                          Text(
                            item['label'] as String,
                            style: GoogleFonts.inter(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w700,
                              color: colorScheme.primary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }),
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
    final textDimColor = colorScheme.onSurface.withOpacity(0.52);
    final cardColor = theme.cardColor;

    final settings = Provider.of<SettingsProvider>(context);
    final bool isHindi = settings.isHindi;
    final String userName = settings.privacyMode ? 'R**' : 'Raj';

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0.w, vertical: 20.0.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header Row
                  StaggeredListItem(
                    index: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${_getGreeting()}, $userName 👋',
                                style: GoogleFonts.inter(
                                  fontSize: 26.sp,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.6,
                                  color: textColor,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                'Ready to scan a document?',
                                style: GoogleFonts.inter(
                                  fontSize: 13.sp,
                                  color: textDimColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 12.w),
                        AnimatedScaleButton(
                          onTap: () {
                            Navigator.push(context,
                                MaterialPageRoute(builder: (context) => const ProfileScreen(isTab: false)));
                          },
                          child: Container(
                            padding: EdgeInsets.all(3.w),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [colorScheme.primary, colorScheme.secondary],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: colorScheme.primary.withOpacity(0.3),
                                  blurRadius: 12.r,
                                  offset: Offset(0, 4.h),
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 22.r,
                              backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
                              child: Icon(Icons.person_rounded, color: colorScheme.primary, size: 22.sp),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 28.h),

                  // Hero Scan Card
                  StaggeredListItem(
                    index: 1,
                    child: AnimatedScaleButton(
                      onTap: () => Navigator.push(
                          context, MaterialPageRoute(builder: (_) => const UploadScreen())),
                      child: Container(
                        padding: EdgeInsets.all(28.w),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              colorScheme.primary,
                              colorScheme.secondary,
                              isDark ? const Color(0xFF0EA5E9) : const Color(0xFF06B6D4),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(28.r),
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.primary.withOpacity(0.4),
                              blurRadius: 30.r,
                              offset: Offset(0.w, 12.h),
                              spreadRadius: -4,
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            // Decorative circles
                            Positioned(
                              right: -20,
                              top: -20,
                              child: Container(
                                width: 120.w,
                                height: 120.w,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withOpacity(0.07),
                                ),
                              ),
                            ),
                            Positioned(
                              right: 20,
                              bottom: -30,
                              child: Container(
                                width: 80.w,
                                height: 80.w,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withOpacity(0.05),
                                ),
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(14.w),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(16.r),
                                      ),
                                      child: Icon(Icons.document_scanner_rounded,
                                          size: 28.sp, color: Colors.white),
                                    ),
                                    SizedBox(width: 16.w),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(8.r),
                                          ),
                                          child: Text(
                                            'AI POWERED',
                                            style: GoogleFonts.inter(
                                              fontSize: 10.sp,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white.withOpacity(0.9),
                                              letterSpacing: 1.5,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                SizedBox(height: 20.h),
                                Text(
                                  tr('Upload Documents', isHindi),
                                  style: GoogleFonts.inter(
                                    fontSize: 24.sp,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                SizedBox(height: 6.h),
                                Text(
                                  tr('Tap to start a new analysis', isHindi),
                                  style: GoogleFonts.inter(
                                    fontSize: 14.sp,
                                    color: Colors.white.withOpacity(0.75),
                                  ),
                                ),
                                SizedBox(height: 24.h),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12.r),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.arrow_forward_rounded,
                                          color: colorScheme.primary, size: 16.sp),
                                      SizedBox(width: 6.w),
                                      Text(
                                        'Start Scan',
                                        style: GoogleFonts.inter(
                                          fontSize: 13.sp,
                                          fontWeight: FontWeight.w700,
                                          color: colorScheme.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 24.h),

                  // Stats Row
                  StaggeredListItem(
                    index: 2,
                    child: Row(
                      children: [
                        _buildStatCard(tr('Last Scan', isHindi), tr('Today', isHindi), Icons.schedule_rounded,
                            const Color(0xFF6366F1), cardColor, textColor, textDimColor, isDark),
                        SizedBox(width: 12.w),
                        _buildStatCard(tr('Total', isHindi), '42', Icons.bar_chart_rounded,
                            const Color(0xFF10B981), cardColor, textColor, textDimColor, isDark),
                        SizedBox(width: 12.w),
                        _buildStatCard(tr('Matches', isHindi), '94%', Icons.verified_rounded,
                            const Color(0xFFF59E0B), cardColor, textColor, textDimColor, isDark),
                      ],
                    ),
                  ),
                  SizedBox(height: 28.h),

                  // Recent Activity Header
                  StaggeredListItem(
                    index: 3,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          tr('Recent Activity', isHindi),
                          style: GoogleFonts.inter(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                            color: textColor,
                          ),
                        ),
                        TextButton(
                          onPressed: () {},
                          child: Text(
                            'See all',
                            style: GoogleFonts.inter(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 8.h),

                  StaggeredListItem(
                    index: 4,
                    child: _buildRecentActivityItem('Passport Verification', '17 Mar 2026', true,
                        cardColor, textColor, textDimColor, isDark, colorScheme),
                  ),
                  StaggeredListItem(
                    index: 5,
                    child: _buildRecentActivityItem('Utility Bill Check', '15 Mar 2026', false,
                        cardColor, textColor, textDimColor, isDark, colorScheme),
                  ),
                  StaggeredListItem(
                    index: 6,
                    child: _buildRecentActivityItem('Driver License', '10 Mar 2026', true,
                        cardColor, textColor, textDimColor, isDark, colorScheme),
                  ),
                  SizedBox(height: 100.h), // Space for bottom nav
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getGreeting() {
    return 'Hello';
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color accentColor,
      Color cardColor, Color textColor, Color textDimColor, bool isDark) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 12.w),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: accentColor.withOpacity(0.15),
            width: 1.w,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
              blurRadius: 12.r,
              offset: Offset(0, 4.h),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(icon, size: 16.sp, color: accentColor),
            ),
            SizedBox(height: 10.h),
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 18.sp,
                color: textColor,
                fontWeight: FontWeight.w800,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 2.h),
            Text(
              title,
              style: GoogleFonts.inter(fontSize: 11.sp, color: textDimColor, fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivityItem(String title, String date, bool isMatch, Color cardColor,
      Color textColor, Color textDimColor, bool isDark, ColorScheme colorScheme) {
    final color = isMatch ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    final status = isMatch ? 'Verified' : 'Mismatch';
    final statusIcon = isMatch ? Icons.check_circle_rounded : Icons.cancel_rounded;

    return Padding(
      padding: EdgeInsets.only(bottom: 10.0.h),
      child: AnimatedScaleButton(
        onTap: () {},
        child: Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: color.withOpacity(0.1),
              width: 1.w,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.15 : 0.04),
                blurRadius: 12.r,
                offset: Offset(0, 4.h),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Icon(Icons.description_rounded, color: color, size: 22.sp),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: GoogleFonts.inter(
                            fontSize: 14.sp, fontWeight: FontWeight.w700, color: textColor)),
                    SizedBox(height: 4.h),
                    Text(date,
                        style: GoogleFonts.inter(
                            fontSize: 12.sp, color: textDimColor, fontWeight: FontWeight.w400)),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(color: color.withOpacity(0.25)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, color: color, size: 12.sp),
                    SizedBox(width: 4.w),
                    Text(status,
                        style: GoogleFonts.inter(
                            fontSize: 11.sp, fontWeight: FontWeight.w700, color: color)),
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
