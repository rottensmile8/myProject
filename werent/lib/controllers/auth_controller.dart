import 'package:flutter/material.dart';
import 'package:werent/models/user_model.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthController extends ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;

  // MongoDB Backend URL
  static const String baseUrl = "http://127.0.0.1:8000/api";

  // Signup method
  Future<User?> signup({
    required String fullName,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/signup/'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "fullName": fullName,
          "email": email,
          "password": password,
          "role": role.name, // send "renter" or "owner"
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        _currentUser = User.fromJson(data);
        return _currentUser;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Signup failed');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Login method
  Future<User?> login({
    required String email,
    required String password,
    required UserRole expectedRole,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login/'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "password": password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['role'] != expectedRole.name) {
          throw Exception(
            'Role mismatch: Expected ${expectedRole.name} but got ${data['role']}',
          );
        }

        _currentUser = User.fromJson(data);
        return _currentUser;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(
          errorData['message'] ?? errorData['error'] ?? 'Login failed',
        );
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Logout method
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await Future.delayed(const Duration(seconds: 1));
      _currentUser = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Reset password method
  Future<void> resetPassword(String email) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/reset-password/'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email}),
      );

      if (response.statusCode != 200) {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Password reset failed');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Helper method to determine initial route
  String getInitialRoute() {
    if (_currentUser == null) return '/auth';
    return _currentUser!.role == UserRole.owner
        ? '/owner/dashboard'
        : '/renter/dashboard';
  }
}
