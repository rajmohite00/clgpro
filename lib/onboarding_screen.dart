import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'login_screen.dart';
import 'providers/settings_provider.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _bgController;

  @override
  void initState() {
    super.initState();
    _bgController =
        AnimationController(vsync: this, duration: const Duration(seconds: 10))
          ..repeat();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _bgController.dispose();
    super.dispose();
  }

  void _onNext() {
    if (_currentPage == 1) {
      _finishOnboarding();
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutQuart,
      );
    }
  }

  Future<void> _finishOnboarding() async {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final isHindi = settings.isHindi;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF070714),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Animated background
          AnimatedBuilder(
            animation: _bgController,
            builder: (context, _) {
              return CustomPaint(
                painter: _OnboardingBgPainter(_bgController.value, _currentPage),
              );
            },
          ),

          // Gradient overlay for depth
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x80070714),
                  Colors.transparent,
                  Colors.transparent,
                  Color(0xCC070714),
                ],
                stops: [0.0, 0.2, 0.7, 1.0],
              ),
            ),
          ),

          // Safe content area
          SafeArea(
            child: Column(
              children: [
                // Skip button top-right
                Align(
                  alignment: Alignment.centerRight,
                  child: _currentPage == 0
                    ? Padding(
                        padding: EdgeInsets.only(right: 20.w, top: 8.h, bottom: 4.h),
                        child: GestureDetector(
                          onTap: _finishOnboarding,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 16.w, vertical: 8.h),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(20.r),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.12)),
                            ),
                            child: Text(
                              'Skip',
                              style: GoogleFonts.inter(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withOpacity(0.55),
                              ),
                            ),
                          ),
                        ),
                      )
                    : SizedBox(height: 44.h),
                ),

                // Pages
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const BouncingScrollPhysics(),
                    onPageChanged: (int page) {
                      setState(() => _currentPage = page);
                    },
                    children: [
                      _buildPage(
                        context: context,
                        size: size,
                        title: tr('Verify Documents\nInstantly', isHindi),
                        subtitle: tr(
                          'Upload Aadhaar, PAN, or any document and let AI verify authenticity in seconds.',
                          isHindi,
                        ),
                        icon: Icons.verified_user_rounded,
                        accentColor: const Color(0xFF6366F1),
                        secondaryColor: const Color(0xFF818CF8),
                      ),
                      _buildPage(
                        context: context,
                        size: size,
                        title: tr('Detect Mismatches\n& Fraud', isHindi),
                        subtitle: tr(
                          'Compare multiple documents and identify mismatches with smart AI analysis.',
                          isHindi,
                        ),
                        icon: Icons.document_scanner_rounded,
                        accentColor: const Color(0xFF8B5CF6),
                        secondaryColor: const Color(0xFFA78BFA),
                      ),
                    ],
                  ),
                ),

                // Bottom controls
                _buildBottomSection(isHindi, size),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage({
    required BuildContext context,
    required Size size,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required Color secondaryColor,
  }) {
    // Use LayoutBuilder to respond to available height
    return LayoutBuilder(
      builder: (context, constraints) {
        final availH = constraints.maxHeight;
        // Scale illustration to available height
        final illustSize = (availH * 0.38).clamp(160.0, 260.0);
        final topGap = (availH * 0.06).clamp(12.0, 48.0);
        final midGap = (availH * 0.05).clamp(16.0, 40.0);
        final titleFontSize = (size.width * 0.072).clamp(20.0, 34.0);
        final subtitleFontSize = (size.width * 0.038).clamp(12.0, 16.0);

        return SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 28.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: topGap),
                // Illustration
                SizedBox(
                  width: illustSize,
                  height: illustSize,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer glow
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              accentColor.withOpacity(0.15),
                              accentColor.withOpacity(0.0),
                            ],
                          ),
                        ),
                      ),
                      // Middle ring
                      Container(
                        width: illustSize * 0.82,
                        height: illustSize * 0.82,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: accentColor.withOpacity(0.2),
                            width: 1,
                          ),
                          gradient: RadialGradient(
                            colors: [
                              accentColor.withOpacity(0.08),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                      // Inner icon circle
                      Container(
                        width: illustSize * 0.6,
                        height: illustSize * 0.6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              accentColor.withOpacity(0.3),
                              secondaryColor.withOpacity(0.4),
                            ],
                          ),
                          border: Border.all(
                            color: accentColor.withOpacity(0.5),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: accentColor.withOpacity(0.35),
                              blurRadius: 40,
                              spreadRadius: 4,
                            ),
                            BoxShadow(
                              color: secondaryColor.withOpacity(0.2),
                              blurRadius: 70,
                              spreadRadius: 15,
                            ),
                          ],
                        ),
                        child: Icon(
                          icon,
                          size: illustSize * 0.28,
                          color: Colors.white,
                        ),
                      ),
                      // Particles
                      ..._buildParticles(illustSize / 2, accentColor),
                    ],
                  ),
                ),
                SizedBox(height: midGap),
                // Title
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [
                      Colors.white,
                      accentColor.withOpacity(0.8),
                      Colors.white
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(bounds),
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1.15,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                SizedBox(height: (availH * 0.025).clamp(10.0, 20.0)),
                // Subtitle
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: subtitleFontSize,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withOpacity(0.6),
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildParticles(double center, Color accentColor) {
    final positions = [
      {'angle': 30.0, 'dist': 0.44, 'size': 7.0},
      {'angle': 120.0, 'dist': 0.42, 'size': 5.0},
      {'angle': 210.0, 'dist': 0.45, 'size': 9.0},
      {'angle': 300.0, 'dist': 0.43, 'size': 6.0},
    ];

    return positions.map((p) {
      final angle = (p['angle']! as double) * pi / 180;
      final dist = (p['dist']! as double) * center;
      final size = (p['size']! as double);
      return Positioned(
        left: center + dist * cos(angle) - size / 2,
        top: center + dist * sin(angle) - size / 2,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: accentColor.withOpacity(0.7),
            boxShadow: [
              BoxShadow(color: accentColor.withOpacity(0.5), blurRadius: 4),
            ],
          ),
        ),
      );
    }).toList();
  }

  Widget _buildBottomSection(bool isHindi, Size size) {
    final bottomPad = (size.height * 0.05).clamp(20.0, 52.0);
    final buttonHeight = (size.height * 0.072).clamp(50.0, 64.0);

    return Padding(
      padding: EdgeInsets.only(
          bottom: bottomPad, left: 28.w, right: 28.w, top: 12.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Page dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(2, (index) => _buildDot(index)),
          ),
          SizedBox(height: (size.height * 0.028).clamp(16.0, 36.0)),

          // CTA Button
          GestureDetector(
            onTap: _onNext,
            child: Container(
              width: double.infinity,
              height: buttonHeight,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20.r),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _currentPage == 0
                        ? const Color(0xFF6366F1)
                        : const Color(0xFF8B5CF6),
                    _currentPage == 0
                        ? const Color(0xFF818CF8)
                        : const Color(0xFFA78BFA),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: (_currentPage == 0
                            ? const Color(0xFF6366F1)
                            : const Color(0xFF8B5CF6))
                        .withOpacity(0.45),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _currentPage == 0
                          ? tr('Next', isHindi)
                          : tr('Get Started', isHindi),
                      style: GoogleFonts.inter(
                        fontSize: (size.width * 0.042).clamp(14.0, 18.0),
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Icon(
                      _currentPage == 1
                          ? Icons.rocket_launch_rounded
                          : Icons.arrow_forward_rounded,
                      color: Colors.white.withOpacity(0.85),
                      size: (size.width * 0.042).clamp(14.0, 20.0),
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

  Widget _buildDot(int index) {
    final isActive = _currentPage == index;
    final activeColor =
        index == 0 ? const Color(0xFF6366F1) : const Color(0xFF8B5CF6);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.symmetric(horizontal: 5),
      height: 8,
      width: isActive ? 28 : 8,
      decoration: BoxDecoration(
        color: isActive ? activeColor : Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
        boxShadow: isActive
            ? [
                BoxShadow(
                    color: activeColor.withOpacity(0.5),
                    blurRadius: 8,
                    spreadRadius: 1)
              ]
            : null,
      ),
    );
  }
}

class _OnboardingBgPainter extends CustomPainter {
  final double t;
  final int page;
  _OnboardingBgPainter(this.t, this.page);

  @override
  void paint(Canvas canvas, Size size) {
    final color1 =
        page == 0 ? const Color(0xFF6366F1) : const Color(0xFF8B5CF6);
    final color2 =
        page == 0 ? const Color(0xFF818CF8) : const Color(0xFFA78BFA);

    final orbs = [
      {'x': 0.8, 'y': 0.15, 'r': 200.0, 'speed': 0.25, 'color': color1},
      {'x': 0.1, 'y': 0.3, 'r': 160.0, 'speed': 0.35, 'color': color2},
      {'x': 0.6, 'y': 0.8, 'r': 180.0, 'speed': 0.2, 'color': color1},
      {'x': 0.2, 'y': 0.85, 'r': 120.0, 'speed': 0.4, 'color': color2},
    ];

    for (var orb in orbs) {
      final speed = orb['speed'] as double;
      final dx =
          (orb['x'] as double) * size.width + sin(t * 2 * pi * speed) * 40;
      final dy =
          (orb['y'] as double) * size.height + cos(t * 2 * pi * speed) * 30;
      final radius = orb['r'] as double;
      final color = orb['color'] as Color;

      final paint = Paint()
        ..shader = RadialGradient(
          colors: [color.withOpacity(0.12), color.withOpacity(0.0)],
        ).createShader(
            Rect.fromCircle(center: Offset(dx, dy), radius: radius));

      canvas.drawCircle(Offset(dx, dy), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _OnboardingBgPainter old) => true;
}
