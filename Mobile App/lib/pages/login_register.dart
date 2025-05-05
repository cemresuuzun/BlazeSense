import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutterilk/pages/reset_password_page.dart';
import 'package:flutterilk/pages/main_page.dart';
import 'package:flutterilk/pages/register_page.dart';
import '../service/auth.dart';

class LoginRegisterPage extends StatefulWidget {
  const LoginRegisterPage({super.key});

  @override
  State<LoginRegisterPage> createState() => _LoginRegisterPageState();
}

class _LoginRegisterPageState extends State<LoginRegisterPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isPasswordVisible = false;
  bool isLoading = false;
  String? emailError;
  String? passwordError;

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      setState(() => isLoading = true);
      await AuthService().sendPasswordResetEmail(email);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset code sent to your email')),
      );

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ResetPasswordPage(email: email)),
      );
    } on AuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void showForgotPasswordDialog(BuildContext context) {
    final TextEditingController resetEmailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.email_rounded, size: 50, color: Colors.black87),
                  const SizedBox(height: 16),
                  const Text(
                    "Forgot Your Password?",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Enter your email address to reset your password.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: resetEmailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: Colors.black),
                    decoration: const InputDecoration(
                      labelText: "Email Address",
                      labelStyle: TextStyle(color: Colors.black),
                      prefixIcon: Icon(Icons.email, color: Colors.black),
                      border: OutlineInputBorder(),
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.black54)),
                      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.black)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () async {
                      final email = resetEmailController.text.trim();
                      if (email.isEmpty || !email.contains('@')) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter a valid email')),
                        );
                        return;
                      }
                      Navigator.pop(context);
                      await sendPasswordResetEmail(email);
                    },
                    child: const Text("Send Reset Code", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> signIn() async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    setState(() {
      isLoading = true;
      emailError = null;
      passwordError = null;
    });

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        if (email.isEmpty) emailError = 'Email is required';
        if (password.isEmpty) passwordError = 'Password is required';
        isLoading = false;
      });
      return;
    }

    try {
      final auth = AuthService();
      final response = await auth.signIn(email: email, password: password);

      if (response.user != null && mounted) {
        final userId = response.user!.id;

        final userData = await Supabase.instance.client
            .from('users')
            .select('activation_key_id')
            .eq('id', userId)
            .maybeSingle();

        final activationKeyId = userData?['activation_key_id'];

        if (activationKeyId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No activation key linked to this account.'), backgroundColor: Colors.red),
          );
          return;
        }

        await auth.notifyBackendWithActivationKey(activationKeyId);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainPage()),
        );
      } else {
        setState(() {
          emailError = 'Wrong email or password';
          passwordError = 'Wrong email or password';
        });
      }
    } on AuthException catch (_) {
      setState(() {
        emailError = 'Wrong email or password';
        passwordError = 'Wrong email or password';
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unexpected error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.white,
        alignment: Alignment.topCenter,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 50),
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset('assets/LogoApp.png', height: 200, fit: BoxFit.scaleDown),
                    const SizedBox(height: 8),
                    const Text('Blaze Sense',
                        style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black, letterSpacing: 2)),
                    const SizedBox(height: 8),
                    const Text('Fire Detection System', style: TextStyle(fontSize: 16, color: Colors.black54)),
                    const SizedBox(height: 40),

                    /// Email Field
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                        labelText: "Email",
                        labelStyle: const TextStyle(color: Colors.black),
                        prefixIcon: const Icon(Icons.email, color: Colors.black),
                        border: const OutlineInputBorder(),
                        enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.black54)),
                        focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.black)),
                        errorText: emailError,
                      ),
                    ),
                    const SizedBox(height: 20),

                    /// Password Field
                    TextField(
                      controller: passwordController,
                      obscureText: !isPasswordVisible,
                      onSubmitted: (_) => signIn(),
                      style: const TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                        labelText: "Password",
                        labelStyle: const TextStyle(color: Colors.black),
                        prefixIcon: const Icon(Icons.lock, color: Colors.black),
                        suffixIcon: IconButton(
                          icon: Icon(isPasswordVisible ? Icons.visibility : Icons.visibility_off, color: Colors.black),
                          onPressed: () => setState(() => isPasswordVisible = !isPasswordVisible),
                        ),
                        border: const OutlineInputBorder(),
                        enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.black54)),
                        focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.black)),
                        errorText: passwordError,
                      ),
                    ),

                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => showForgotPasswordDialog(context),
                        child: const Text(
                          "Forgot Password?",
                          style: TextStyle(fontSize: 14, color: Colors.black, decoration: TextDecoration.underline),
                        ),
                      ),
                    ),

                    /// Login Button
                    ElevatedButton(
                      onPressed: isLoading ? null : signIn,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        backgroundColor: const Color(0xFFFF0000),
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("Login", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),

                    const SizedBox(height: 20),
                    TextButton(
                      onPressed: isLoading
                          ? null
                          : () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterPage()));
                      },
                      style: TextButton.styleFrom(foregroundColor: Colors.black),
                      child: const Text(
                        "Don't have an account? Register here",
                        style: TextStyle(fontSize: 14, decoration: TextDecoration.underline),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
