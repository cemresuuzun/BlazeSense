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
  String? _errorMessage;

  Future<void> _resetPassword() async {
    if (_codeController.text.isEmpty) {
      setState(() => _errorMessage = 'Password must be at least 6 characters');
      return;
    }

    if (_passwordController.text.length < 6) {
      setState(() => _errorMessage = 'Şifre en az 6 karakter olmalıdır');
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _errorMessage = 'Passwords do not match');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // YENİ AUTH SERVICE'E UYGUN ÇAĞRI
      await AuthService().updatePasswordWithToken(
        email: widget.email, // Sayfadan gelen email
        token: _codeController.text.trim(),
        newPassword: _passwordController.text,
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
      setState(() => _errorMessage = _getErrorMessage(e.message));
    } catch (e) {
      setState(() => _errorMessage = 'Error: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Hata mesajlarını Türkçeleştirme
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
              'Enter the 6-digit code sent to ${widget.email} ',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 30),
            TextField(
              controller: _codeController,
              decoration: const InputDecoration(
                labelText: 'Verificaiton Code',
                hintText: '123456',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.sms,color: Colors.black),
              ),
              keyboardType: TextInputType.number,
              maxLength: 6,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'New Password',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock, color: Colors.black),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Verify Password',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.verified, color: Colors.black),
              ),
              onSubmitted: (_) => _resetPassword(),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 15),
              Text(
                _errorMessage!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ],
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
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,color: Colors.white,),
              ),
            ),
          ],
        ),
      ),
    );
  }
}