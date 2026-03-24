import 'dart:async';
import 'dart:convert';
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

class _ProcessingScreenState extends State<ProcessingScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _hasError = false;
  String _errorMessage = '';

  int _currentStepIndex = 0;
  final List<String> _steps = [
    'Scanning document...',
    'Extracting data...',
    'Analyzing authenticity...'
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _controller.repeat(reverse: true);
    
    _startAnalysis();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _startAnalysis() async {
    setState(() {
      _hasError = false;
      _currentStepIndex = 0;
    });

    try {
      // Step 1
      await Future.delayed(const Duration(milliseconds: 1000));
      if (!mounted) return;
      setState(() => _currentStepIndex = 1);
      
      // Step 2
      await Future.delayed(const Duration(milliseconds: 1000));
      if (!mounted) return;
      setState(() => _currentStepIndex = 2);

      // Step 3
      await Future.delayed(const Duration(milliseconds: 1000));
      
      // Generate random mock data
      final int fraudScore = 15 + (DateTime.now().millisecond % 85);
      final bool isMatch = fraudScore <= 30; // 0-30 = Green (Match), >30 = Yellow/Red (Mismatch)
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
        ]
      };

      // Save to SharedPreferences history
      SharedPreferences prefs = await SharedPreferences.getInstance();
      List<String> historyList = prefs.getStringList('history_results') ?? [];
      historyList.insert(0, jsonEncode(mockResult));
      await prefs.setStringList('history_results', historyList);

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => ResultScreen(resultData: mockResult)),
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
      canPop: false, // Disables the physical and app-bar back buttons natively
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: _hasError
              ? _buildErrorState()
              : _buildProcessingState(),
        ),
      ),
    );
  }

  Widget _buildProcessingState() {
    final settings = Provider.of<SettingsProvider>(context);
    final isHindi = settings.isHindi;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final curvedValue = Curves.easeInOut.transform(_controller.value);
            return Container(
              width: 140.w,
              height: 140.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.blueAccent.withOpacity(curvedValue),
                  width: 4.w,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blueAccent.withOpacity(curvedValue * 0.4),
                    blurRadius: 40.r,
                    spreadRadius: 15.r,
                  )
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.document_scanner_rounded,
                    size: 60.sp,
                    color: Colors.blueAccent,
                  ),
                  // Scanning line effect
                  Positioned(
                    top: 140.h * curvedValue, // Moves down the container
                    child: Container(
                      width: 100.w,
                      height: 2.h,
                      // Additional glow
                      margin: EdgeInsets.only(bottom: 2.h),
                      decoration: BoxDecoration(
                        color: Colors.cyanAccent.withOpacity(0.8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.cyanAccent.withOpacity(0.5),
                            blurRadius: 8.r,
                            spreadRadius: 2.r,
                          )
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        SizedBox(height: 64.h),
        Text(
          tr(_steps[_currentStepIndex], isHindi),
          style: GoogleFonts.inter(
            fontSize: 24.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 12.h),
        Text(
          tr('Processing details...', isHindi),
          style: GoogleFonts.inter(
            fontSize: 16.sp,
            color: Colors.white54,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    final settings = Provider.of<SettingsProvider>(context);
    final isHindi = settings.isHindi;
    return Padding(
      padding: EdgeInsets.all(24.0.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 80.sp, color: Colors.redAccent),
          SizedBox(height: 24.h),
          Text(
            tr('Analysis Failed', isHindi),
            style: GoogleFonts.inter(fontSize: 24.sp, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          SizedBox(height: 12.h),
          Text(
            tr(_errorMessage, isHindi),
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 16.sp, color: Colors.white54),
          ),
          SizedBox(height: 48.h),
          ElevatedButton(
            onPressed: () => _startAnalysis(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              padding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 16.h),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
            ),
            child: Text(
              tr('Retry Analysis', isHindi),
              style: GoogleFonts.inter(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          )
        ],
      ),
    );
  }
}
