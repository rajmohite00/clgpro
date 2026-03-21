import 'package:flutter/material.dart';

class UserProvider with ChangeNotifier {
  String _name = 'Raj';
  String _email = 'raj@example.com';
  bool _isLoading = false;

  String get name => _name;
  String get email => _email;
  bool get isLoading => _isLoading;

  Future<void> fetchProfile() async {
    _isLoading = true;
    notifyListeners();
    // API mock: /get-profile
    await Future.delayed(const Duration(seconds: 1));
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
