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

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
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
        pageBuilder: (context, animation, secondaryAnimation) => const LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final isHindi = settings.isHindi;
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A), // Matches dark theme splash
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0D1B2A), Color(0xFF1B1A3A), Color(0xFF281944)], // Dark to Deep Purple
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const BouncingScrollPhysics(),
                onPageChanged: (int page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                children: [
                  _buildPage(
                    title: tr("Verify Documents\nInstantly", isHindi),
                    subtitle: tr("Upload Aadhaar, PAN, or any document and let AI verify authenticity in seconds.", isHindi),
                    icon: Icons.verified_user_rounded,
                    glowColor: Colors.blueAccent,
                  ),
                  _buildPage(
                    title: tr("Detect Mismatches\n& Fraud", isHindi),
                    subtitle: tr("Compare multiple documents and identify mismatches with smart AI analysis.", isHindi),
                    icon: Icons.document_scanner_rounded,
                    glowColor: Colors.purpleAccent,
                  ),
                ],
              ),
            ),
            _buildBottomSection(isHindi),
          ],
        ),
      ),
    );
  }

  Widget _buildPage({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color glowColor,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 32.0.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _AnimatedImage(icon: icon, glowColor: glowColor),
          SizedBox(height: 50.h),
          _AnimatedText(
            title: title,
            subtitle: subtitle,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSection(bool isHindi) {
    return Padding(
      padding: EdgeInsets.only(bottom: 60.0.h, left: 32.w, right: 32.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(2, (index) => _buildDot(index)),
          ),
          SizedBox(height: 48.h),
          _AnimatedButton(
            text: _currentPage == 0 ? tr("Next", isHindi) : tr("Get Started", isHindi),
            onPressed: _onNext,
            isPrimary: _currentPage == 1,
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    final isActive = _currentPage == index;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      margin: EdgeInsets.symmetric(horizontal: 6.w),
      height: 8.h,
      width: isActive ? 32 : 8,
      decoration: BoxDecoration(
        color: isActive ? Colors.blueAccent : Colors.white24,
        borderRadius: BorderRadius.circular(4.r),
        boxShadow: isActive
            ? [BoxShadow(color: Colors.blueAccent.withOpacity(0.5), blurRadius: 10.r)]
            : null,
      ),
    );
  }
}

class _AnimatedImage extends StatefulWidget {
  final IconData icon;
  final Color glowColor;
  
  const _AnimatedImage({required this.icon, required this.glowColor});

  @override
  State<_AnimatedImage> createState() => _AnimatedImageState();
}

class _AnimatedImageState extends State<_AnimatedImage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _slideAnimation = Tween<Offset>(begin: Offset(0.w, 0.15.h), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutQuart),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant _AnimatedImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.icon != widget.icon) {
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          width: 220.w,
          height: 220.h,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.glowColor.withOpacity(0.08),
            border: Border.all(color: widget.glowColor.withOpacity(0.3), width: 2.w),
            boxShadow: [
              BoxShadow(
                color: widget.glowColor.withOpacity(0.25),
                blurRadius: 60.r,
                spreadRadius: 10.r,
              ),
            ],
          ),
          child: Icon(
            widget.icon,
            size: 110.sp,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _AnimatedText extends StatefulWidget {
  final String title;
  final String subtitle;
  
  const _AnimatedText({required this.title, required this.subtitle});

  @override
  State<_AnimatedText> createState() => _AnimatedTextState();
}

class _AnimatedTextState extends State<_AnimatedText> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _slideAnimation = Tween<Offset>(begin: Offset(0.w, 0.2.h), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.2, 1.0, curve: Curves.easeOutQuart)),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.2, 1.0, curve: Curves.easeIn)),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant _AnimatedText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.title != widget.title) {
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Column(
          children: [
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 32.sp,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                height: 1.2.h,
                letterSpacing: -0.5,
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              widget.subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 16.sp,
                fontWeight: FontWeight.w400,
                color: Colors.white.withOpacity(0.7),
                height: 1.5.h,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isPrimary;
  
  const _AnimatedButton({
    required this.text, 
    required this.onPressed,
    this.isPrimary = false,
  });

  @override
  State<_AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<_AnimatedButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 150));
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) => _controller.forward();
  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onPressed();
  }
  void _onTapCancel() => _controller.reverse();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: double.infinity,
          height: 60.h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.r),
            gradient: LinearGradient(
              colors: widget.isPrimary 
                ? [const Color(0xFF3B82F6), const Color(0xFF8B5CF6)] 
                : [Colors.white.withOpacity(0.1), Colors.white.withOpacity(0.1)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            border: widget.isPrimary ? null : Border.all(color: Colors.white24, width: 1.5.w),
            boxShadow: widget.isPrimary ? [
              BoxShadow(
                color: Color(0xFF8B5CF6).withOpacity(0.4),
                blurRadius: 20.r,
                spreadRadius: 2.r,
                offset: Offset(0.w, 8.h),
              ),
            ] : null,
          ),
          child: Center(
            child: Text(
              widget.text,
              style: GoogleFonts.inter(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
