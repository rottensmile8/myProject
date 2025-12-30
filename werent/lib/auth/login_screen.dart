import 'package:flutter/material.dart';
import 'package:werent/controllers/auth_controller.dart';
import 'package:werent/models/user_model.dart';
import 'package:werent/widgets/custom_field.dart';
import 'package:werent/auth/signup_screen.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authController = AuthController();
  final _formKey = GlobalKey<FormState>();

  bool _obscurePassword = true;
  bool _isLoading = false;
  UserRole _selectedRole = UserRole.renter;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22.15),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const SizedBox(height: 56.9),

                  // Logo Circle
                  Center(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14.76),
                          decoration: const BoxDecoration(
                            color: Color.fromARGB(223, 34, 110, 223),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.home_rounded,
                            size: 48,
                            color: Color.fromARGB(223, 53, 61, 220),
                          ),
                        ),
                        const SizedBox(height: 44.3),

                        // Welcome Text
                        const Text(
                          'Welcome Back',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Login to continue',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 30.3),

                        // Role selection
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildRoleTab(UserRole.renter, 'Renter'),
                              ),
                              Expanded(
                                child: _buildRoleTab(UserRole.owner, 'Owner'),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 30),

                        // Email field
                        CustomTextField(
                          controller: _emailController,
                          hintText: 'Email',
                        ),
                        const SizedBox(height: 16),

                        // Password field
                        CustomTextField(
                          controller: _passwordController,
                          hintText: 'Password',
                          obscureText: _obscurePassword,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Login Button
                        

                        SizedBox( 
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _loginUser,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : const Text(
                                    'Login',
                                    style: TextStyle(
                                        color: Color.fromARGB(255, 0, 0, 0),
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 30),

                        const SizedBox(height: 16),

Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    const Text(
      "Don't have an account?",
      style: TextStyle(color: Colors.black54),
    ),
    TextButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const SignUpScreen(),
          ),
        );
      },
      child: const Text(
        "Sign Up",
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.blue,
        ),
      ),
    ),
  ],
),

const SizedBox(height: 30),

                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  

  // Role Tab Widget
  Widget _buildRoleTab(UserRole role, String label) {
    final bool isSelected = _selectedRole == role;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRole = role;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  // Login function
  void _loginUser() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final user = await _authController.loginwithRole(
          _emailController.text,
          _passwordController.text,
          _selectedRole,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Logged in as ${user?.fullName}')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

// CustomTextField Widget
class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final Widget? suffixIcon;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.obscureText = false,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        hintText: hintText,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        suffixIcon: suffixIcon,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter $hintText';
        }
        return null;
      },
    );
  }
}
