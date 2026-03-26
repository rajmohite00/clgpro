import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'result_screen.dart';
import 'providers/settings_provider.dart';

class ProcessingScreen extends StatefulWidget {
  final String docId;
  const ProcessingScreen({super.key, required this.docId});

  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late AnimationController _scanLineController;
  late AnimationController _progressController;

  bool _hasError = false;
  String _errorMessage = '';
  int _currentStepIndex = 0;

  final List<Map<String, dynamic>> _steps = [
    {'label': 'Scanning document', 'icon': Icons.document_scanner_rounded, 'color': const Color(0xFF6366F1)},
    {'label': 'Extracting data', 'icon': Icons.data_array_rounded, 'color': const Color(0xFF8B5CF6)},
    {'label': 'Analyzing authenticity', 'icon': Icons.verified_user_rounded, 'color': const Color(0xFF06B6D4)},
    {'label': 'Generating report', 'icon': Icons.summarize_rounded, 'color': const Color(0xFF10B981)},
  ];

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _rotateController = AnimationController(vsync: this, duration: const Duration(seconds: 3))
      ..repeat();
    _scanLineController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))
          ..repeat();
    _progressController = AnimationController(vsync: this, duration: const Duration(seconds: 4));

    _startAnalysis();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    _scanLineController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  Future<void> _startAnalysis() async {
    setState(() {
      _hasError = false;
      _currentStepIndex = 0;
    });
    _progressController.reset();
    _progressController.forward();

    try {
      for (int i = 0; i < _steps.length; i++) {
        await Future.delayed(const Duration(milliseconds: 900));
        if (!mounted) return;
        setState(() => _currentStepIndex = i);
      }

      await Future.delayed(const Duration(milliseconds: 600));

      final int fraudScore = 15 + (DateTime.now().millisecond % 85);
      final bool isMatch = fraudScore <= 30;
      final dateStr = DateTime.now().toString().split(' ')[0];

      final mockResult = {
        'date': dateStr,
        'status': isMatch ? 'Match' : 'Mismatch',
        'fraudScore': fraudScore,
        'summary': 'Driver License & Passport Verification',
        'comparisons': [
          {
            'field': 'Full Name',
            'doc1': 'John Doe',
            'doc2': isMatch ? 'John Doe' : 'Jonathan Doe',
            'status': isMatch ? 'Match' : 'Partial'
          },
          {
            'field': 'Date of Birth',
            'doc1': '15-08-1990',
            'doc2': '15-08-1990',
            'status': 'Match'
          },
          {
            'field': 'ID Number',
            'doc1': 'A123456789',
            'doc2': isMatch ? 'A123456789' : 'B987654321',
            'status': isMatch ? 'Match' : 'Mismatch'
          },
          {
            'field': 'Address',
            'doc1': '123 MG Road, Mumbai',
            'doc2': isMatch ? '123 MG Road, Mumbai' : '456 Nehru Nagar, Delhi',
            'status': isMatch ? 'Match' : 'Mismatch'
          },
        ]
      };

      SharedPreferences prefs = await SharedPreferences.getInstance();
      List<String> historyList = prefs.getStringList('history_results') ?? [];
      historyList.insert(0, jsonEncode(mockResult));
      await prefs.setStringList('history_results', historyList);

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => ResultScreen(resultData: mockResult),
          transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _errorMessage = 'Analysis Failed: Something went wrong.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFF07071A),
        body: Center(
          child: _hasError ? _buildErrorState() : _buildProcessingState(),
        ),
      ),
    );
  }

  Widget _buildProcessingState() {
    final settings = Provider.of<SettingsProvider>(context);
    final isHindi = settings.isHindi;
    final step = _steps[_currentStepIndex];
    final stepColor = step['color'] as Color;

    return Stack(
      children: [
        // Animated background orbs
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, _) {
            return CustomPaint(
              painter: _ProcessingBgPainter(_pulseController.value, stepColor),
              size: Size.infinite,
            );
          },
        ),

        Padding(
          padding: EdgeInsets.symmetric(horizontal: 32.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Main scanning animation
              SizedBox(
                width: 200.w,
                height: 200.w,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer pulse ring
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, _) {
                        final pulse = Curves.easeInOut.transform(_pulseController.value);
                        return Container(
                          width: 200.w,
                          height: 200.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: stepColor.withOpacity(0.15 + 0.15 * pulse),
                              width: 1.w,
                            ),
                          ),
                        );
                      },
                    ),
                    // Rotating dashed ring
                    AnimatedBuilder(
                      animation: _rotateController,
                      builder: (context, _) {
                        return Transform.rotate(
                          angle: _rotateController.value * 2 * pi,
                          child: Container(
                            width: 164.w,
                            height: 164.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: SweepGradient(
                                colors: [
                                  stepColor.withOpacity(0),
                                  stepColor.withOpacity(0.6),
                                  stepColor,
                                  stepColor.withOpacity(0),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    // Inner circle
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, _) {
                        final pulse = Curves.easeInOut.transform(_pulseController.value);
                        return Container(
                          width: 140.w,
                          height: 140.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF0F0E24),
                            boxShadow: [
                              BoxShadow(
                                color: stepColor.withOpacity(0.3 + 0.2 * pulse),
                                blurRadius: 30.r + 10 * pulse,
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Scan line
                              AnimatedBuilder(
                                animation: _scanLineController,
                                builder: (context, _) {
                                  final progress = _scanLineController.value;
                                  return Positioned(
                                    top: 10.h + (120.h - 20.h) * progress,
                                    child: Container(
                                      width: 100.w,
                                      height: 2.h,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.transparent,
                                            stepColor.withOpacity(0.8),
                                            Colors.transparent,
                                          ],
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: stepColor.withOpacity(0.5),
                                            blurRadius: 8.r,
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                              Icon(step['icon'] as IconData, size: 52.sp, color: stepColor),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(height: 48.h),

              // Step label
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
                        .animate(animation),
                    child: child,
                  ),
                ),
                child: Text(
                  tr(_steps[_currentStepIndex]['label'] as String, isHindi),
                  key: ValueKey(_currentStepIndex),
                  style: GoogleFonts.inter(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'AI is working its magic...',
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  color: Colors.white.withOpacity(0.4),
                ),
              ),
              SizedBox(height: 40.h),

              // Step indicators
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_steps.length, (i) {
                  final isDone = i <= _currentStepIndex;
                  final isCurrent = i == _currentStepIndex;
                  final color = (_steps[i]['color'] as Color);
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    margin: EdgeInsets.symmetric(horizontal: 4.w),
                    width: isCurrent ? 32.w : 10.w,
                    height: 10.h,
                    decoration: BoxDecoration(
                      color: isDone ? color : Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(5.r),
                      boxShadow: isCurrent
                          ? [BoxShadow(color: color.withOpacity(0.6), blurRadius: 8.r)]
                          : null,
                    ),
                  );
                }),
              ),
              SizedBox(height: 32.h),

              // Progress bar
              AnimatedBuilder(
                animation: _progressController,
                builder: (context, _) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Processing...',
                            style: GoogleFonts.inter(
                              fontSize: 12.sp,
                              color: Colors.white.withOpacity(0.4),
                            ),
                          ),
                          Text(
                            '${(_progressController.value * 100).toInt()}%',
                            style: GoogleFonts.inter(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w700,
                              color: stepColor,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8.h),
                      Container(
                        height: 4.h,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(2.r),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: _progressController.value,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [stepColor, stepColor.withBlue(255)],
                              ),
                              borderRadius: BorderRadius.circular(2.r),
                              boxShadow: [
                                BoxShadow(
                                  color: stepColor.withOpacity(0.6),
                                  blurRadius: 6.r,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    final settings = Provider.of<SettingsProvider>(context);
    final isHindi = settings.isHindi;

    return Padding(
      padding: EdgeInsets.all(32.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.3)),
            ),
            child: Icon(Icons.error_outline_rounded, size: 56.sp, color: const Color(0xFFEF4444)),
          ),
          SizedBox(height: 28.h),
          Text(
            tr('Analysis Failed', isHindi),
            style: GoogleFonts.inter(
              fontSize: 24.sp,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            _errorMessage,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 14.sp, color: Colors.white.withOpacity(0.45)),
          ),
          SizedBox(height: 48.h),
          GestureDetector(
            onTap: () => _startAnalysis(),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 18.h),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                ),
                borderRadius: BorderRadius.circular(20.r),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withOpacity(0.4),
                    blurRadius: 20.r,
                    offset: Offset(0, 8.h),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.refresh_rounded, color: Colors.white, size: 20.sp),
                  SizedBox(width: 8.w),
                  Text(
                    tr('Retry Analysis', isHindi),
                    style: GoogleFonts.inter(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProcessingBgPainter extends CustomPainter {
  final double t;
  final Color stepColor;
  _ProcessingBgPainter(this.t, this.stepColor);

  @override
  void paint(Canvas canvas, Size size) {
    final orbs = [
      {'x': 0.2, 'y': 0.1, 'r': 200.0, 'speed': 0.2},
      {'x': 0.8, 'y': 0.3, 'r': 160.0, 'speed': 0.3},
      {'x': 0.1, 'y': 0.8, 'r': 140.0, 'speed': 0.25},
      {'x': 0.9, 'y': 0.7, 'r': 180.0, 'speed': 0.15},
    ];

    for (var orb in orbs) {
      final speed = orb['speed'] as double;
      final dx = (orb['x'] as double) * size.width + sin(t * 2 * pi * speed) * 50;
      final dy = (orb['y'] as double) * size.height + cos(t * 2 * pi * speed) * 40;
      final radius = orb['r'] as double;

      final paint = Paint()
        ..shader = RadialGradient(
          colors: [stepColor.withOpacity(0.08), stepColor.withOpacity(0.0)],
        ).createShader(Rect.fromCircle(center: Offset(dx, dy), radius: radius));

      canvas.drawCircle(Offset(dx, dy), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ProcessingBgPainter old) => true;
}
