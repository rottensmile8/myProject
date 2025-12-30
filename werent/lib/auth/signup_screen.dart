import 'package:flutter/material.dart';
import 'package:werent/models/user_model.dart';
import 'package:werent/widgets/custom_field.dart';



class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();

  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  UserRole _selectedRole = UserRole.renter;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Account"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 30),

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

              const SizedBox(height: 24),

              CustomTextField(
                controller: _fullNameController,
                hintText: 'Full Name',
              ),
              const SizedBox(height: 16),

              CustomTextField(
                controller: _emailController,
                hintText: 'Email',
              ),
              const SizedBox(height: 16),

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

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _signUpUser,
                  child: const Text(
                    "Sign Up",
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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

  void _signUpUser() {
    if (_formKey.currentState!.validate()) {
      // Call your AuthController signup method here
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Account created successfully")),
      );

      Navigator.pop(context); // Go back to Login screen
    }
  }
}
