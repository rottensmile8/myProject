import 'package:flutter/material.dart';
import 'package:werent/auth/login_screen.dart';
import 'package:werent/auth/signup_screen.dart';
import 'package:werent/auth/renter_dashboard.dart';
import 'package:werent/auth/owner_dashboard.dart';
import 'package:werent/auth/add_vehicle.dart';
import 'package:werent/auth/my_vehicles.dart';
import 'package:werent/auth/bookings.dart';
import 'package:werent/auth/browse_vehicles.dart';
import 'package:werent/models/user_model.dart';
import 'package:werent/controllers/auth_controller.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'We Rent',
      theme: ThemeData(primarySwatch: Colors.deepPurple),
      // Define named routes
      routes: {
        '/auth': (context) => const LoginScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/renter/dashboard': (context) {
          // Get user from arguments
          final user = ModalRoute.of(context)!.settings.arguments as User?;
          final authController = AuthController();
          if (user != null) {
            // Set the current user in the auth controller
            authController.setUser(user);
            return RenterDashboardPage(
              user: user,
              authController: authController,
            );
          }
          return const LoginScreen();
        },
        '/browse-vehicles': (context) {
          final user = ModalRoute.of(context)!.settings.arguments as User?;
          return BrowseVehiclesScreen(user: user);
        },
        '/owner/dashboard': (context) {
          // Get user from arguments
          final user = ModalRoute.of(context)!.settings.arguments as User?;
          final authController = AuthController();
          if (user != null) {
            // Set the current user in the auth controller
            authController.setUser(user);
            return OwnerDashboardPage(
              user: user,
              authController: authController,
            );
          }
          return const LoginScreen();
        },
        '/owner/add-vehicle': (context) {
          final user = ModalRoute.of(context)!.settings.arguments as User?;
          if (user != null) {
            return AddVehicleScreen(user: user);
          }
          return const LoginScreen();
        },
        '/owner/my-vehicles': (context) {
          final user = ModalRoute.of(context)!.settings.arguments as User?;
          if (user != null) {
            return MyVehiclesScreen(user: user);
          }
          return const LoginScreen();
        },
        '/owner/bookings': (context) {
          final user = ModalRoute.of(context)!.settings.arguments as User?;
          if (user != null) {
            return BookingsScreen(user: user);
          }
          return const LoginScreen();
        },
      },
      home: const LoginScreen(),
    );
  }
}
