import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dashboard_screen.dart';
import 'login_screen.dart';
import 'onboarding_screen.dart';
import 'providers/theme_provider.dart';
import 'widgets/logo_widget.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _gridCtrl;
  late AnimationController _contentCtrl;
  late AnimationController _scanCtrl;
  late AnimationController _glowCtrl;

  late Animation<double> _gridReveal;
  late Animation<double> _logoFade;
  late Animation<double> _logoScale;
  late Animation<double> _textSlide;
  late Animation<double> _statusFade;
  late Animation<double> _progressBar;
  late Animation<double> _glowPulse;

  // Typewriter state
  final List<String> _bootLines = [
    'INITIALIZING FORENSIC ENGINE...',
    'LOADING AI VERIFICATION MODEL...',
    'ESTABLISHING SECURE CHANNEL...',
    'READY.',
  ];
  int _visibleLines = 0;
  Timer? _typeTimer;

  @override
  void initState() {
    super.initState();

    _gridCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1200),
    );
    _contentCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1000),
    );
    _scanCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 2000),
    )..repeat();
    _glowCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _gridReveal = CurvedAnimation(parent: _gridCtrl, curve: Curves.easeOut);

    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _contentCtrl, curve: const Interval(0.0, 0.4, curve: Curves.easeOut)),
    );
    _logoScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _contentCtrl, curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack)),
    );
    _textSlide = Tween<double>(begin: 24, end: 0).animate(
      CurvedAnimation(parent: _contentCtrl, curve: const Interval(0.25, 0.7, curve: Curves.easeOutCubic)),
    );
    _statusFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _contentCtrl, curve: const Interval(0.4, 0.8, curve: Curves.easeOut)),
    );
    _progressBar = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _contentCtrl, curve: const Interval(0.5, 1.0, curve: Curves.easeInOut)),
    );
    _glowPulse = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut),
    );

    // Boot sequence
    _gridCtrl.forward();
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _contentCtrl.forward();
    });
    Future.delayed(const Duration(milliseconds: 800), () {
      _startTypewriter();
    });

    _checkAuthentication();
  }

  void _startTypewriter() {
    int line = 0;
    _typeTimer = Timer.periodic(const Duration(milliseconds: 380), (t) {
      if (!mounted) { t.cancel(); return; }
      if (line < _bootLines.length) {
        setState(() => _visibleLines = line + 1);
        line++;
      } else {
        t.cancel();
      }
    });
  }

  Future<void> _checkAuthentication() async {
    await Future.delayed(const Duration(milliseconds: 3000));
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (!mounted) return;

    final dest = (token != null && token.isNotEmpty)
        ? const DashboardScreen()
        : const OnboardingScreen();

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => dest,
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  void dispose() {
    _gridCtrl.dispose();
    _contentCtrl.dispose();
    _scanCtrl.dispose();
    _glowCtrl.dispose();
    _typeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.ink,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Animated grid background ──────────────────────────────────────
          AnimatedBuilder(
            animation: _gridReveal,
            builder: (_, __) => CustomPaint(
              painter: _GridPainter(_gridReveal.value),
            ),
          ),

          // ── Moving scanline ───────────────────────────────────────────────
          AnimatedBuilder(
            animation: _scanCtrl,
            builder: (_, __) {
              final h = MediaQuery.of(context).size.height;
              return Positioned(
                top: h * _scanCtrl.value,
                left: 0, right: 0,
                child: Container(
                  height: 2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        AppTheme.jade.withOpacity(0.3),
                        AppTheme.jade.withOpacity(0.6),
                        AppTheme.jade.withOpacity(0.3),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          // ── Main content ──────────────────────────────────────────────────
          SafeArea(
            child: AnimatedBuilder(
              animation: _contentCtrl,
              builder: (_, __) => Column(
                children: [
                  const Spacer(flex: 3),

                  // ── Logo mark ─────────────────────────────────────────────
                  Opacity(
                    opacity: _logoFade.value,
                    child: Transform.scale(
                      scale: _logoScale.value,
                      child: AnimatedBuilder(
                        animation: _glowCtrl,
                        builder: (_, child) => Container(
                          width: 88.w,
                          height: 88.w,
                          decoration: BoxDecoration(
                            color: AppTheme.inkMid,
                            borderRadius: BorderRadius.circular(20.r),
                            border: Border.all(
                              color: AppTheme.jade.withOpacity(0.5 * _glowPulse.value),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.jade.withOpacity(0.25 * _glowPulse.value),
                                blurRadius: 40,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: Center(
                            child: _HexShieldIcon(
                              color: AppTheme.jade,
                              size: 44.sp,
                              glowOpacity: _glowPulse.value,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 28.h),

                  // ── App name ──────────────────────────────────────────────
                  Transform.translate(
                    offset: Offset(0, _textSlide.value),
                    child: Opacity(
                      opacity: _logoFade.value,
                      child: Column(
                        children: [
                          Text(
                            'DOCVERIFY',
                            style: GoogleFonts.syne(
                              fontSize: 28.sp,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimary,
                              letterSpacing: 4.0,
                            ),
                          ),
                          SizedBox(height: 6.h),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 20.w, height: 1,
                                color: AppTheme.jade.withOpacity(0.4),
                              ),
                              SizedBox(width: 8.w),
                              Text(
                                'FRAUD INTELLIGENCE SYSTEM',
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 9.5.sp,
                                  color: AppTheme.jade.withOpacity(0.7),
                                  letterSpacing: 2.5,
                                ),
                              ),
                              SizedBox(width: 8.w),
                              Container(
                                width: 20.w, height: 1,
                                color: AppTheme.jade.withOpacity(0.4),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Spacer(flex: 2),

                  // ── Boot log terminal ─────────────────────────────────────
                  Opacity(
                    opacity: _statusFade.value,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 32.w),
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(14.w),
                        decoration: BoxDecoration(
                          color: AppTheme.inkMid,
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(
                            color: AppTheme.borderLight,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 8.w, height: 8.w,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppTheme.jade,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.jade.withOpacity(0.5),
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(width: 6.w),
                                Text(
                                  'SYSTEM BOOT',
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 9.sp,
                                    color: AppTheme.jade,
                                    letterSpacing: 2,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 10.h),
                            ...List.generate(_visibleLines, (i) => Padding(
                              padding: EdgeInsets.only(bottom: 4.h),
                              child: Row(
                                children: [
                                  Text(
                                    '> ',
                                    style: GoogleFonts.jetBrainsMono(
                                      fontSize: 10.sp,
                                      color: AppTheme.jade.withOpacity(0.6),
                                    ),
                                  ),
                                  Text(
                                    _bootLines[i],
                                    style: GoogleFonts.jetBrainsMono(
                                      fontSize: 10.sp,
                                      color: i == _visibleLines - 1
                                          ? AppTheme.textPrimary
                                          : AppTheme.textMuted,
                                      fontWeight: i == _visibleLines - 1
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                            )),
                            // Cursor blink
                            if (_visibleLines < _bootLines.length) ...[
                              SizedBox(height: 2.h),
                              _BlinkingCursor(),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 20.h),

                  // ── Progress bar ──────────────────────────────────────────
                  Opacity(
                    opacity: _statusFade.value,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 32.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(2.r),
                            child: Container(
                              height: 3.h,
                              color: AppTheme.inkMid,
                              child: FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: _progressBar.value,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        AppTheme.jade.withOpacity(0.5),
                                        AppTheme.jade,
                                      ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.jade.withOpacity(0.5),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 48.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Custom hex-shield icon using CustomPainter ────────────────────────────────
class _HexShieldIcon extends StatelessWidget {
  final Color color;
  final double size;
  final double glowOpacity;
  const _HexShieldIcon({required this.color, required this.size, this.glowOpacity = 1.0});

  @override
  Widget build(BuildContext context) => DocVerifyLogo(
    size: size,
    color: color,
    glowOpacity: glowOpacity,
  );
}

// ── Blinking cursor ───────────────────────────────────────────────────────────
class _BlinkingCursor extends StatefulWidget {
  @override
  State<_BlinkingCursor> createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<_BlinkingCursor>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _ctrl,
    builder: (_, __) => Opacity(
      opacity: _ctrl.value,
      child: Container(
        width: 8, height: 14,
        color: AppTheme.jade,
      ),
    ),
  );
}

// ── Isometric grid background painter ────────────────────────────────────────
class _GridPainter extends CustomPainter {
  final double progress;
  _GridPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.jade.withOpacity(0.04)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    const spacing = 36.0;

    // Vertical lines — draw progressively
    final vLines = (size.width / spacing).ceil() + 1;
    for (int i = 0; i < vLines; i++) {
      final x = i * spacing;
      final lineProgress = (progress * vLines - i).clamp(0.0, 1.0);
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height * lineProgress),
        paint,
      );
    }

    // Horizontal lines
    final hLines = (size.height / spacing).ceil() + 1;
    for (int i = 0; i < hLines; i++) {
      final y = i * spacing;
      final lineProgress = (progress * hLines - i).clamp(0.0, 1.0);
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width * lineProgress, y),
        paint,
      );
    }

    // Corner accent dots at intersections (only when nearly fully revealed)
    if (progress > 0.7) {
      final dotPaint = Paint()
        ..color = AppTheme.jade.withOpacity(0.12 * ((progress - 0.7) / 0.3))
        ..style = PaintingStyle.fill;

      for (int i = 0; i <= vLines; i++) {
        for (int j = 0; j <= hLines; j++) {
          canvas.drawCircle(
            Offset(i * spacing, j * spacing), 1.5, dotPaint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter old) => old.progress != progress;
}
