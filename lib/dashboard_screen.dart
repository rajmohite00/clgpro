import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'upload_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';
import 'analytics_screen.dart';
import 'providers/settings_provider.dart';
import 'providers/user_provider.dart';
import 'providers/theme_provider.dart';
import 'widgets/chatbot_widget.dart';
import 'widgets/logo_widget.dart';
import 'utils/animations.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  DASHBOARD — Forensic Intelligence UI
// ─────────────────────────────────────────────────────────────────────────────
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _navCtrl;

  final List<Widget> _pages = [
    const _HomeView(),
    const HistoryScreen(isTab: true),
    const ProfileScreen(isTab: true),
  ];

  @override
  void initState() {
    super.initState();
    _navCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 400),
    )..forward();
  }

  @override
  void dispose() { _navCtrl.dispose(); super.dispose(); }

  void _onTabTapped(int index) => setState(() => _currentIndex = index);

  @override
  Widget build(BuildContext context) {
    final theme   = Theme.of(context);
    final cs      = theme.colorScheme;
    final isDark  = theme.brightness == Brightness.dark;
    final settings = Provider.of<SettingsProvider>(context);
    final isHindi = settings.isHindi;

    final navItems = [
      {'icon': Icons.shield_outlined,   'activeIcon': Icons.shield_rounded,       'label': tr('Intel', isHindi)},
      {'icon': Icons.history_outlined,  'activeIcon': Icons.history_rounded,       'label': tr('Archive', isHindi)},
      {'icon': Icons.person_outline,    'activeIcon': Icons.person_rounded,        'label': tr('Agent', isHindi)},
    ];

    final navBg  = isDark ? AppTheme.inkMid : Colors.white;
    final bdr    = isDark ? AppTheme.borderLight : AppTheme.lightBorder;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      floatingActionButton: const ChatbotFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      extendBody: true,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 260),
        transitionBuilder: (child, anim) => FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
          child: child,
        ),
        child: KeyedSubtree(key: ValueKey(_currentIndex), child: _pages[_currentIndex]),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: navBg,
          border: Border(top: BorderSide(color: bdr, width: 1)),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 16.w),
            child: Row(
              children: List.generate(navItems.length, (i) {
                final item     = navItems[i];
                final selected = _currentIndex == i;
                return Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _onTabTapped(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      margin: EdgeInsets.symmetric(horizontal: 4.w),
                      padding: EdgeInsets.symmetric(vertical: 8.h),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10.r),
                        color: selected
                            ? cs.primary.withOpacity(isDark ? 0.12 : 0.08)
                            : Colors.transparent,
                        border: selected
                            ? Border.all(color: cs.primary.withOpacity(0.25), width: 1)
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 180),
                            child: Icon(
                              selected
                                  ? item['activeIcon'] as IconData
                                  : item['icon'] as IconData,
                              key: ValueKey(selected),
                              size: 20.sp,
                              color: selected
                                  ? cs.primary
                                  : cs.onSurface.withOpacity(0.35),
                            ),
                          ),
                          SizedBox(height: 3.h),
                          AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 180),
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 9.sp,
                              fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                              color: selected
                                  ? cs.primary
                                  : cs.onSurface.withOpacity(0.35),
                              letterSpacing: 0.5,
                            ),
                            child: Text(item['label'] as String),
                          ),
                        ],
                      ),
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

// ─────────────────────────────────────────────────────────────────────────────
//  HOME VIEW
// ─────────────────────────────────────────────────────────────────────────────
class _HomeView extends StatefulWidget {
  const _HomeView();
  @override
  State<_HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<_HomeView> with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _recent = [];
  late AnimationController _bgCtrl;

  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(
      vsync: this, duration: const Duration(seconds: 12),
    )..repeat();
    _loadRecent();
  }

  @override
  void dispose() { _bgCtrl.dispose(); super.dispose(); }

  Future<void> _loadRecent() async {
    final prefs = await SharedPreferences.getInstance();
    final uid   = prefs.getString('user_id') ?? 'guest';
    final saved = prefs.getStringList('history_results_$uid') ?? [];
    if (mounted) {
      setState(() {
        _recent = saved.take(3)
            .map((s) => jsonDecode(s) as Map<String, dynamic>)
            .toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme    = Theme.of(context);
    final cs       = theme.colorScheme;
    final isDark   = theme.brightness == Brightness.dark;
    final textPri  = cs.onSurface;
    final textSec  = cs.onSurface.withOpacity(0.5);
    final settings = Provider.of<SettingsProvider>(context);
    final isHindi  = settings.isHindi;
    final user     = Provider.of<UserProvider>(context);
    final userName = user.name.trim().split(RegExp(r'\s+')).first;

    if (user.shouldShowRatingPrompt) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showRatingDialog(context, isHindi);
      });
    }

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadRecent,
        color: cs.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [

            // ── App Bar ──────────────────────────────────────────────────────
            SliverAppBar(
              pinned: true,
              floating: false,
              backgroundColor: isDark ? AppTheme.ink : AppTheme.lightBg,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              flexibleSpace: Stack(
                fit: StackFit.expand,
                children: [
                  // Subtle grid on dark mode
                  if (isDark) AnimatedBuilder(
                    animation: _bgCtrl,
                    builder: (_, __) => CustomPaint(
                      painter: _DashGridPainter(_bgCtrl.value),
                    ),
                  ),
                ],
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(1),
                child: Divider(
                  height: 1,
                  color: isDark ? AppTheme.borderLight : AppTheme.lightBorder,
                ),
              ),
              title: Row(
                children: [
                  Container(
                    width: 28.w, height: 28.w,
                    decoration: BoxDecoration(
                      color: AppTheme.inkMid,
                      borderRadius: BorderRadius.circular(6.r),
                      border: Border.all(
                        color: cs.primary.withOpacity(0.5), width: 1,
                      ),
                    ),
                    child: Center(
                      child: DocVerifyLogo(
                        size: 14.sp,
                        color: cs.primary,
                        glowOpacity: 0.0,
                      ),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Text(
                    'DOCVERIFY',
                    style: GoogleFonts.syne(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w800,
                      color: textPri,
                      letterSpacing: 2.0,
                    ),
                  ),
                ],
              ),
              actions: [
                GestureDetector(
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const ProfileScreen(isTab: false))),
                  child: Padding(
                    padding: EdgeInsets.only(right: 16.w),
                    child: Container(
                      width: 34.w, height: 34.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: cs.primary.withOpacity(0.4), width: 1.5),
                        color: cs.primary.withOpacity(0.08),
                      ),
                      child: ClipOval(
                        child: user.profilePicPath != null
                            ? Image.file(File(user.profilePicPath!), fit: BoxFit.cover)
                            : Icon(Icons.person_rounded, color: cs.primary, size: 17.sp),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // ── Greeting + threat level ───────────────────────────────────
            SliverToBoxAdapter(
              child: SlideIn(
                begin: const Offset(-0.05, 0),
                duration: const Duration(milliseconds: 500),
                child: Container(
                  margin: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 0),
                  padding: EdgeInsets.all(20.w),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.inkMid : Colors.white,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: isDark ? AppTheme.borderLight : AppTheme.lightBorder,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tr('Welcome back,', isHindi),
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 10.sp,
                                color: cs.primary.withOpacity(0.7),
                                letterSpacing: 1,
                              ),
                            ),
                            SizedBox(height: 3.h),
                            Text(
                              userName,
                              style: GoogleFonts.syne(
                                fontSize: 22.sp,
                                fontWeight: FontWeight.w800,
                                color: textPri,
                                letterSpacing: -0.3,
                              ),
                            ),
                            SizedBox(height: 6.h),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                              decoration: BoxDecoration(
                                color: cs.primary.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(4.r),
                                border: Border.all(color: cs.primary.withOpacity(0.2)),
                              ),
                              child: Text(
                                tr('AGENT ACTIVE', isHindi),
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 9.sp,
                                  color: cs.primary,
                                  letterSpacing: 1.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Animated threat gauge
                      _ThreatGauge(
                        fraudRate: _recent.isEmpty ? 0 :
                          (_recent.where((r) => (r['status'] as String?) != 'REAL').length /
                           _recent.length * 100).round(),
                        isDark: isDark, accent: cs.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Scan CTA ──────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 0),
                child: SlideIn(
                  delay: const Duration(milliseconds: 80),
                  child: _ScanCard(isDark: isDark, accent: cs.primary, isHindi: isHindi),
                ),
              ),
            ),

            // ── Stats Row ─────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 0),
                child: SlideIn(
                  delay: const Duration(milliseconds: 140),
                  child: Row(children: [
                    _StatTile(
                      label: tr('SCANS', isHindi),
                      value: '${user.totalScans}',
                      icon: Icons.document_scanner_outlined,
                      isDark: isDark, accent: cs.primary,
                      textPri: textPri, textSec: textSec,
                    ),
                    SizedBox(width: 10.w),
                    _StatTile(
                      label: tr('STREAK', isHindi),
                      value: '${user.streakDays}D',
                      icon: Icons.local_fire_department_outlined,
                      isDark: isDark, accent: cs.primary,
                      textPri: textPri, textSec: textSec,
                    ),
                    SizedBox(width: 10.w),
                    _StatTile(
                      label: tr('ANALYTICS', isHindi),
                      value: '→',
                      icon: Icons.analytics_outlined,
                      isDark: isDark, accent: cs.primary,
                      textPri: textPri, textSec: textSec,
                      onTap: () => Navigator.push(context,
                          FadeSlideRoute(page: const AnalyticsScreen())),
                    ),
                  ]),
                ),
              ),
            ),

            // ── Recent header ─────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20.w, 28.h, 20.w, 12.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 3.w, height: 14.h,
                          decoration: BoxDecoration(
                            color: cs.primary,
                            borderRadius: BorderRadius.circular(2.r),
                            boxShadow: [
                              BoxShadow(
                                color: cs.primary.withOpacity(0.5), blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Text(
                          tr('RECENT INTEL', isHindi),
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w700,
                            color: textSec,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () {
                        final dash = context
                            .findAncestorStateOfType<_DashboardScreenState>();
                        dash?._onTabTapped(1);
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: cs.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(6.r),
                          border: Border.all(color: cs.primary.withOpacity(0.2)),
                        ),
                        child: Text(
                          tr('VIEW ALL', isHindi),
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 9.sp,
                            fontWeight: FontWeight.w600,
                            color: cs.primary,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Recent items ──────────────────────────────────────────────
            _recent.isEmpty
                ? SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                      child: Container(
                        padding: EdgeInsets.all(24.w),
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.inkMid : Colors.white,
                          borderRadius: BorderRadius.circular(10.r),
                          border: Border.all(
                            color: isDark ? AppTheme.borderLight : AppTheme.lightBorder,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.inbox_outlined,
                              size: 32.sp,
                              color: cs.primary.withOpacity(0.3),
                            ),
                            SizedBox(height: 10.h),
                            Text(
                              tr('NO RECORDS FOUND', isHindi),
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 10.sp,
                                color: textSec,
                                letterSpacing: 1,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              tr('Upload a document to begin analysis.', isHindi),
                              style: GoogleFonts.syne(fontSize: 12.sp, color: textSec),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) {
                        final item   = _recent[i];
                        final status = item['status'] as String? ?? '';
                        final isReal = status == 'REAL' || status == 'Match';
                        final title  = (item['summary'] as String? ?? '').isNotEmpty
                            ? item['summary'] as String
                            : (item['documentType'] as String? ?? 'Document');
                        final date   = item['date'] as String? ?? '';
                        final score  = item['fraudScore'] as int? ?? 0;

                        return AnimatedListItem(
                          index: i,
                          delay: const Duration(milliseconds: 60),
                          child: _ActivityRow(
                            title: title, date: date, score: score,
                            isReal: isReal, isDark: isDark,
                            accent: cs.primary, textPri: textPri, textSec: textSec,
                            isLast: i == _recent.length - 1,
                          ),
                        );
                      },
                      childCount: _recent.length,
                    ),
                  ),

            SliverToBoxAdapter(child: SizedBox(height: 90.h)),
          ],
        ),
      ),
    );
  }

  void _showRatingDialog(BuildContext context, bool isHindi) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.inkMid,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
          side: const BorderSide(color: AppTheme.borderLight),
        ),
        title: Text(tr('Enjoying DocVerify?', isHindi),
            style: GoogleFonts.syne(fontWeight: FontWeight.w700, fontSize: 16.sp,
              color: AppTheme.textPrimary)),
        content: Text(tr('Help us improve by leaving a rating.', isHindi),
            style: GoogleFonts.syne(fontSize: 13.sp, color: AppTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () {
              Provider.of<UserProvider>(context, listen: false).markRatingPrompted();
              Navigator.pop(ctx);
            },
            child: Text(tr('Later', isHindi),
              style: GoogleFonts.syne(fontSize: 13.sp, color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Provider.of<UserProvider>(context, listen: false).markRated();
              Navigator.pop(ctx);
            },
            child: Text(tr('Rate Us', isHindi),
              style: GoogleFonts.syne(fontSize: 13.sp,
                color: AppTheme.jade, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  THREAT GAUGE — animated circular indicator
// ─────────────────────────────────────────────────────────────────────────────
class _ThreatGauge extends StatelessWidget {
  final int fraudRate;
  final bool isDark;
  final Color accent;
  const _ThreatGauge({required this.fraudRate, required this.isDark, required this.accent});

  @override
  Widget build(BuildContext context) {
    final Color color = fraudRate == 0
        ? AppTheme.jade
        : fraudRate <= 50
            ? AppTheme.amber
            : AppTheme.crimson;
    final String label = fraudRate == 0
        ? 'CLEAR'
        : fraudRate <= 50 ? 'MEDIUM' : 'HIGH';

    return Column(
      children: [
        SizedBox(
          width: 56.w, height: 56.w,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CircularProgressIndicator(
                value: fraudRate / 100,
                backgroundColor: color.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                strokeWidth: 3,
                strokeCap: StrokeCap.round,
              ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$fraudRate%',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 5.h),
        Text(
          label,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 8.sp,
            color: color,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  SCAN CTA CARD
// ─────────────────────────────────────────────────────────────────────────────
class _ScanCard extends StatefulWidget {
  final bool isDark;
  final Color accent;
  final bool isHindi;
  const _ScanCard({required this.isDark, required this.accent, required this.isHindi});
  @override
  State<_ScanCard> createState() => _ScanCardState();
}

class _ScanCardState extends State<_ScanCard> with SingleTickerProviderStateMixin {
  late AnimationController _shimmerCtrl;

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() { _shimmerCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return TapScale(
      onTap: () => Navigator.push(
          context, FadeSlideRoute(page: const UploadScreen())),
      child: Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: widget.isDark ? AppTheme.inkMid : Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: widget.accent.withOpacity(0.3), width: 1),
          boxShadow: [
            BoxShadow(
              color: widget.accent.withOpacity(0.08),
              blurRadius: 20,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon block
            Container(
              width: 52.w, height: 52.w,
              decoration: BoxDecoration(
                color: widget.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: widget.accent.withOpacity(0.3)),
              ),
              child: Icon(
                Icons.document_scanner_rounded,
                color: widget.accent, size: 24.sp,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr('INITIATE SCAN', widget.isHindi),
                    style: GoogleFonts.syne(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w800,
                      color: widget.isDark ? AppTheme.textPrimary : AppTheme.lightText,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    tr('Upload document for AI analysis', widget.isHindi),
                    style: GoogleFonts.syne(
                      fontSize: 11.sp,
                      color: widget.isDark ? AppTheme.textSecondary : AppTheme.lightTextSub,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.all(6.w),
              decoration: BoxDecoration(
                color: widget.accent.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: widget.accent.withOpacity(0.3)),
              ),
              child: Icon(
                Icons.arrow_forward_rounded,
                size: 14.sp, color: widget.accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  STAT TILE
// ─────────────────────────────────────────────────────────────────────────────
class _StatTile extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final bool isDark;
  final Color accent, textPri, textSec;
  final VoidCallback? onTap;

  const _StatTile({
    required this.label, required this.value, required this.icon,
    required this.isDark, required this.accent,
    required this.textPri, required this.textSec, this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: TapScale(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 12.w),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.inkMid : Colors.white,
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(
              color: isDark ? AppTheme.borderLight : AppTheme.lightBorder,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 16.sp, color: accent.withOpacity(0.6)),
              SizedBox(height: 8.h),
              Text(
                value,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: textPri,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                label,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 8.5.sp,
                  color: textSec,
                  letterSpacing: 0.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  ACTIVITY ROW — terminal log style
// ─────────────────────────────────────────────────────────────────────────────
class _ActivityRow extends StatelessWidget {
  final String title, date;
  final int score;
  final bool isReal, isLast, isDark;
  final Color accent, textPri, textSec;

  const _ActivityRow({
    required this.title, required this.date, required this.score,
    required this.isReal, required this.isLast, required this.isDark,
    required this.accent, required this.textPri, required this.textSec,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = isReal ? AppTheme.jade : AppTheme.crimson;
    final bdr = isDark ? AppTheme.borderLight : AppTheme.lightBorder;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.inkMid : Colors.white,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: bdr),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        child: Row(
          children: [
            // Status indicator
            Container(
              width: 36.w, height: 36.w,
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: statusColor.withOpacity(0.2)),
              ),
              child: Icon(
                isReal ? Icons.verified_rounded : Icons.gpp_bad_rounded,
                size: 16.sp, color: statusColor,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                    style: GoogleFonts.syne(
                      fontSize: 12.5.sp,
                      fontWeight: FontWeight.w600,
                      color: textPri,
                    ),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 2.h),
                  Text(date,
                    style: GoogleFonts.jetBrainsMono(fontSize: 9.5.sp, color: textSec),
                  ),
                ],
              ),
            ),
            SizedBox(width: 10.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(4.r),
                    border: Border.all(color: statusColor.withOpacity(0.25)),
                  ),
                  child: Text(
                    isReal ? 'GENUINE' : 'FRAUD',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 8.5.sp,
                      fontWeight: FontWeight.w800,
                      color: statusColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  '$score/100',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 9.sp,
                    color: textSec,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Dashboard background grid (very subtle) ───────────────────────────────────
class _DashGridPainter extends CustomPainter {
  final double t;
  _DashGridPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.jade.withOpacity(0.025)
      ..strokeWidth = 0.4;
    const spacing = 32.0;
    for (double x = 0; x <= size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DashGridPainter old) => false;
}
