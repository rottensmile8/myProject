

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
  final List<String>? ownedCarIds; //only for owner

  User({
    required this.id,
    required this.fullName,
    required this.email,
    this.phoneNumber,
    required this.role,
    this.ownedCarIds,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? '',  // MongoDB _id
      fullName: json['fullName'],
      email: json['email'],
      role: json['role'] == 'owner' ? UserRole.owner : UserRole.renter,
    );
  }
}