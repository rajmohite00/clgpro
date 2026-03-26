import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProvider with ChangeNotifier {
  String _name = 'Raj';
  String _email = 'raj@example.com';
  String? _profilePicPath;
  bool _isLoading = false;

  String get name => _name;
  String get email => _email;
  String? get profilePicPath => _profilePicPath;
  bool get isLoading => _isLoading;

  Future<void> fetchProfile() async {
    _isLoading = true;
    notifyListeners();
    // API mock: /get-profile
    await Future.delayed(const Duration(seconds: 1));
    final prefs = await SharedPreferences.getInstance();
    _profilePicPath = prefs.getString('profile_pic_path');
    _isLoading = false;
    notifyListeners();
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
