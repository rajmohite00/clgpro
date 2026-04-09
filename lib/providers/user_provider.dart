import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProvider with ChangeNotifier {
  String _name = 'Raj';
  String _email = 'raj@example.com';
  String? _profilePicPath;
  bool _isLoading = false;
  int _totalScans = 0;
  int _verifiedCount = 0;
  int _streakDays = 0;
  bool _hasRated = false;
  bool _hasPromptedRating = false;

  String get name => _name;
  String get email => _email;
  String? get profilePicPath => _profilePicPath;
  bool get isLoading => _isLoading;
  int get totalScans => _totalScans;
  int get verifiedCount => _verifiedCount;
  int get streakDays => _streakDays;
  bool get hasRated => _hasRated;
  bool get hasPromptedRating => _hasPromptedRating;

  /// Whether to show rating prompt (after 3+ scans, not yet rated/dismissed)
  bool get shouldShowRatingPrompt =>
      _totalScans >= 3 && !_hasRated && !_hasPromptedRating;

  Future<void> fetchProfile() async {
    _isLoading = true;
    notifyListeners();
    // API mock: /get-profile
    await Future.delayed(const Duration(seconds: 1));
    final prefs = await SharedPreferences.getInstance();
    _profilePicPath = prefs.getString('profile_pic_path');
    _totalScans = prefs.getInt('total_scans') ?? 0;
    _verifiedCount = prefs.getInt('verified_count') ?? 0;
    _streakDays = prefs.getInt('streak_days') ?? 0;
    _hasRated = prefs.getBool('has_rated') ?? false;
    _hasPromptedRating = prefs.getBool('has_prompted_rating') ?? false;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> incrementScanCount({required bool isVerified}) async {
    _totalScans++;
    if (isVerified) _verifiedCount++;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('total_scans', _totalScans);
    await prefs.setInt('verified_count', _verifiedCount);

    // Track streak
    await _updateStreak(prefs);
  }

  Future<void> _updateStreak(SharedPreferences prefs) async {
    final lastScanDateStr = prefs.getString('last_scan_date');
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month}-${today.day}';

    if (lastScanDateStr == null) {
      _streakDays = 1;
    } else if (lastScanDateStr == todayStr) {
      // Already scanned today, streak unchanged
    } else {
      final lastDate = DateTime.tryParse(lastScanDateStr);
      if (lastDate != null) {
        final diff = today.difference(lastDate).inDays;
        if (diff == 1) {
          _streakDays++;
        } else {
          _streakDays = 1; // Reset streak
        }
      } else {
        _streakDays = 1;
      }
    }

    await prefs.setString('last_scan_date', todayStr);
    await prefs.setInt('streak_days', _streakDays);
    notifyListeners();
  }

  Future<void> markRatingPrompted() async {
    _hasPromptedRating = true;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_prompted_rating', true);
  }

  Future<void> markRated() async {
    _hasRated = true;
    _hasPromptedRating = true;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_rated', true);
    await prefs.setBool('has_prompted_rating', true);
  }

  Future<bool> updateProfile(String newName, String newEmail) async {
    _isLoading = true;
    notifyListeners();
    try {
      // API mock: /update-profile
      await Future.delayed(const Duration(seconds: 2));
      _name = newName;
      _email = newEmail;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> updateProfilePic(String path) async {
    _profilePicPath = path;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_pic_path', path);
  }

  Future<String?> changePassword(String current, String newPass, String confirmPass) async {
    if (newPass != confirmPass) {
      return "New passwords do not match";
    }
    
    _isLoading = true;
    notifyListeners();
    try {
      // API mock: /change-password
      await Future.delayed(const Duration(seconds: 2));
      _isLoading = false;
      notifyListeners();
      return null; // Return null on success
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return 'Failed to change password. Please try again.';
    }
  }
}
