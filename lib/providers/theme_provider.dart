import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/animations.dart';

// ─── FORENSIC INTELLIGENCE — Design Tokens ────────────────────────────────────
// Aesthetic: Terminal noir meets luxury cyber-forensic lab
// Fonts: Syne (display) + JetBrains Mono (data values)
// Palette: Deep Ink + Electric Jade + Crimson Alert
class AppTheme {
  // ── Core Identity ─────────────────────────────────────────────────────────
  static const Color ink          = Color(0xFF050A0F);   // Deepest background
  static const Color inkLight     = Color(0xFF0C1520);   // Surface layer
  static const Color inkMid       = Color(0xFF111D2B);   // Card backgrounds
  static const Color inkSurface   = Color(0xFF162234);   // Elevated cards

  // ── Accent system ─────────────────────────────────────────────────────────
  static const Color jade         = Color(0xFF00FFA3);   // Electric jade — primary action
  static const Color jadeDim      = Color(0xFF00CC82);   // Muted jade
  static const Color jadeGlow     = Color(0x3300FFA3);   // Glow layer

  static const Color crimson      = Color(0xFFFF2D55);   // Fraud / error
  static const Color crimsonDim   = Color(0xFF8B0000);   // Muted crimson
  static const Color crimsonGlow  = Color(0x33FF2D55);   // Glow

  static const Color amber        = Color(0xFFFFB547);   // Warning / medium risk
  static const Color amberGlow    = Color(0x33FFB547);

  // ── Legacy aliases (keep other screens compiling) ─────────────────────────
  static const Color primary    = jade;
  static const Color secondary  = jade;
  static const Color accent     = jade;
  static const Color neutral    = inkLight;
  static const Color tertiary   = jadeDim;

  static const Color surfaceLight = Color(0xFFF0F4F8);   // Light theme bg
  static const Color surfaceDark  = inkMid;

  // ── Text ─────────────────────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFFE8EFF8);  // Off-white
  static const Color textSecondary = Color(0xFF7A8FA6);  // Muted slate
  static const Color textMuted     = Color(0xFF3D5269);  // Very dim

  // ── Status ───────────────────────────────────────────────────────────────
  static const Color success = jade;
  static const Color error   = crimson;
  static const Color warning = amber;

  // ── Borders ──────────────────────────────────────────────────────────────
  static const Color borderLight = Color(0xFF1E3148);   // Dark border
  static const Color borderDark  = Color(0xFF1E3148);

  // ── Light mode tokens (when toggled) ─────────────────────────────────────
  static const Color lightBg     = Color(0xFFF0F4F8);
  static const Color lightCard   = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFDDE4EE);
  static const Color lightText   = Color(0xFF0D1B2A);
  static const Color lightTextSub = Color(0xFF4A5F75);
}

class ThemeProvider with ChangeNotifier {
  bool _isDarkMode = true;   // Default to dark — the design is built for it
  bool _isLoaded   = false;
  Color _accentColor = AppTheme.jade;

  bool  get isDarkMode   => _isDarkMode;
  bool  get isLoaded     => _isLoaded;
  Color get accentColor  => _accentColor;

  ThemeProvider() { _loadTheme(); }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? true;
    final colorValue = prefs.getInt('accentColor');
    if (colorValue != null) _accentColor = Color(colorValue);
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> toggleTheme(bool value) async {
    _isDarkMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', value);
    notifyListeners();
  }

  Future<void> setAccentColor(Color color) async {
    _accentColor = color;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('accentColor', color.value);
    notifyListeners();
  }

  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  // ── Dark Theme — PRIMARY experience ──────────────────────────────────────
  ThemeData get darkTheme {
    final textTheme = GoogleFonts.syneTextTheme().copyWith(
      displayLarge: GoogleFonts.syne(
        fontSize: 32, fontWeight: FontWeight.w800, color: AppTheme.textPrimary,
        letterSpacing: -1.0,
      ),
      displayMedium: GoogleFonts.syne(
        fontSize: 24, fontWeight: FontWeight.w700, color: AppTheme.textPrimary,
        letterSpacing: -0.5,
      ),
      titleLarge: GoogleFonts.syne(
        fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary,
        letterSpacing: -0.3,
      ),
      titleMedium: GoogleFonts.syne(
        fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textPrimary,
      ),
      bodyLarge: GoogleFonts.jetBrainsMono(
        fontSize: 14, color: AppTheme.textPrimary, fontWeight: FontWeight.w400,
      ),
      bodyMedium: GoogleFonts.syne(
        fontSize: 13, color: AppTheme.textSecondary,
      ),
      labelSmall: GoogleFonts.jetBrainsMono(
        fontSize: 10, color: AppTheme.textMuted, letterSpacing: 1.2,
      ),
    );

    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      scaffoldBackgroundColor: AppTheme.ink,
      primaryColor: _accentColor,
      cardColor: AppTheme.inkMid,
      textTheme: textTheme,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      colorScheme: ColorScheme.dark(
        primary:      _accentColor,
        secondary:    _accentColor,
        tertiary:     AppTheme.amber,
        surface:      AppTheme.inkMid,
        onPrimary:    AppTheme.ink,
        onSecondary:  AppTheme.ink,
        onSurface:    AppTheme.textPrimary,
        outline:      AppTheme.borderLight,
        error:        AppTheme.crimson,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppTheme.ink,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: GoogleFonts.syne(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppTheme.textPrimary,
          letterSpacing: -0.2,
        ),
      ),
      dividerColor: AppTheme.borderLight,
      dividerTheme: const DividerThemeData(
        color: AppTheme.borderLight,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppTheme.inkMid,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppTheme.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppTheme.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: _accentColor, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: GoogleFonts.jetBrainsMono(
          color: AppTheme.textMuted, fontSize: 13,
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeSlidePageTransitionsBuilder(),
          TargetPlatform.iOS:     FadeSlidePageTransitionsBuilder(),
          TargetPlatform.windows: FadeSlidePageTransitionsBuilder(),
        },
      ),
    );
  }

  // ── Light Theme ───────────────────────────────────────────────────────────
  ThemeData get lightTheme {
    final textTheme = GoogleFonts.syneTextTheme().copyWith(
      displayLarge: GoogleFonts.syne(
        fontSize: 32, fontWeight: FontWeight.w800, color: AppTheme.lightText,
        letterSpacing: -1.0,
      ),
      titleLarge: GoogleFonts.syne(
        fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.lightText,
      ),
      bodyMedium: GoogleFonts.syne(
        fontSize: 13, color: AppTheme.lightTextSub,
      ),
      labelSmall: GoogleFonts.jetBrainsMono(
        fontSize: 10, color: AppTheme.lightTextSub, letterSpacing: 1.2,
      ),
    );

    return ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      scaffoldBackgroundColor: AppTheme.lightBg,
      primaryColor: const Color(0xFF006B4A),   // Dark jade for light mode
      cardColor: AppTheme.lightCard,
      textTheme: textTheme,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      colorScheme: ColorScheme.light(
        primary:      _accentColor == AppTheme.jade ? const Color(0xFF006B4A) : _accentColor,
        secondary:    _accentColor == AppTheme.jade ? const Color(0xFF006B4A) : _accentColor,
        tertiary:     const Color(0xFF006B4A),
        surface:      AppTheme.lightCard,
        onPrimary:    Colors.white,
        onSecondary:  Colors.white,
        onSurface:    AppTheme.lightText,
        outline:      AppTheme.lightBorder,
        error:        AppTheme.crimson,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppTheme.lightBg,
        foregroundColor: AppTheme.lightText,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: GoogleFonts.syne(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppTheme.lightText,
          letterSpacing: -0.2,
        ),
      ),
      dividerColor: AppTheme.lightBorder,
      dividerTheme: const DividerThemeData(
        color: AppTheme.lightBorder,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppTheme.lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppTheme.lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF006B4A), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeSlidePageTransitionsBuilder(),
          TargetPlatform.iOS:     FadeSlidePageTransitionsBuilder(),
          TargetPlatform.windows: FadeSlidePageTransitionsBuilder(),
        },
      ),
    );
  }
}
