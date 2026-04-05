import 'package:flutter/material.dart';
import 'package:werent/models/notification_model.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class NotificationController extends ChangeNotifier {
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  String? _error;

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // MongoDB Backend URL
  static const String baseUrl = "http://127.0.0.1:8000/api";

  // Get all notifications for a user
  Future<List<NotificationModel>> getNotifications(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/notifications/?user_id=$userId'),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _notifications = data.map((json) => NotificationModel.fromJson(json)).toList();
        return _notifications;
      } else {
        final errorData = jsonDecode(response.body);
        _error = errorData['error'] ?? 'Failed to fetch notifications';
        throw Exception(_error);
      }
    } catch (e) {
      _error = e.toString();
      return [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Delete a specific notification
  Future<bool> deleteNotification(String notificationId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/notifications/?notification_id=$notificationId'),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        _notifications.removeWhere((n) => n.id == notificationId);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  // Clear all notifications for a user
  Future<bool> clearAllNotifications(String userId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/notifications/?user_id=$userId'),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        _notifications.clear();
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  int get unreadCount => _notifications.where((n) => !n.isRead).length;
}
