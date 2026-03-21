import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider with ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _clearError();
    try {
      // TODO: Replace with real API call
      // final response = await http.post(Uri.parse('https://your-api.com/login'), body: {'email': email, 'password': password});
      await Future.delayed(const Duration(seconds: 2));
      
      if (email.isNotEmpty && password.length >= 6) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', 'dummy_token_123');
        _setLoading(false);
        return true;
      } else {
        _errorMessage = 'Invalid email or password constraints';
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }

  Future<bool> signup(String name, String email, String password) async {
    _setLoading(true);
    _clearError();
    try {
      // TODO: Replace with real API call
      await Future.delayed(const Duration(seconds: 2));
      
      if (name.isNotEmpty && email.isNotEmpty && password.length >= 6) {
        _setLoading(false);
        return true;
      } else {
        _errorMessage = 'Please fill all fields correctly';
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }

  Future<bool> resetPassword(String email) async {
    _setLoading(true);
    _clearError();
    try {
      // TODO: Replace with real API call
      await Future.delayed(const Duration(seconds: 2));
      
      if (email.isNotEmpty) {
        _setLoading(false);
        return true;
      } else {
        _errorMessage = 'Please enter a valid email';
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }
}
