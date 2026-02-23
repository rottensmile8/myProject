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
    );
  }

  Map<String, dynamic> toJson() {
    return {
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
}
