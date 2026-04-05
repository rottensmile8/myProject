class Booking {
  final String id;
  final String vehicleId;
  final String vehicleName;
  final String vehicleCategory;
  final String? vehicleImageBase64;
  final String renterId;
  final String renterName;
  final String renterEmail;
  final DateTime startDate;
  final DateTime endDate;
  final double totalPrice;
  final String status; // pending, confirmed, completed, cancelled
  final DateTime createdAt;

  Booking({
    required this.id,
    required this.vehicleId,
    required this.vehicleName,
    required this.vehicleCategory,
    this.vehicleImageBase64,
    required this.renterId,
    required this.renterName,
    required this.renterEmail,
    required this.startDate,
    required this.endDate,
    required this.totalPrice,
    required this.status,
    required this.createdAt,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['_id'] ?? '',
      vehicleId: json['vehicleId'] ?? '',
      vehicleName: json['vehicleName'] ?? '',
      vehicleCategory: json['vehicleCategory'] ?? '',
      vehicleImageBase64: json['vehicleImageBase64'] as String?,
      renterId: json['renterId'] ?? '',
      renterName: json['renterName'] ?? '',
      renterEmail: json['renterEmail'] ?? '',
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'])
          : DateTime.now(),
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'])
          : DateTime.now(),
      totalPrice: (json['totalPrice'] ?? 0).toDouble(),
      status: json['status'] ?? 'pending',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vehicleId': vehicleId,
      'renterId': renterId,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'totalPrice': totalPrice,
      'status': status,
    };
  }

  // Helper getters for display
  String get statusDisplay {
    switch (status) {
      case 'confirmed':
        return 'Confirmed';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      case 'pending':
      default:
        return 'Pending';
    }
  }

  String get statusColor {
    switch (status) {
      case 'confirmed':
        return 'green';
      case 'completed':
        return 'blue';
      case 'cancelled':
        return 'red';
      case 'pending':
      default:
        return 'orange';
    }
  }

  String get dateRangeDisplay {
    final start = '${startDate.day}/${startDate.month}/${startDate.year}';
    final end = '${endDate.day}/${endDate.month}/${endDate.year}';
    return '$start - $end';
  }

  int get rentalDays {
    return endDate.difference(startDate).inDays + 1;
  }

  bool get isOverdue {
    final now = DateTime.now();
    final endDateOnly = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
    return now.isAfter(endDateOnly);
  }

  bool get isCurrentlyRented {
    if (status != 'confirmed') return false;
    final now = DateTime.now();
    // Normalize to dates
    final startDateOnly = DateTime(startDate.year, startDate.month, startDate.day);
    final endDateOnly = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
    return now.isAfter(startDateOnly.subtract(const Duration(seconds: 1))) && 
           now.isBefore(endDateOnly);
  }

  int get daysRemaining {
    final now = DateTime.now();
    final endDateOnly = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
    if (now.isAfter(endDateOnly)) return 0;
    return endDateOnly.difference(now).inDays + 1;
  }
}
