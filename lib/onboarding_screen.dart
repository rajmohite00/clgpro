import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'login_screen.dart';
import 'providers/settings_provider.dart';
import 'providers/theme_provider.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  late AnimationController _bgCtrl;
  late AnimationController _scanCtrl;
  late AnimationController _entryCtrl;
  late List<AnimationController> _nodeCtrl;

  final List<_OnboardingData> _pages = [
    _OnboardingData(
      headline: 'VERIFY\nDOCUMENTS',
      tagline: 'FRAUD DETECTION SYSTEM',
      body: 'Upload Aadhaar, PAN, or any official document.\nOur AI engine cross-checks authenticity in seconds.',
      icon: Icons.shield_rounded,
      accentA: Color(0xFF00FFA3),   // jade
      accentB: Color(0xFF00CC82),
      glowColor: Color(0x2200FFA3),
    ),
    _OnboardingData(
      headline: 'DETECT\nMISMATCH',
      tagline: 'CROSS-DOCUMENT ANALYSIS',
      body: 'Compare multiple documents simultaneously.\nIdentify data discrepancies with precision AI analysis.',
      icon: Icons.compare_arrows_rounded,
      accentA: Color(0xFFFF6B2B),   // deep orange — fresh, not purple
      accentB: Color(0xFFFF8C5A),
      glowColor: Color(0x22FF6B2B),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(
      vsync: this, duration: const Duration(seconds: 8),
    )..repeat();
    _scanCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 2800),
    )..repeat();
    _entryCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 900),
    )..forward();

    // Floating node animations
    _nodeCtrl = List.generate(6, (i) => AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 2000 + i * 300),
    )..repeat(reverse: true));
  }

  @override
  void dispose() {
    _pageController.dispose();
    _bgCtrl.dispose();
    _scanCtrl.dispose();
    _entryCtrl.dispose();
    for (final c in _nodeCtrl) c.dispose();
    super.dispose();
  }

  void _onNext() {
    if (_currentPage == _pages.length - 1) {
      _finishOnboarding();
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  Future<void> _finishOnboarding() async {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const LoginScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final isHindi = settings.isHindi;
    final page = _pages[_currentPage];
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppTheme.ink,
      body: Stack(
        fit: StackFit.expand,
        children: [

          // ── Background grid ──────────────────────────────────────────────
          CustomPaint(
            painter: _OnboardGridPainter(),
          ),

          // ── Accent orbs ───────────────────────────────────────────────────
          AnimatedBuilder(
            animation: _bgCtrl,
            builder: (_, __) => CustomPaint(
              painter: _OnboardOrbPainter(_bgCtrl.value, page.accentA, page.accentB),
            ),
          ),

          // ── Moving scan line ──────────────────────────────────────────────
          AnimatedBuilder(
            animation: _scanCtrl,
            builder: (_, __) {
              final progress = Curves.easeInOut.transform(_scanCtrl.value);
              return Positioned(
                top: size.height * 0.1 + size.height * 0.6 * progress,
                left: 0, right: 0,
                child: Container(
                  height: 1.5,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      Colors.transparent,
                      page.accentA.withOpacity(0.4),
                      page.accentA.withOpacity(0.6),
                      page.accentA.withOpacity(0.4),
                      Colors.transparent,
                    ]),
                  ),
                ),
              );
            },
          ),

          // ── Floating data nodes ───────────────────────────────────────────
          ..._buildFloatingNodes(page.accentA),

          // ── Page content ─────────────────────────────────────────────────
          SafeArea(
            child: Column(
              children: [

                // Skip
                Align(
                  alignment: Alignment.centerRight,
                  child: _currentPage == 0
                      ? Padding(
                          padding: EdgeInsets.only(right: 20.w, top: 10.h),
                          child: GestureDetector(
                            onTap: _finishOnboarding,
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
                              decoration: BoxDecoration(
                                color: AppTheme.inkMid,
                                borderRadius: BorderRadius.circular(20.r),
                                border: Border.all(color: AppTheme.borderLight),
                              ),
                              child: Text(
                                'SKIP',
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 9.sp,
                                  color: AppTheme.textSecondary,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ),
                          ),
                        )
                      : SizedBox(height: 46.h),
                ),

                // Page view
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    physics: const BouncingScrollPhysics(),
                    itemCount: _pages.length,
                    onPageChanged: (p) {
                      setState(() => _currentPage = p);
                      _entryCtrl.reset();
                      _entryCtrl.forward();
                    },
                    itemBuilder: (_, i) => _buildPage(_pages[i], isHindi, size),
                  ),
                ),

                // Bottom section
                _buildBottomSection(page, isHindi, size),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildFloatingNodes(Color accentA) {
    final positions = [
      Offset(0.1, 0.15), Offset(0.85, 0.12), Offset(0.05, 0.5),
      Offset(0.92, 0.4), Offset(0.15, 0.8), Offset(0.88, 0.75),
    ];
    return positions.asMap().entries.map((e) {
      return AnimatedBuilder(
        animation: _nodeCtrl[e.key],
        builder: (_, __) {
          final bob = _nodeCtrl[e.key].value * 8 - 4;
          return Positioned(
            left: MediaQuery.of(context).size.width * e.value.dx,
            top: MediaQuery.of(context).size.height * e.value.dy + bob,
            child: Container(
              width: 5, height: 5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accentA.withOpacity(0.3),
                boxShadow: [
                  BoxShadow(
                    color: accentA.withOpacity(0.5),
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
          );
        },
      );
    }).toList();
  }

  Widget _buildPage(_OnboardingData page, bool isHindi, Size size) {
    final illustSize = (size.height * 0.3).clamp(160.0, 240.0);

    return AnimatedBuilder(
      animation: _entryCtrl,
      builder: (_, child) {
        final fade = CurvedAnimation(parent: _entryCtrl, curve: const Interval(0.0, 0.7)).value;
        final slide = (1 - CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic).value) * 40;
        return Opacity(
          opacity: fade,
          child: Transform.translate(offset: Offset(0, slide), child: child),
        );
      },
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 28.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            // Illustration
            SizedBox(
              width: illustSize, height: illustSize,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer glow ring
                  Container(
                    width: illustSize,
                    height: illustSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [page.accentA.withOpacity(0.12), Colors.transparent],
                      ),
                    ),
                  ),
                  // Middle ring
                  Container(
                    width: illustSize * 0.78,
                    height: illustSize * 0.78,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: page.accentA.withOpacity(0.15),
                        width: 1,
                      ),
                    ),
                  ),
                  // Corner brackets
                  ..._buildCornerBrackets(illustSize * 0.65, page.accentA),
                  // Core icon circle
                  Container(
                    width: illustSize * 0.52,
                    height: illustSize * 0.52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.inkMid,
                      border: Border.all(
                        color: page.accentA.withOpacity(0.4),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: page.accentA.withOpacity(0.2),
                          blurRadius: 40,
                          spreadRadius: 8,
                        ),
                      ],
                    ),
                    child: Icon(
                      page.icon,
                      size: illustSize * 0.22,
                      color: page.accentA,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 36.h),

            // Tagline
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
              decoration: BoxDecoration(
                color: page.accentA.withOpacity(0.08),
                borderRadius: BorderRadius.circular(4.r),
                border: Border.all(color: page.accentA.withOpacity(0.2)),
              ),
              child: Text(
                tr(page.tagline, isHindi),
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 9.sp,
                  color: page.accentA,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            SizedBox(height: 16.h),

            // Headline
            Text(
              tr(page.headline, isHindi),
              textAlign: TextAlign.center,
              style: GoogleFonts.syne(
                fontSize: (size.width * 0.09).clamp(26.0, 40.0),
                fontWeight: FontWeight.w900,
                color: AppTheme.textPrimary,
                height: 1.05,
                letterSpacing: -0.5,
              ),
            ),

            SizedBox(height: 16.h),

            // Body text
            Text(
              tr(page.body, isHindi),
              textAlign: TextAlign.center,
              style: GoogleFonts.syne(
                fontSize: 13.sp,
                color: AppTheme.textSecondary,
                height: 1.7,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildCornerBrackets(double size, Color color) {
    const cornerSize = 12.0;
    const strokeW = 1.5;
    final half = size / 2;
    Widget bracket(double l, double t, double scaleX, double scaleY) => Positioned(
      left: half + l - cornerSize / 2,
      top: half + t - cornerSize / 2,
      child: Transform.scale(
        scaleX: scaleX, scaleY: scaleY,
        child: Container(
          width: cornerSize, height: cornerSize,
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: color.withOpacity(0.5), width: strokeW),
              left: BorderSide(color: color.withOpacity(0.5), width: strokeW),
            ),
          ),
        ),
      ),
    );
    return [
      bracket(-half,  -half,  1,  1),
      bracket( half,  -half, -1,  1),
      bracket(-half,   half,  1, -1),
      bracket( half,   half, -1, -1),
    ];
  }

  Widget _buildBottomSection(_OnboardingData page, bool isHindi, Size size) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24.w, 8.h, 24.w, 40.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Page dots — horizontal bar style
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_pages.length, (i) {
              final isActive = _currentPage == i;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: isActive ? 24 : 6,
                height: 4,
                decoration: BoxDecoration(
                  color: isActive
                      ? page.accentA
                      : AppTheme.textMuted.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: isActive
                      ? [BoxShadow(color: page.accentA.withOpacity(0.5), blurRadius: 6)]
                      : null,
                ),
              );
            }),
          ),
          SizedBox(height: 24.h),

          // CTA button
          GestureDetector(
            onTap: _onNext,
            child: Container(
              width: double.infinity,
              height: 52.h,
              decoration: BoxDecoration(
                color: page.accentA,
                borderRadius: BorderRadius.circular(10.r),
                boxShadow: [
                  BoxShadow(
                    color: page.accentA.withOpacity(0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _currentPage == _pages.length - 1
                          ? tr('BEGIN ANALYSIS', isHindi)
                          : tr('CONTINUE', isHindi),
                      style: GoogleFonts.syne(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.ink,
                        letterSpacing: 1.5,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Icon(
                      _currentPage == _pages.length - 1
                          ? Icons.rocket_launch_rounded
                          : Icons.arrow_forward_rounded,
                      color: AppTheme.ink,
                      size: 16.sp,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingData {
  final String headline, tagline, body;
  final IconData icon;
  final Color accentA, accentB, glowColor;
  const _OnboardingData({
    required this.headline, required this.tagline, required this.body,
    required this.icon, required this.accentA, required this.accentB,
    required this.glowColor,
  });
}

// ── Background grid painter ───────────────────────────────────────────────────
class _OnboardGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.jade.withOpacity(0.028)
      ..strokeWidth = 0.5;
    const s = 38.0;
    for (double x = 0; x <= size.width; x += s) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += s) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ── Orb painter ───────────────────────────────────────────────────────────────
class _OnboardOrbPainter extends CustomPainter {
  final double t;
  final Color accentA, accentB;
  _OnboardOrbPainter(this.t, this.accentA, this.accentB);

  @override
  void paint(Canvas canvas, Size size) {
    void orb(double xFrac, double yFrac, double r, Color c, double spd) {
      final x = xFrac * size.width  + sin(t * 2 * pi * spd) * 50;
      final y = yFrac * size.height + cos(t * 2 * pi * spd) * 40;
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [c.withOpacity(0.12), Colors.transparent],
        ).createShader(Rect.fromCircle(center: Offset(x, y), radius: r));
      canvas.drawCircle(Offset(x, y), r, paint);
    }

    orb(0.1, 0.2,  200, accentA, 0.2);
    orb(0.9, 0.15, 160, accentB, 0.3);
    orb(0.8, 0.7,  180, accentA, 0.18);
    orb(0.05, 0.8, 140, accentB, 0.25);
  }

  @override
  bool shouldRepaint(covariant _OnboardOrbPainter old) =>
      old.t != t || old.accentA != accentA;
}
