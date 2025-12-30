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

  static List<User> dummyUsers = [
    User(
    id: '1', 
    fullName: 'Oli', 
    email: 'oli@gmail.com', 
    role: UserRole.renter
    ),

    User(
    id: '1', 
    fullName: 'Shyam', 
    email: 'Shyam@gmail.com', 
    role: UserRole.owner ,
    ownedCarIds: ['1', '2']
    ),
  ];
    


}