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
        final errorMessage =
            errorData['error'] ?? errorData['message'] ?? 'Signup failed';
        throw Exception(_getUserFriendlyErrorMessage(errorMessage, 'signup'));
      }
    } on Exception catch (e) {
      // Re-throw with user-friendly message
      throw Exception(_getUserFriendlyErrorMessage(e.toString(), 'signup'));
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
            'Role mismatch: You are trying to login as ${expectedRole.name} but your account is registered as ${data["role"]}. Please select the correct role.',
          );
        }

        _currentUser = User.fromJson(data);
        return _currentUser;
      } else {
        final errorData = jsonDecode(response.body);
        final errorMessage =
            errorData['error'] ?? errorData['message'] ?? 'Login failed';
        throw Exception(_getUserFriendlyErrorMessage(errorMessage, 'login'));
      }
    } on Exception catch (e) {
      // Re-throw with user-friendly message
      throw Exception(_getUserFriendlyErrorMessage(e.toString(), 'login'));
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Convert technical errors to user-friendly messages
  String _getUserFriendlyErrorMessage(String error, String context) {
    final lowerError = error.toLowerCase();

    // Network/Socket errors
    if (lowerError.contains('socketexception') ||
        lowerError.contains('connection refused') ||
        lowerError.contains('network is unreachable') ||
        lowerError.contains('failed host identification')) {
      return 'Cannot connect to server. Please ensure:\n'
          '1. MongoDB is running (check MongoDB Compass)\n'
          '2. Django server is running (python manage.py runserver)\n'
          '3. You have an active internet connection';
    }

    // User already exists
    if (lowerError.contains('user already exists') ||
        lowerError.contains('duplicate key')) {
      return 'An account with this email already exists. Please login or use a different email.';
    }

    // User not found
    if (lowerError.contains('user not found') ||
        lowerError.contains('no such document')) {
      return 'No account found with this email. Please signup first.';
    }

    // Invalid credentials
    if (lowerError.contains('invalid credentials') ||
        lowerError.contains('wrong password') ||
        lowerError.contains('password mismatch')) {
      return 'Incorrect password. Please try again.';
    }

    // Password validation
    if (lowerError.contains('password') && lowerError.contains('required')) {
      return 'Password is required.';
    }

    // Email validation
    if (lowerError.contains('email') && lowerError.contains('required')) {
      return 'Email is required.';
    }

    // All fields required
    if (lowerError.contains('all fields are required')) {
      return 'Please fill in all required fields.';
    }

    // Role mismatch
    if (lowerError.contains('role mismatch')) {
      return error; // Keep the detailed role mismatch message
    }

    // Default - return original error
    return error;
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

  // Helper method to set user directly
  void setUser(User user) {
    _currentUser = user;
    notifyListeners();
  }

  // Helper method to determine initial route
  String getInitialRoute() {
    if (_currentUser == null) return '/auth';
    return _currentUser!.role == UserRole.owner
        ? '/owner/dashboard'
        : '/renter/dashboard';
  }
}
