import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// ════════════════════════════════════════════════════════════════════════════
//  AUTH PROVIDER  — Real backend integration
//  Connects to POST /api/auth/login, /api/auth/register, /api/auth/change-password
// ════════════════════════════════════════════════════════════════════════════

class AuthProvider with ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  String? _userId;
  String? _userEmail;
  String? _userName;
  String? _userPhone;
  String? _token;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get userId => _userId;
  String? get userEmail => _userEmail;
  String? get userName => _userName;
  String? get userPhone => _userPhone;
  String? get token => _token;
  bool get isLoggedIn => _token != null && _token!.isNotEmpty;

  static final String _baseUrl = dotenv.get('BACKEND_URL', fallback: 'https://clgpro.onrender.com');
  static const Duration _timeout = Duration(seconds: 90);

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  // ── Email format check ──────────────────────────────────────────────────
  bool _isValidEmail(String email) {
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email);
  }

  // ── Login ───────────────────────────────────────────────────────────────
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _clearError();

    // Client-side validation first
    if (email.trim().isEmpty) {
      _errorMessage = 'Please enter your email address.';
      _setLoading(false);
      return false;
    }
    if (!_isValidEmail(email.trim())) {
      _errorMessage = 'Please enter a valid email address.';
      _setLoading(false);
      return false;
    }
    if (password.isEmpty) {
      _errorMessage = 'Please enter your password.';
      _setLoading(false);
      return false;
    }
    if (password.length < 6) {
      _errorMessage = 'Password must be at least 6 characters.';
      _setLoading(false);
      return false;
    }

    try {
      final res = await http
          .post(
            Uri.parse('$_baseUrl/api/auth/login'),
            headers: {'Content-Type': 'application/json', 'ngrok-skip-browser-warning': 'true'},
            body: jsonEncode({'email': email.trim(), 'password': password}),
          )
          .timeout(_timeout);

      final body = jsonDecode(res.body) as Map<String, dynamic>;

      if (res.statusCode == 200 && body['success'] == true) {
        final tok  = body['token'] as String;
        final user = body['user'] as Map<String, dynamic>;

        _token     = tok;
        _userId    = user['id'] as String?;
        _userEmail = user['email'] as String?;
        _userName  = user['name'] as String?;
        _userPhone = user['phone'] as String? ?? '';

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', tok);
        await prefs.setString('user_id',    _userId    ?? '');
        await prefs.setString('user_email', _userEmail ?? '');
        await prefs.setString('user_name',  _userName  ?? '');
        await prefs.setString('user_phone', _userPhone ?? '');

        _setLoading(false);
        return true;
      } else {
        _errorMessage = body['error'] as String? ?? 'Login failed. Please try again.';
        _setLoading(false);
        return false;
      }
    } on http.ClientException catch (e) {
      _errorMessage = 'Network error: ${e.message}';
      _setLoading(false);
      return false;
    } catch (e) {
      _errorMessage = 'Unable to connect to server. Please check your internet connection.';
      _setLoading(false);
      return false;
    }
  }

  // ── Signup ──────────────────────────────────────────────────────────────
  Future<bool> signup(String name, String email, String password) async {
    _setLoading(true);
    _clearError();

    // Client-side validation
    if (name.trim().isEmpty) {
      _errorMessage = 'Please enter your full name.';
      _setLoading(false);
      return false;
    }
    if (email.trim().isEmpty || !_isValidEmail(email.trim())) {
      _errorMessage = 'Please enter a valid email address.';
      _setLoading(false);
      return false;
    }
    if (password.length < 6) {
      _errorMessage = 'Password must be at least 6 characters.';
      _setLoading(false);
      return false;
    }

    try {
      final res = await http
          .post(
            Uri.parse('$_baseUrl/api/auth/register'),
            headers: {'Content-Type': 'application/json', 'ngrok-skip-browser-warning': 'true'},
            body: jsonEncode({
              'name':     name.trim(),
              'email':    email.trim(),
              'password': password,
            }),
          )
          .timeout(_timeout);

      final body = jsonDecode(res.body) as Map<String, dynamic>;

      if ((res.statusCode == 200 || res.statusCode == 201) && body['success'] == true) {
        // Auto-login on register
        final tok  = body['token'] as String;
        final user = body['user'] as Map<String, dynamic>;

        _token     = tok;
        _userId    = user['id'] as String?;
        _userEmail = user['email'] as String?;
        _userName  = user['name'] as String?;
        _userPhone = '';

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', tok);
        await prefs.setString('user_id',    _userId    ?? '');
        await prefs.setString('user_email', _userEmail ?? '');
        await prefs.setString('user_name',  _userName  ?? '');
        await prefs.setString('user_phone', '');

        _setLoading(false);
        return true;
      } else {
        _errorMessage = body['error'] as String? ?? 'Registration failed. Please try again.';
        _setLoading(false);
        return false;
      }
    } on http.ClientException catch (e) {
      _errorMessage = 'Network error: ${e.message}';
      _setLoading(false);
      return false;
    } catch (e) {
      _errorMessage = 'Unable to connect to server. Please check your internet connection.';
      _setLoading(false);
      return false;
    }
  }

  // ── Change password (calls backend) ────────────────────────────────────
  Future<String?> changePassword(
      String currentPassword, String newPassword, String confirmPassword) async {
    if (newPassword != confirmPassword) {
      return 'New passwords do not match.';
    }
    if (newPassword.length < 6) {
      return 'New password must be at least 6 characters.';
    }
    if (currentPassword.isEmpty) {
      return 'Please enter your current password.';
    }

    _setLoading(true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final tok   = prefs.getString('auth_token') ?? _token ?? '';

      final res = await http
          .post(
            Uri.parse('$_baseUrl/api/auth/change-password'),
            headers: {
              'Content-Type': 'application/json', 'ngrok-skip-browser-warning': 'true',
              'Authorization': 'Bearer $tok',
            },
            body: jsonEncode({
              'currentPassword': currentPassword,
              'newPassword':     newPassword,
            }),
          )
          .timeout(_timeout);

      final body = jsonDecode(res.body) as Map<String, dynamic>;
      _setLoading(false);

      if (res.statusCode == 200 && body['success'] == true) {
        return null; // success
      }
      return body['error'] as String? ?? 'Failed to change password.';
    } catch (e) {
      _setLoading(false);
      return 'Unable to connect to server. Please try again.';
    }
  }

  // ── Reset password (email-based — shows info message) ──────────────────
  Future<bool> resetPassword(String email) async {
    _setLoading(true);
    _clearError();
    if (email.trim().isEmpty || !_isValidEmail(email.trim())) {
      _errorMessage = 'Please enter a valid email address.';
      _setLoading(false);
      return false;
    }
    await Future.delayed(const Duration(milliseconds: 800));
    _setLoading(false);
    return true;
  }

  // ── Logout ──────────────────────────────────────────────────────────────
  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tok = prefs.getString('auth_token') ?? _token ?? '';
      if (tok.isNotEmpty) {
        await http
            .post(
              Uri.parse('$_baseUrl/api/auth/logout'),
              headers: {
                'Content-Type':  'application/json',
                'Authorization': 'Bearer $tok',
              },
            )
            .timeout(const Duration(seconds: 10));
      }
    } catch (_) {}

    _token     = null;
    _userId    = null;
    _userEmail = null;
    _userName  = null;
    _userPhone = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_id');
    await prefs.remove('user_email');
    await prefs.remove('user_name');
    await prefs.remove('user_phone');
    notifyListeners();
  }

  // ── Restore session from SharedPreferences ──────────────────────────────
  Future<bool> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final tok   = prefs.getString('auth_token');
    if (tok == null || tok.isEmpty) return false;

    // Check if token is expired
    try {
      final parts = tok.split('.');
      if (parts.length != 3) {
        await logout();
        return false;
      }
      
      final payloadStr = parts[1];
      final normalized = base64Url.normalize(payloadStr);
      final payloadMap = jsonDecode(utf8.decode(base64Url.decode(normalized)));
      
      if (payloadMap is Map<String, dynamic> && payloadMap.containsKey('exp')) {
        final exp = payloadMap['exp'] as int;
        final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        if (now >= exp) {
          // Token expired
          await logout();
          return false;
        }
      }
    } catch (_) {
      // If parsing fails, assume invalid token
      await logout();
      return false;
    }

    _token     = tok;
    _userId    = prefs.getString('user_id');
    _userEmail = prefs.getString('user_email');
    _userName  = prefs.getString('user_name');
    _userPhone = prefs.getString('user_phone') ?? '';
    notifyListeners();
    return true;
  }
}
