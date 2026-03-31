import 'package:flutter/material.dart';
import 'package:werent/models/vehicle_model.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class VehicleController extends ChangeNotifier {
  List<Vehicle> _vehicles = [];
  bool _isLoading = false;
  String? _error;

  List<Vehicle> get vehicles => _vehicles;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // MongoDB Backend URL
  static const String baseUrl = "http://127.0.0.1:8000/api";

  // Get all vehicles for an owner
  Future<List<Vehicle>> getOwnerVehicles(String ownerId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/vehicles/?owner_id=$ownerId'),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _vehicles = data.map((json) => Vehicle.fromJson(json)).toList();
        return _vehicles;
      } else {
        final errorData = jsonDecode(response.body);
        _error = errorData['error'] ?? 'Failed to fetch vehicles';
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

  // Add a new vehicle
  Future<Vehicle?> addVehicle({
    required String ownerId,
    required VehicleCategory category,
    required String name,
    required String brand,
    required int modelYear,
    required double pricePerDay,
    required FuelType fuelType,
    required Transmission transmission,
    required String pickupLocation,
    String? imageBase64,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final vehicle = Vehicle(
        id: '',
        ownerId: ownerId,
        category: category,
        name: name,
        brand: brand,
        modelYear: modelYear,
        pricePerDay: pricePerDay,
        fuelType: fuelType,
        transmission: transmission,
        pickupLocation: pickupLocation,
        createdAt: DateTime.now(),
        imageBase64: imageBase64,
      );

      final response = await http.post(
        Uri.parse('$baseUrl/vehicles/'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(vehicle.toJson()),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final newVehicle = Vehicle.fromJson(data);
        _vehicles.add(newVehicle);
        notifyListeners();
        return newVehicle;
      } else {
        final errorData = jsonDecode(response.body);
        _error = errorData['error'] ?? 'Failed to add vehicle';
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

  // Update a vehicle
  Future<bool> updateVehicle(Vehicle vehicle) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.put(
        Uri.parse('$baseUrl/vehicles/${vehicle.id}/'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(vehicle.toJson()),
      );

      if (response.statusCode == 200) {
        final index = _vehicles.indexWhere((v) => v.id == vehicle.id);
        if (index != -1) {
          _vehicles[index] = Vehicle.fromJson(jsonDecode(response.body));
        }
        notifyListeners();
        return true;
      } else {
        final errorData = jsonDecode(response.body);
        _error = errorData['error'] ?? 'Failed to update vehicle';
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

  // Delete a vehicle
  Future<bool> deleteVehicle(String vehicleId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/vehicles/$vehicleId/'),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        _vehicles.removeWhere((v) => v.id == vehicleId);
        notifyListeners();
        return true;
      } else {
        final errorData = jsonDecode(response.body);
        _error = errorData['error'] ?? 'Failed to delete vehicle';
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

  // Toggle vehicle availability
  Future<bool> toggleAvailability(String vehicleId) async {
    final index = _vehicles.indexWhere((v) => v.id == vehicleId);
    if (index != -1) {
      final vehicle = _vehicles[index];
      final updatedVehicle = Vehicle(
        id: vehicle.id,
        ownerId: vehicle.ownerId,
        category: vehicle.category,
        name: vehicle.name,
        brand: vehicle.brand,
        modelYear: vehicle.modelYear,
        pricePerDay: vehicle.pricePerDay,
        fuelType: vehicle.fuelType,
        transmission: vehicle.transmission,
        pickupLocation: vehicle.pickupLocation,
        isAvailable: !vehicle.isAvailable,
        createdAt: vehicle.createdAt,
        imageBase64: vehicle.imageBase64,
      );
      return await updateVehicle(updatedVehicle);
    }
    return false;
  }
}
