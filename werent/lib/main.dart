import 'package:flutter/material.dart';
import 'package:werent/auth/login_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // optional: hide debug banner
      title: 'We Rent',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        // You can also use colorScheme.fromSeed if you want
      ),
      home: const LoginScreen(), // ← Set LoginScreen as home
    );
  }
}
