import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
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
    });

    try {
      // API call placeholder (/analyze-docs)
      // Throw random timeout occasionally for realistic testing?
      // In production, real HTTP calls happen here.
      await Future.delayed(const Duration(seconds: 4));
      
      // We force a specific response for demonstration according to requirements.
      final mockResult = {
        'status': 'Mismatch', // Set to 'Match' to see success layout
        'comparisons': [
          {
            'field': 'Full Name',
            'doc1': 'John Doe',
            'doc2': 'Johnathan Doe',
            'status': 'Partial'
          },
          {
            'field': 'Date of Birth',
            'doc1': '15-08-1990',
            'doc2': '15-08-1990',
            'status': 'Match'
          },
          {
            'field': 'Address',
            'doc1': '123 Fake Street, NY',
            'doc2': '456 Different St, NY',
            'status': 'Mismatch'
          },
        ]
      };

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => ResultScreen(resultData: mockResult)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _errorMessage = 'API Timeout: Failed to analyze documents. Please try again.';
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
          tr('Analyzing Documents...', isHindi),
          style: GoogleFonts.inter(
            fontSize: 24.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 12.h),
        Text(
          tr('Checking authenticity & mismatches', isHindi),
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
