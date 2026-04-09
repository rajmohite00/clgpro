import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/theme_provider.dart';
import 'signup_screen.dart';
import 'forgot_password_screen.dart';
import 'dashboard_screen.dart';
import 'utils/animations.dart';
import 'widgets/logo_widget.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  LOGIN SCREEN — Forensic Lab Aesthetic
// ─────────────────────────────────────────────────────────────────────────────
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _emailCtrl  = TextEditingController();
  final _passCtrl   = TextEditingController();
  final _emailFocus = FocusNode();
  final _passFocus  = FocusNode();
  bool _passVisible = false;

  late AnimationController _entryCtrl;
  late AnimationController _bgCtrl;
  late List<Animation<double>> _itemFades;
  late List<Animation<double>> _itemSlides;

  @override
  void initState() {
    super.initState();

    _bgCtrl = AnimationController(
      vsync: this, duration: const Duration(seconds: 8),
    )..repeat();

    _entryCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1000),
    );

    // 5 staggered items: [logo, title, emailField, passField, button]
    _itemFades = List.generate(5, (i) => Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: Interval(i * 0.12, (i * 0.12 + 0.4).clamp(0.0, 1.0), curve: Curves.easeOut),
      ),
    ));
    _itemSlides = List.generate(5, (i) => Tween<double>(begin: 30, end: 0).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: Interval(i * 0.12, (i * 0.12 + 0.45).clamp(0.0, 1.0), curve: Curves.easeOutCubic),
      ),
    ));

    _entryCtrl.forward();

    _emailFocus.addListener(() => setState(() {}));
    _passFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _bgCtrl.dispose();
    _emailCtrl.dispose(); _passCtrl.dispose();
    _emailFocus.dispose(); _passFocus.dispose();
    super.dispose();
  }

  Widget _animated(int i, Widget child) => AnimatedBuilder(
    animation: _entryCtrl,
    builder: (_, __) => Opacity(
      opacity: _itemFades[i].value,
      child: Transform.translate(
        offset: Offset(0, _itemSlides[i].value),
        child: child,
      ),
    ),
  );

  void _showErr(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: AppTheme.crimson, size: 16),
          SizedBox(width: 8),
          Expanded(child: Text(msg,
            style: GoogleFonts.jetBrainsMono(color: AppTheme.textPrimary, fontSize: 12))),
        ],
      ),
      backgroundColor: AppTheme.inkMid,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.r),
        side: const BorderSide(color: AppTheme.crimson),
      ),
      margin: EdgeInsets.all(16.w),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final auth     = Provider.of<AuthProvider>(context);
    final settings = Provider.of<SettingsProvider>(context);
    final isHindi  = settings.isHindi;
    final theme    = Theme.of(context);
    final cs       = theme.colorScheme;
    final isDark   = theme.brightness == Brightness.dark;

    final bg      = isDark ? AppTheme.ink : AppTheme.lightBg;
    final cardBg  = isDark ? AppTheme.inkMid : Colors.white;
    final txtPri  = isDark ? AppTheme.textPrimary : AppTheme.lightText;
    final txtSec  = isDark ? AppTheme.textSecondary : AppTheme.lightTextSub;
    final bdr     = isDark ? AppTheme.borderLight : AppTheme.lightBorder;
    final accent  = cs.primary;

    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        children: [
          // ── Animated hex-grid background ─────────────────────────────────
          if (isDark) AnimatedBuilder(
            animation: _bgCtrl,
            builder: (_, __) => CustomPaint(
              painter: _LoginBgPainter(_bgCtrl.value),
              size: Size.infinite,
            ),
          ),

          // ── Accent glow top-left ──────────────────────────────────────────
          if (isDark) Positioned(
            top: -80, left: -60,
            child: Container(
              width: 280.w, height: 280.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  AppTheme.jade.withOpacity(0.08),
                  Colors.transparent,
                ]),
              ),
            ),
          ),

          // ── Content ───────────────────────────────────────────────────────
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [

                      // Logo + Brand ─────────────────────────────────────────
                      _animated(0, Center(
                        child: Column(
                          children: [
                            Container(
                              width: 56.w, height: 56.w,
                              decoration: BoxDecoration(
                                color: AppTheme.inkMid,
                                borderRadius: BorderRadius.circular(14.r),
                                border: Border.all(
                                  color: accent.withOpacity(0.5), width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: accent.withOpacity(0.2),
                                    blurRadius: 24,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: DocVerifyLogo(
                                  size: 26.sp,
                                  color: accent,
                                  glowOpacity: 1.0,
                                ),
                              ),
                            ),
                            SizedBox(height: 16.h),
                            Text(
                              'DOCVERIFY',
                              style: GoogleFonts.syne(
                                fontSize: 20.sp,
                                fontWeight: FontWeight.w800,
                                color: txtPri,
                                letterSpacing: 3.0,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              tr('FRAUD INTELLIGENCE SYSTEM', isHindi),
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 9.sp,
                                color: accent.withOpacity(0.6),
                                letterSpacing: 1.8,
                              ),
                            ),
                          ],
                        ),
                      )),
                      SizedBox(height: 36.h),

                      // Form card ────────────────────────────────────────────
                      _animated(1, Container(
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(color: bdr),
                          boxShadow: isDark
                              ? [BoxShadow(
                                    color: Colors.black.withOpacity(0.4),
                                    blurRadius: 30, offset: const Offset(0, 8)),
                                ]
                              : [BoxShadow(
                                    color: Colors.black.withOpacity(0.06),
                                    blurRadius: 20, offset: const Offset(0, 4)),
                                ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Card header bar
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppTheme.inkSurface
                                    : AppTheme.lightBorder.withOpacity(0.3),
                                borderRadius: BorderRadius.vertical(top: Radius.circular(12.r)),
                                border: Border(bottom: BorderSide(color: bdr)),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 6.w, height: 6.w,
                                    decoration: BoxDecoration(
                                      color: accent,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(color: accent.withOpacity(0.5), blurRadius: 6),
                                      ],
                                    ),
                                  ),
                                  SizedBox(width: 8.w),
                                  Text(
                                    tr('SECURE LOGIN', isHindi),
                                    style: GoogleFonts.jetBrainsMono(
                                      fontSize: 10.sp,
                                      color: accent,
                                      letterSpacing: 2,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            Padding(
                              padding: EdgeInsets.all(20.w),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Email ───────────────────────────────────
                                  _animated(2, Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _fieldLabel('EMAIL ADDRESS', isDark),
                                      SizedBox(height: 6.h),
                                      _buildField(
                                        ctrl: _emailCtrl,
                                        focus: _emailFocus,
                                        hint: 'agent@secure.gov',
                                        icon: Icons.alternate_email_rounded,
                                        accent: accent, isDark: isDark,
                                        txtPri: txtPri, bdr: bdr,
                                        keyboardType: TextInputType.emailAddress,
                                      ),
                                    ],
                                  )),
                                  SizedBox(height: 16.h),

                                  // Password ────────────────────────────────
                                  _animated(3, Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _fieldLabel('PASSWORD', isDark),
                                      SizedBox(height: 6.h),
                                      _buildField(
                                        ctrl: _passCtrl,
                                        focus: _passFocus,
                                        hint: '••••••••••••',
                                        icon: Icons.lock_outline_rounded,
                                        accent: accent, isDark: isDark,
                                        txtPri: txtPri, bdr: bdr,
                                        isPassword: true,
                                        passVisible: _passVisible,
                                        onTogglePass: () =>
                                            setState(() => _passVisible = !_passVisible),
                                      ),
                                      SizedBox(height: 10.h),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: GestureDetector(
                                          onTap: () => Navigator.push(context,
                                              FadeSlideRoute(page: const ForgotPasswordScreen())),
                                          child: Text(
                                            tr('Forgot password?', isHindi),
                                            style: GoogleFonts.syne(
                                              fontSize: 12.sp,
                                              color: accent.withOpacity(0.8),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  )),

                                  SizedBox(height: 24.h),

                                  // Submit button ───────────────────────────
                                  _animated(4, TapScale(
                                    onTap: auth.isLoading ? null : () async {
                                      final ok = await auth.login(
                                          _emailCtrl.text.trim(), _passCtrl.text);
                                      if (ok && mounted) {
                                        Navigator.pushReplacement(context,
                                            FadeSlideRoute(page: const DashboardScreen()));
                                      } else if (auth.errorMessage != null) {
                                        _showErr(auth.errorMessage!);
                                      }
                                    },
                                    child: Container(
                                      height: 48.h,
                                      decoration: BoxDecoration(
                                        color: auth.isLoading
                                            ? accent.withOpacity(0.5)
                                            : accent,
                                        borderRadius: BorderRadius.circular(8.r),
                                        boxShadow: [
                                          BoxShadow(
                                            color: accent.withOpacity(0.35),
                                            blurRadius: 16,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: auth.isLoading
                                            ? SizedBox(
                                                width: 18, height: 18,
                                                child: CircularProgressIndicator(
                                                  color: isDark ? AppTheme.ink : Colors.white,
                                                  strokeWidth: 2,
                                                ),
                                              )
                                            : Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.lock_open_rounded,
                                                    size: 16.sp,
                                                    color: isDark ? AppTheme.ink : Colors.white,
                                                  ),
                                                  SizedBox(width: 8.w),
                                                  Text(
                                                    tr('AUTHENTICATE', isHindi),
                                                    style: GoogleFonts.syne(
                                                      fontSize: 13.sp,
                                                      fontWeight: FontWeight.w700,
                                                      color: isDark ? AppTheme.ink : Colors.white,
                                                      letterSpacing: 1.5,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                      ),
                                    ),
                                  )),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )),

                      SizedBox(height: 24.h),

                      // Sign up link ─────────────────────────────────────────
                      _animated(4, Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            tr("No account? ", isHindi),
                            style: GoogleFonts.syne(fontSize: 13.sp, color: txtSec),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.push(context,
                                MaterialPageRoute(builder: (_) => const SignupScreen())),
                            child: Text(
                              tr('Register', isHindi),
                              style: GoogleFonts.syne(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w700,
                                color: accent,
                              ),
                            ),
                          ),
                        ],
                      )),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fieldLabel(String t, bool isDark) => Text(
    t,
    style: GoogleFonts.jetBrainsMono(
      fontSize: 9.5.sp,
      fontWeight: FontWeight.w600,
      color: isDark ? AppTheme.textMuted : AppTheme.lightTextSub,
      letterSpacing: 1.5,
    ),
  );

  Widget _buildField({
    required TextEditingController ctrl,
    required FocusNode focus,
    required String hint,
    required IconData icon,
    required Color accent,
    required bool isDark,
    required Color txtPri,
    required Color bdr,
    TextInputType keyboardType = TextInputType.text,
    bool isPassword = false,
    bool passVisible = false,
    VoidCallback? onTogglePass,
  }) {
    final focused = focus.hasFocus;
    final fillColor = isDark ? AppTheme.inkSurface : Colors.white;
    return TextField(
      controller: ctrl,
      focusNode: focus,
      obscureText: isPassword && !passVisible,
      keyboardType: keyboardType,
      style: GoogleFonts.jetBrainsMono(color: txtPri, fontSize: 13.sp),
      cursorColor: accent,
      cursorWidth: 1.5,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.jetBrainsMono(
          color: isDark ? AppTheme.textMuted : AppTheme.lightBorder,
          fontSize: 13.sp,
        ),
        prefixIcon: Icon(icon,
          size: 16.sp,
          color: focused ? accent : (isDark ? AppTheme.textMuted : AppTheme.lightBorder),
        ),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  passVisible ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                  size: 16.sp,
                  color: isDark ? AppTheme.textMuted : AppTheme.lightBorder,
                ),
                onPressed: onTogglePass,
              )
            : null,
        filled: true,
        fillColor: fillColor,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: BorderSide(color: bdr),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: BorderSide(color: accent, width: 1.5),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
      ),
    );
  }
}

// ── Login background painter — fine grid + moving orb ────────────────────────
class _LoginBgPainter extends CustomPainter {
  final double t;
  _LoginBgPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = AppTheme.jade.withOpacity(0.035)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    const spacing = 40.0;
    for (double x = 0; x <= size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y <= size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Moving glow orb
    final ox = size.width * 0.75 + sin(t * 2 * pi) * 60;
    final oy = size.height * 0.25 + cos(t * 2 * pi * 0.7) * 40;

    final orbPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppTheme.jade.withOpacity(0.06),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: Offset(ox, oy), radius: 220));
    canvas.drawCircle(Offset(ox, oy), 220, orbPaint);
  }

  @override
  bool shouldRepaint(covariant _LoginBgPainter old) => old.t != t;
}
