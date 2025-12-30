import 'package:flutter/material.dart';
import 'package:werent/models/user_model.dart';

class AuthController extends ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;

 //Simulated authentication methods 

Future<User?> loginwithRole(String email, String password, UserRole expectedRole) async {
  _isLoading = true;
  notifyListeners();

  try{
    await Future.delayed(const Duration(seconds: 2));

    _currentUser = User.dummyUsers.firstWhere(
      (user) => 
        user.email == email && user.role == expectedRole,
      orElse: () => throw Exception('Invalid credentials or role'),
    );

    return _currentUser;
  }catch(e){
    rethrow;
  }finally{
    _isLoading = false;
    notifyListeners();
  }

}

Future<User?> register({
  required String fullName,
  required String email,
  required String password,
  required UserRole role,
}) async {
  _isLoading = true;
  notifyListeners();

  try{
    //simulate API.call
    await Future.delayed(const Duration(seconds: 2));

    //create new user (replace with firebase auth)
    _currentUser = User(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      fullName: fullName, 
      email: email, 
      role: role
      );
  } catch (e) {
    rethrow;
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}

Future<void> logout() async {
  _isLoading = true;
  notifyListeners();

  try{
    await Future.delayed(const Duration(seconds: 3));
    _currentUser = null;
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}

Future<void> _resetpassword(String email) async {
  _isLoading = true;
  notifyListeners();

  try{
    //simulate API call
    await Future.delayed(const Duration(seconds: 2));

  } finally {
    _isLoading = false;
    notifyListeners();
  }

}
//helper method to determine initial route
String getnInitialRoute(){
  if (_currentUser == null) return '/auth';
  return _currentUser!.role == UserRole.owner
    ? '/owner/dashboard'
    : '/home';
}
}
