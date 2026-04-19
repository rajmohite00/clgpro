import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// ════════════════════════════════════════════════════════════════════════════
//  USER PROVIDER  — User-account-scoped data
//  All SharedPreferences keys are prefixed with the userId so multiple
//  accounts on the same device stay completely isolated.
// ════════════════════════════════════════════════════════════════════════════

class UserProvider with ChangeNotifier {
  String _name    = '';
  String _email   = '';
  String _phone   = '';
  String? _profilePicPath;
  bool   _isLoading = false;

  // Stats — per user
  int  _totalScans    = 0;
  int  _verifiedCount = 0;
  int  _streakDays    = 0;

  // Rating gate
  bool _hasRated          = false;
  bool _hasPromptedRating = false;

  // ── Getters ──────────────────────────────────────────────────────────────
  String  get name            => _name;
  String  get email           => _email;
  String  get phone           => _phone;
  String? get profilePicPath  => _profilePicPath;
  bool    get isLoading       => _isLoading;
  int     get totalScans      => _totalScans;
  int     get verifiedCount   => _verifiedCount;
  int     get streakDays      => _streakDays;
  bool    get hasRated        => _hasRated;
  bool    get hasPromptedRating => _hasPromptedRating;

  bool get shouldShowRatingPrompt =>
      _totalScans >= 3 && !_hasRated && !_hasPromptedRating;

  static const String _baseUrl = 'https://satya-agent-main.onrender.com';

  // ── Key helper — every pref is scoped to userId ────────────────────────
  Future<String> _uid(SharedPreferences prefs) async {
    return prefs.getString('user_id') ?? 'guest';
  }

  String _k(String uid, String key) => 'user_${uid}_$key';

  // ── Load profile from SharedPreferences (and optionally backend) ───────
  Future<void> fetchProfile() async {
    _isLoading = true;
    notifyListeners();

    final prefs  = await SharedPreferences.getInstance();
    final uid    = await _uid(prefs);

    // Load persisted fields
    _name            = prefs.getString(_k(uid, 'name'))    ?? prefs.getString('user_name') ?? 'User';
    _email           = prefs.getString(_k(uid, 'email'))   ?? prefs.getString('user_email') ?? '';
    _phone           = prefs.getString(_k(uid, 'phone'))   ?? prefs.getString('user_phone') ?? '';
    _profilePicPath  = prefs.getString(_k(uid, 'pic'));
    _totalScans      = prefs.getInt(_k(uid, 'total_scans'))    ?? 0;
    _verifiedCount   = prefs.getInt(_k(uid, 'verified_count')) ?? 0;
    _streakDays      = prefs.getInt(_k(uid, 'streak_days'))    ?? 0;
    _hasRated             = prefs.getBool(_k(uid, 'has_rated'))          ?? false;
    _hasPromptedRating    = prefs.getBool(_k(uid, 'has_prompted_rating')) ?? false;

    // Try to sync profile from backend (non-blocking, silently fails)
    _syncProfileFromBackend(prefs, uid);

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _syncProfileFromBackend(SharedPreferences prefs, String uid) async {
    try {
      final token = prefs.getString('auth_token') ?? '';
      if (token.isEmpty) return;

      final res = await http
          .get(
            Uri.parse('$_baseUrl/api/auth/profile'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        _name  = data['name']  as String? ?? _name;
        _email = data['email'] as String? ?? _email;
        _phone = data['phone'] as String? ?? _phone;

        await prefs.setString(_k(uid, 'name'),  _name);
        await prefs.setString(_k(uid, 'email'), _email);
        await prefs.setString(_k(uid, 'phone'), _phone);
        notifyListeners();
      }
    } catch (_) {
      // Silent fail — offline-first approach
    }
  }

  // ── Update profile (local + backend) ────────────────────────────────────
  Future<bool> updateProfile(String newName, String newEmail, {String newPhone = ''}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final uid   = await _uid(prefs);
      final token = prefs.getString('auth_token') ?? '';

      // Try backend
      if (token.isNotEmpty) {
        final res = await http
            .put(
              Uri.parse('$_baseUrl/api/auth/profile'),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $token',
              },
              body: jsonEncode({'name': newName, 'phone': newPhone}),
            )
            .timeout(const Duration(seconds: 15));
        if (res.statusCode != 200) {
          final body = jsonDecode(res.body) as Map<String, dynamic>;
          _isLoading = false;
          notifyListeners();
          return false;
        }
      }

      // Always save locally (works offline too)
      _name  = newName;
      _email = newEmail;
      _phone = newPhone;

      await prefs.setString(_k(uid, 'name'),  newName);
      await prefs.setString(_k(uid, 'email'), newEmail);
      await prefs.setString(_k(uid, 'phone'), newPhone);
      // Also update top-level keys used by auth restore
      await prefs.setString('user_name',  newName);
      await prefs.setString('user_email', newEmail);
      await prefs.setString('user_phone', newPhone);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ── Profile picture ──────────────────────────────────────────────────────
  Future<void> updateProfilePic(String path) async {
    _profilePicPath = path;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final uid   = await _uid(prefs);
    await prefs.setString(_k(uid, 'pic'), path);
  }

  // ── Scan counter + streak ────────────────────────────────────────────────
  Future<void> incrementScanCount({required bool isVerified}) async {
    _totalScans++;
    if (isVerified) _verifiedCount++;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final uid   = await _uid(prefs);
    await prefs.setInt(_k(uid, 'total_scans'),    _totalScans);
    await prefs.setInt(_k(uid, 'verified_count'), _verifiedCount);
    await _updateStreak(prefs, uid);
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  STREAK LOGIC
  //  • Same day        → no change
  //  • Next day        → streak + 1
  //  • Skipped ≥1 day  → reset to 1
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _updateStreak(SharedPreferences prefs, String uid) async {
    final lastScanDateStr = prefs.getString(_k(uid, 'last_scan_date'));
    final now             = DateTime.now();
    final todayStr        = '${now.year}-${_pad(now.month)}-${_pad(now.day)}';

    if (lastScanDateStr == null) {
      // First ever scan
      _streakDays = 1;
    } else if (lastScanDateStr == todayStr) {
      // Already scanned today — streak unchanged
      // Still attempt to sync in background if backend had a different day recorded
    } else {
      final lastDate = DateTime.tryParse(lastScanDateStr);
      if (lastDate != null) {
        // Compare only calendar dates (ignore time)
        final lastDay  = DateTime(lastDate.year, lastDate.month, lastDate.day);
        final today    = DateTime(now.year, now.month, now.day);
        final diffDays = today.difference(lastDay).inDays;

        if (diffDays == 1) {
          _streakDays++; // Consecutive day
        } else {
          _streakDays = 1; // Streak broken
        }
      } else {
        _streakDays = 1;
      }
    }

    await prefs.setString(_k(uid, 'last_scan_date'), todayStr);
    await prefs.setInt(_k(uid, 'streak_days'), _streakDays);
    notifyListeners();

    // Sync with MongoDB Backend
    final token = prefs.getString('auth_token') ?? '';
    if (token.isNotEmpty) {
      try {
        final res = await http.post(
          Uri.parse('$_baseUrl/api/auth/sync-streak'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ).timeout(const Duration(seconds: 15));
        
        if (res.statusCode == 200) {
          final body = jsonDecode(res.body) as Map<String, dynamic>;
          if (body['success'] == true) {
            _streakDays = body['streakDays'] ?? _streakDays;
            await prefs.setInt(_k(uid, 'streak_days'), _streakDays);
            notifyListeners();
          }
        }
      } catch (_) {
        // Silently fail if network is down
      }
    }
  }

  String _pad(int n) => n.toString().padLeft(2, '0');

  // ── Rating ───────────────────────────────────────────────────────────────
  Future<void> markRatingPrompted() async {
    _hasPromptedRating = true;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    final uid   = await _uid(prefs);
    await prefs.setBool(_k(uid, 'has_prompted_rating'), true);
  }

  Future<void> markRated() async {
    _hasRated          = true;
    _hasPromptedRating = true;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    final uid   = await _uid(prefs);
    await prefs.setBool(_k(uid, 'has_rated'),           true);
    await prefs.setBool(_k(uid, 'has_prompted_rating'), true);
  }

  // ── Change password (delegates to AuthProvider-like call) ───────────────
  // Also exposed here so screens with userProvider can call it directly.
  Future<String?> changePassword(
      String current, String newPass, String confirmPass) async {
    if (newPass != confirmPass) return 'New passwords do not match.';
    if (newPass.length < 6)    return 'New password must be at least 6 characters.';
    if (current.isEmpty)       return 'Please enter your current password.';

    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';

      final res = await http
          .post(
            Uri.parse('$_baseUrl/api/auth/change-password'),
            headers: {
              'Content-Type':  'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'currentPassword': current,
              'newPassword':     newPass,
            }),
          )
          .timeout(const Duration(seconds: 15));

      final body = jsonDecode(res.body) as Map<String, dynamic>;
      _isLoading = false;
      notifyListeners();

      if (res.statusCode == 200 && body['success'] == true) return null;
      return body['error'] as String? ?? 'Failed to change password.';
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return 'Unable to connect. Please check your internet connection.';
    }
  }

  // ── Reset all user data (called on logout) ───────────────────────────────
  void clearUserData() {
    _name            = '';
    _email           = '';
    _phone           = '';
    _profilePicPath  = null;
    _totalScans      = 0;
    _verifiedCount   = 0;
    _streakDays      = 0;
    _hasRated        = false;
    _hasPromptedRating = false;
    notifyListeners();
  }
}
