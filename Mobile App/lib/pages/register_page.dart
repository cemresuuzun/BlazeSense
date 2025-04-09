import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutterilk/service/auth.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  String? errorMessage;

  Future<void> createUser() async {
    if (passwordController.text != confirmPasswordController.text) {
      setState(() {
        errorMessage = "Passwords do not match";
      });
      return;
    }

    try {
      final response = await AuthService().createUser(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final user = response.user;

      if (user != null) {
        await Supabase.instance.client.from('users').insert({
          'id': user.id,
          'email': emailController.text.trim(),
          'username': usernameController.text.trim(),
          'phone': phoneController.text.trim(),
          'created_at': DateTime.now().toIso8601String(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🎉 Registered successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } else {
        setState(() {
          errorMessage = "Registration failed.";
        });
      }
    } on AuthException catch (e) {
      setState(() {
        errorMessage = e.message;
      });
    } catch (e) {
      setState(() {
        errorMessage = "Unexpected error: $e";
      });
    }
  }

  Widget buildInput({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white),
        prefixIcon: Icon(icon, color: Colors.white),
        border: const OutlineInputBorder(),
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white70),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFFFF416C),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFF416C),
              Color(0xFFFF4B2B),
              Color(0xFFFF9900),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: ListView(
            children: [
              buildInput(label: "Username", controller: usernameController, icon: Icons.person),
              const SizedBox(height: 20),
              buildInput(
                label: "Email",
                controller: emailController,
                icon: Icons.email,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 20),
              buildInput(
                label: "Phone",
                controller: phoneController,
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 20),
              buildInput(
                label: "Password",
                controller: passwordController,
                icon: Icons.lock,
                isPassword: true,
              ),
              const SizedBox(height: 20),
              buildInput(
                label: "Confirm Password",
                controller: confirmPasswordController,
                icon: Icons.lock_outline,
                isPassword: true,
              ),
              const SizedBox(height: 20),
              if (errorMessage != null)
                Text(
                  errorMessage!,
                  style: const TextStyle(color: Colors.white),
                ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: createUser,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFFFF416C),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  "Register",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
