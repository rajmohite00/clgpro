import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/animations.dart';

// ─── Design Tokens ────────────────────────────────────────────────────────────
class AppTheme {
  // Primary palette
  static const Color primary = Color(0xFF0F172A);      // Dark Navy
  static const Color secondary = Color(0xFF3B82F6);    // Blue
  static const Color tertiary = Color(0xFF231500);     // Dark Brown
  static const Color neutral = Color(0xFFF8FAFC);      // Near-White BG

  // Secondary blue shades
  static const Color blueLight = Color(0xFFEFF6FF);
  static const Color blueMid = Color(0xFFBFDBFE);
  static const Color blueDark = Color(0xFF1D4ED8);

  // Surface / card
  static const Color surfaceLight = Colors.white;
  static const Color surfaceDark = Color(0xFF1E293B);

  // Text
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textMuted = Color(0xFF94A3B8);

  // Status
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);

  // Border
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color borderDark = Color(0xFF334155);
}

class ThemeProvider with ChangeNotifier {
  bool _isDarkMode = false;
  bool _isLoaded = false;

  bool get isDarkMode => _isDarkMode;
  bool get isLoaded => _isLoaded;

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> toggleTheme(bool value) async {
    _isDarkMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', value);
    notifyListeners();
  }

  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppTheme.neutral,
      primaryColor: AppTheme.secondary,
      cardColor: AppTheme.surfaceLight,
      colorScheme: const ColorScheme.light(
        primary: AppTheme.secondary,
        secondary: AppTheme.secondary,
        tertiary: AppTheme.tertiary,
        background: AppTheme.neutral,
        surface: AppTheme.surfaceLight,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppTheme.textPrimary,
        onBackground: AppTheme.textPrimary,
        outline: AppTheme.borderLight,
        error: AppTheme.error,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      dividerColor: AppTheme.borderLight,
      useMaterial3: true,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeSlidePageTransitionsBuilder(),
          TargetPlatform.iOS: FadeSlidePageTransitionsBuilder(),
        },
      ),
    );
  }

  ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppTheme.primary,
      primaryColor: AppTheme.secondary,
      cardColor: AppTheme.surfaceDark,
      colorScheme: const ColorScheme.dark(
        primary: AppTheme.secondary,
        secondary: AppTheme.secondary,
        tertiary: Color(0xFF60A5FA),
        background: AppTheme.primary,
        surface: AppTheme.surfaceDark,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.white,
        onBackground: Colors.white,
        outline: AppTheme.borderDark,
        error: AppTheme.error,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      dividerColor: AppTheme.borderDark,
      useMaterial3: true,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeSlidePageTransitionsBuilder(),
          TargetPlatform.iOS: FadeSlidePageTransitionsBuilder(),
        },
      ),
    );
  }
}
