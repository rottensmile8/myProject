enum UserRole {
  renter,
  owner,
}

class User {
  final String id;
  final String fullName;
  final String email;
  final int? phoneNumber;
  final UserRole role;
  final bool isActive;
  final List<String>? ownedCarIds; //only for owner

  User({
    required this.id,
    required this.fullName,
    required this.email,
    this.phoneNumber,
    required this.role,
    this.isActive = false,
    this.ownedCarIds,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: (json['_id'] is Map
          ? (json['_id']['\$oid'] ?? '')
          : (json['_id'] ?? '')), // 🐛 FIXED: MongoDB ObjectId parsing"
      fullName: json['fullName'],
      email: json['email'],
      role: json['role'] == 'owner' ? UserRole.owner : UserRole.renter,
      isActive: json['isActive'] ?? true, // Default to true for existing users
    );
  }
}
