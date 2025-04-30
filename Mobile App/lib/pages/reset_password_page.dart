import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ResetPasswordPage extends StatefulWidget {
  final String refreshToken;

  const ResetPasswordPage({
    super.key,
    required this.refreshToken,
  });

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  bool isLoading = false;
  String? error;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  Future<void> updatePassword() async {
    final newPassword = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    if (newPassword.isEmpty || newPassword.length < 6) {
      setState(() => error = 'Password must be at least 6 characters');
      return;
    }

    if (newPassword != confirmPassword) {
      setState(() => error = 'Passwords do not match');
      return;
    }

    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      // Refresh token ile session başlatıyoruz
      final sessionResponse = await Supabase.instance.client.auth.setSession(
        widget.refreshToken,
      );

      // Eğer sessionResponse'da bir hata varsa, error olarak göster
      if (sessionResponse.user == null) {
        setState(() => error = 'Failed to authenticate user');
        return;
      }

      // Şifreyi güncelleme işlemi
      final response = await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      if (response.user?.id != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password updated successfully'),
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.pop(context);
      }
    } on AuthException catch (e) {
      setState(() => error = e.message);
    } catch (e) {
      setState(() => error = 'An error occurred. Please try again.');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
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
            const SizedBox(height: 20),
            const Text(
              'Create a new password',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            TextField(
              controller: passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'New Password',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: confirmPasswordController,
              obscureText: _obscureConfirmPassword,
              decoration: InputDecoration(
                labelText: 'Confirm New Password',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                  },
                ),
              ),
              onSubmitted: (_) => updatePassword(),
            ),
            if (error != null) ...[
              const SizedBox(height: 15),
              Text(
                error!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: isLoading ? null : updatePassword,
              child: isLoading
                  ? const CircularProgressIndicator()
                  : const Text(
                'Update Password',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
