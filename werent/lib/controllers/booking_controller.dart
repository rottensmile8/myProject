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

  // Get all bookings for a renter
  Future<List<Booking>> getRenterBookings(String renterId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/bookings/?renter_id=$renterId'),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final renterBookings =
            data.map((json) => Booking.fromJson(json)).toList();
        return renterBookings;
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

  // Check if renter has active rental
  Future<bool> hasActiveRental(String renterId) async {
    try {
      final bookings = await getRenterBookings(renterId);
      return bookings.any((b) => b.status == 'confirmed');
    } catch (e) {
      print('Error checking active rental: $e');
      return false;
    }
  }

  // Create a new booking
  Future<Booking?> createBooking({
    required String vehicleId,
    required String vehicleName,
    required String vehicleCategory,
    required String renterId,
    required String renterName,
    required String renterEmail,
    required DateTime startDate,
    required DateTime endDate,
    required double totalPrice,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/bookings/'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          'vehicleId': vehicleId,
          'vehicleName': vehicleName,
          'vehicleCategory': vehicleCategory,
          'renterId': renterId,
          'renterName': renterName,
          'renterEmail': renterEmail,
          'startDate': startDate.toIso8601String(),
          'endDate': endDate.toIso8601String(),
          'totalPrice': totalPrice,
          'status': 'pending',
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final booking = Booking.fromJson(data);
        _bookings.add(booking);
        notifyListeners();
        return booking;
      } else {
        final errorData = jsonDecode(response.body);
        _error = errorData['error'] ?? 'Failed to create booking';
        throw Exception(_error);
      }
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update booking status
  Future<bool> updateBookingStatus(String bookingId, String status,
      {double? refundAmount}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final body = <String, dynamic>{'status': status};
      if (refundAmount != null) {
        body['refundAmount'] = refundAmount;
      }
      final response = await http.put(
        Uri.parse('$baseUrl/bookings/$bookingId/'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
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

  // Delete a booking
  Future<bool> deleteBooking(String bookingId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/bookings/$bookingId/'),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        _bookings.removeWhere((b) => b.id == bookingId);
        notifyListeners();
        return true;
      } else {
        final errorData = jsonDecode(response.body);
        _error = errorData['error'] ?? 'Failed to delete booking';
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
