import 'package:flutter/material.dart';
import 'package:flutterilk/service/auth.dart';
import 'package:flutterilk/pages/login_register.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ResetPasswordPage extends StatefulWidget {
  final String email;

  const ResetPasswordPage({super.key, required this.email});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;

  String? _codeError;
  String? _passwordError;
  String? _confirmPasswordError;

  bool _showPassword = false;
  bool _showConfirmPassword = false;

  bool _isValidPassword(String password) {
    final regex = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).{6,}$');
    final hasWhitespace = password.contains(RegExp(r'\s'));
    return regex.hasMatch(password) && !hasWhitespace;
  }

  Future<void> _resetPassword() async {
    final code = _codeController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    setState(() {
      _codeError = null;
      _passwordError = null;
      _confirmPasswordError = null;
    });

    if (code.isEmpty) {
      setState(() => _codeError = 'Verification code is required');
      return;
    }

    if (!_isValidPassword(password)) {
      setState(() => _passwordError = 'Password must be at least 6 characters,\ninclude uppercase, lowercase, number,\nand no spaces');
      return;
    }

    if (password != confirmPassword) {
      setState(() => _confirmPasswordError = 'Passwords do not match');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await AuthService().updatePasswordWithToken(
        email: widget.email,
        token: code,
        newPassword: password,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your password has been successfully updated!')),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginRegisterPage()),
            (route) => false,
      );
    } on AuthException catch (e) {
      final msg = _getErrorMessage(e.message);
      if (msg.contains('Invalid')) {
        setState(() => _codeError = msg);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unexpected error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getErrorMessage(String message) {
    if (message.contains('Invalid token')) return 'Invalid or expired code';
    if (message.contains('User not found')) return 'User not found';
    return message;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Enter the 6-digit code sent to ${widget.email}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 30),

            TextField(
              controller: _codeController,
              decoration: InputDecoration(
                labelText: 'Verification Code',
                hintText: '123456',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.sms, color: Colors.black),
                errorText: _codeError,
              ),
              keyboardType: TextInputType.number,
              maxLength: 6,
            ),
            const SizedBox(height: 20),

            TextField(
              controller: _passwordController,
              obscureText: !_showPassword,
              decoration: InputDecoration(
                labelText: 'New Password',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.lock, color: Colors.black),
                suffixIcon: IconButton(
                  icon: Icon(
                    _showPassword ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      _showPassword = !_showPassword;
                    });
                  },
                ),
                errorText: _passwordError,
              ),
            ),
            const SizedBox(height: 15),

            TextField(
              controller: _confirmPasswordController,
              obscureText: !_showConfirmPassword,
              onSubmitted: (_) => _resetPassword(),
              decoration: InputDecoration(
                labelText: 'Verify Password',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.verified, color: Colors.black),
                suffixIcon: IconButton(
                  icon: Icon(
                    _showConfirmPassword ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      _showConfirmPassword = !_showConfirmPassword;
                    });
                  },
                ),
                errorText: _confirmPasswordError,
              ),
            ),

            const SizedBox(height: 25),

            ElevatedButton(
              onPressed: _isLoading ? null : _resetPassword,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                'Reset Password',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
