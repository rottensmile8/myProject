import 'package:flutter/material.dart';
import 'package:werent/models/booking_model.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class BookingController extends ChangeNotifier {
  List<Booking> _bookings = [];
  bool _isLoading = false;
  String? _error;

  List<Booking> get bookings => _bookings;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // MongoDB Backend URL
  static const String baseUrl = "http://127.0.0.1:8000/api";

  // Get all bookings for an owner (based on their vehicles)
  Future<List<Booking>> getOwnerBookings(String ownerId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/bookings/?owner_id=$ownerId'),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _bookings = data.map((json) => Booking.fromJson(json)).toList();
        return _bookings;
      } else {
        final errorData = jsonDecode(response.body);
        _error = errorData['error'] ?? 'Failed to fetch bookings';
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

  // Update booking status
  Future<bool> updateBookingStatus(String bookingId, String status) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.put(
        Uri.parse('$baseUrl/bookings/$bookingId/'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({'status': status}),
      );

      if (response.statusCode == 200) {
        final index = _bookings.indexWhere((b) => b.id == bookingId);
        if (index != -1) {
          _bookings[index] = Booking.fromJson(jsonDecode(response.body));
        }
        notifyListeners();
        return true;
      } else {
        final errorData = jsonDecode(response.body);
        _error = errorData['error'] ?? 'Failed to update booking';
        throw Exception(_error);
      }
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
