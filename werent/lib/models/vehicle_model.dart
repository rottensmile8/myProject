import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

enum VehicleCategory { car, bike }

enum FuelType { petrol, diesel, electric, hybrid }

enum Transmission { manual, automatic }

class Vehicle {
  final String id;
  final String ownerId;
  final VehicleCategory category;
  final String name;
  final String brand;
  final int modelYear;
  final double pricePerDay; // in NPR
  final FuelType fuelType;
  final Transmission transmission;
  final String pickupLocation;
  final bool isAvailable;
  final DateTime createdAt;
  final String? imageBase64; // optional vehicle photo
  final String? ownerName; // populated when fetching all vehicles

  Vehicle({
    required this.id,
    required this.ownerId,
    required this.category,
    required this.name,
    required this.brand,
    required this.modelYear,
    required this.pricePerDay,
    required this.fuelType,
    required this.transmission,
    required this.pickupLocation,
    this.isAvailable = true,
    required this.createdAt,
    this.imageBase64,
    this.ownerName,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['_id'] ?? '',
      ownerId: json['ownerId'] ?? '',
      category: json['category'] == 'bike'
          ? VehicleCategory.bike
          : VehicleCategory.car,
      name: json['name'] ?? '',
      brand: json['brand'] ?? '',
      modelYear: json['modelYear'] ?? 0,
      pricePerDay: (json['pricePerDay'] ?? 0).toDouble(),
      fuelType: _parseFuelType(json['fuelType']),
      transmission: _parseTransmission(json['transmission']),
      pickupLocation: json['pickupLocation'] ?? '',
      isAvailable: json['isAvailable'] ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      imageBase64: json['imageBase64'] as String?,
      ownerName: json['ownerName'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'ownerId': ownerId,
      'category': category == VehicleCategory.bike ? 'bike' : 'car',
      'name': name,
      'brand': brand,
      'modelYear': modelYear,
      'pricePerDay': pricePerDay,
      'fuelType': fuelType.name,
      'transmission': transmission.name,
      'pickupLocation': pickupLocation,
      'isAvailable': isAvailable,
    };
    if (imageBase64 != null) map['imageBase64'] = imageBase64;
    return map;
  }

  static FuelType _parseFuelType(String? fuelType) {
    switch (fuelType?.toLowerCase()) {
      case 'diesel':
        return FuelType.diesel;
      case 'electric':
        return FuelType.electric;
      case 'hybrid':
        return FuelType.hybrid;
      case 'petrol':
      default:
        return FuelType.petrol;
    }
  }

  static Transmission _parseTransmission(String? transmission) {
    switch (transmission?.toLowerCase()) {
      case 'automatic':
        return Transmission.automatic;
      case 'manual':
      default:
        return Transmission.manual;
    }
  }

  // Helper getters for display
  String get categoryDisplay =>
      category == VehicleCategory.bike ? 'Bike' : 'Car';

  String get fuelTypeDisplay {
    switch (fuelType) {
      case FuelType.petrol:
        return 'Petrol';
      case FuelType.diesel:
        return 'Diesel';
      case FuelType.electric:
        return 'Electric';
      case FuelType.hybrid:
        return 'Hybrid';
    }
  }

  String get transmissionDisplay =>
      transmission == Transmission.automatic ? 'Automatic' : 'Manual';

  String get pricePerDayNPR => 'NPR ${pricePerDay.toStringAsFixed(0)}/day';

  /// Safely decodes base64 image data for display.
  /// - Strips data URL prefix if present
  /// - Validates size (<2MB), MIME type
  /// - Comprehensive error logging
  static Uint8List? safeDecodeImage(String? base64Str) {
    if (base64Str == null || base64Str.isEmpty) {
      debugPrint('❌ Vehicle imageBase64 is empty/null');
      return null;
    }

    try {
      // Strip data URL prefix (data:image/...;base64,)
      String cleanBase64 = base64Str;
      String? mimeType;
      if (base64Str.contains(',')) {
        final parts = base64Str.split(',');
        if (parts.length > 1) {
          final header = parts[0];
          mimeType = header.split(':')[1].split(';')[0];
          cleanBase64 = parts[1];
        }
      }

      debugPrint(
          '🔍 Decoding image: ${mimeType ?? 'unknown'} (base64 len: ${cleanBase64.length})');

      final bytes = base64Decode(cleanBase64);

      // Size validation (<2MB)
      if (bytes.length > 2 * 1024 * 1024) {
        debugPrint('⚠️ Image too large: ${bytes.length} bytes (>2MB limit)');
        return null;
      }

      // Basic MIME validation
      if (mimeType != null && !mimeType.startsWith('image/')) {
        debugPrint('❌ Invalid MIME type: $mimeType');
        return null;
      }

      debugPrint(
          '✅ Image decoded: ${bytes.length} bytes (${mimeType ?? 'unknown'})');
      return bytes;
    } catch (e) {
      debugPrint('❌ Base64 decode FAILED: $e');
      debugPrint(
          '📄 Base64 preview: ${base64Str.length > 100 ? base64Str.substring(0, 100) + '...' : base64Str}');
      return null;
    }
  }
}
