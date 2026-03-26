import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';
import 'dashboard_screen.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _orbController;
  late AnimationController _shimmerController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _textFadeAnimation;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();

    _mainController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000));
    _orbController =
        AnimationController(vsync: this, duration: const Duration(seconds: 6))
          ..repeat();
    _shimmerController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat();

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _mainController,
          curve: const Interval(0.0, 0.5, curve: Curves.easeOut)),
    );
    _scaleAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
          parent: _mainController,
          curve: const Interval(0.0, 0.6, curve: Curves.elasticOut)),
    );
    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _mainController,
          curve: const Interval(0.4, 1.0, curve: Curves.easeOut)),
    );
    _textFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _mainController,
          curve: const Interval(0.5, 0.9, curve: Curves.easeOut)),
    );
    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _mainController,
          curve: const Interval(0.6, 1.0, curve: Curves.easeInOut)),
    );

    _mainController.forward();
    _checkAuthentication();
  }

  Future<void> _checkAuthentication() async {
    await Future.delayed(const Duration(milliseconds: 3000));
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (!mounted) return;

    if (token != null && token.isNotEmpty) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const DashboardScreen(),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 600),
        ),
      );
    } else {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const OnboardingScreen(),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 600),
        ),
      );
    }
  }

  @override
  void dispose() {
    _mainController.dispose();
    _orbController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final logoSize = (size.width * 0.32).clamp(90.0, 160.0);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.3),
            radius: 1.4,
            colors: [
              Color(0xFF1E1152),
              Color(0xFF0A0820),
              Color(0xFF050410),
            ],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Animated Orbs
            AnimatedBuilder(
              animation: _orbController,
              builder: (context, _) {
                return CustomPaint(
                  painter: _SplashOrbPainter(_orbController.value),
                );
              },
            ),

            // Main content — fully flexible, no Spacer overflow
            FadeTransition(
              opacity: _fadeAnimation,
              child: SafeArea(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(), // top padding handled by spaceBetween

                      // Center: Logo + Text
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedBuilder(
                            animation: _mainController,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _scaleAnimation.value,
                                child: SizedBox(
                                  width: logoSize,
                                  height: logoSize,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      // Outer soft glow ring
                                      Container(
                                        width: logoSize,
                                        height: logoSize,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: RadialGradient(
                                            colors: [
                                              const Color(0xFF6366F1).withOpacity(
                                                  0.25 * _glowAnimation.value),
                                              const Color(0xFF8B5CF6).withOpacity(
                                                  0.1 * _glowAnimation.value),
                                              Colors.transparent,
                                            ],
                                          ),
                                        ),
                                      ),
                                      // Middle border ring
                                      Container(
                                        width: logoSize * 0.78,
                                        height: logoSize * 0.78,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: const Color(0xFF6366F1)
                                                .withOpacity(0.25 * _glowAnimation.value),
                                            width: 1.5,
                                          ),
                                        ),
                                      ),
                                      // Core icon circle
                                      Container(
                                        width: logoSize * 0.58,
                                        height: logoSize * 0.58,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: const LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              Color(0xFF4F46E5),
                                              Color(0xFF7C3AED),
                                            ],
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFF6366F1)
                                                  .withOpacity(0.55 * _glowAnimation.value),
                                              blurRadius: 32,
                                              spreadRadius: 4,
                                            ),
                                            BoxShadow(
                                              color: const Color(0xFF8B5CF6)
                                                  .withOpacity(0.3 * _glowAnimation.value),
                                              blurRadius: 60,
                                              spreadRadius: 12,
                                            ),
                                          ],
                                        ),
                                        child: Icon(
                                          Icons.document_scanner_rounded,
                                          size: logoSize * 0.28,
                                          color: Colors.white,
                                        ),
                                      ),
                                      // Small verified badge bottom-right
                                      Positioned(
                                        right: logoSize * 0.1,
                                        bottom: logoSize * 0.1,
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: const Color(0xFF10B981),
                                            border: Border.all(
                                                color: const Color(0xFF070714),
                                                width: 2),
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(0xFF10B981)
                                                    .withOpacity(0.5),
                                                blurRadius: 8,
                                              ),
                                            ],
                                          ),
                                          child: Icon(
                                            Icons.verified_rounded,
                                            size: logoSize * 0.1,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                          SizedBox(height: size.height * 0.035),

                          // App name with shimmer
                          FadeTransition(
                            opacity: _textFadeAnimation,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AnimatedBuilder(
                                  animation: _shimmerController,
                                  builder: (context, child) {
                                    return ShaderMask(
                                      shaderCallback: (bounds) =>
                                          LinearGradient(
                                        begin: Alignment(
                                            -2 + 4 * _shimmerController.value,
                                            0),
                                        end: Alignment(
                                            -1 + 4 * _shimmerController.value,
                                            0),
                                        colors: const [
                                          Color(0xFFE0E7FF),
                                          Color(0xFFFFFFFF),
                                          Color(0xFFC4B5FD),
                                          Color(0xFFE0E7FF),
                                        ],
                                      ).createShader(bounds),
                                      child: Text(
                                        'Smart Document',
                                        style: GoogleFonts.inter(
                                          fontSize: (size.width * 0.068)
                                              .clamp(18.0, 30.0),
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                Text(
                                  'Detective',
                                  style: GoogleFonts.inter(
                                    fontSize:
                                        (size.width * 0.068).clamp(18.0, 30.0),
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF818CF8),
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                SizedBox(height: size.height * 0.012),
                                Text(
                                  'AI-Powered Document Analysis',
                                  style: GoogleFonts.inter(
                                    fontSize:
                                        (size.width * 0.032).clamp(10.0, 15.0),
                                    fontWeight: FontWeight.w400,
                                    color: Colors.white.withOpacity(0.45),
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // Bottom: Progress bar
                      FadeTransition(
                        opacity: _textFadeAnimation,
                        child: Padding(
                          padding:
                              EdgeInsets.only(bottom: size.height * 0.05),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AnimatedBuilder(
                                animation: _progressAnimation,
                                builder: (context, _) {
                                  return Container(
                                    width: (size.width * 0.38).clamp(120.0, 200.0),
                                    height: 3,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(2),
                                      color: Colors.white.withOpacity(0.08),
                                    ),
                                    child: FractionallySizedBox(
                                      alignment: Alignment.centerLeft,
                                      widthFactor: _progressAnimation.value,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(2),
                                          gradient: const LinearGradient(
                                            colors: [
                                              Color(0xFF6366F1),
                                              Color(0xFF8B5CF6)
                                            ],
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFF6366F1)
                                                  .withOpacity(0.6),
                                              blurRadius: 8,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Initializing...',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: Colors.white.withOpacity(0.3),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SplashOrbPainter extends CustomPainter {
  final double t;
  _SplashOrbPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final orbs = [
      {'x': 0.15, 'y': 0.2, 'r': 180.0, 'color': const Color(0xFF6366F1), 'speed': 0.3},
      {'x': 0.85, 'y': 0.15, 'r': 150.0, 'color': const Color(0xFF8B5CF6), 'speed': 0.4},
      {'x': 0.1, 'y': 0.75, 'r': 120.0, 'color': const Color(0xFF06B6D4), 'speed': 0.25},
      {'x': 0.9, 'y': 0.8, 'r': 160.0, 'color': const Color(0xFFA78BFA), 'speed': 0.35},
      {'x': 0.5, 'y': 0.05, 'r': 100.0, 'color': const Color(0xFF818CF8), 'speed': 0.45},
    ];

    for (var orb in orbs) {
      final speed = orb['speed'] as double;
      final dx = (orb['x'] as double) * size.width + sin(t * 2 * pi * speed) * 50;
      final dy = (orb['y'] as double) * size.height + cos(t * 2 * pi * speed) * 40;
      final radius = orb['r'] as double;
      final color = orb['color'] as Color;

      final paint = Paint()
        ..shader = RadialGradient(
          colors: [color.withOpacity(0.15), color.withOpacity(0.0)],
        ).createShader(Rect.fromCircle(center: Offset(dx, dy), radius: radius));

      canvas.drawCircle(Offset(dx, dy), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SplashOrbPainter old) => true;
}
