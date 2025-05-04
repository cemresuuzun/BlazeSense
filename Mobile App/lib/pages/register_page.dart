import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart';
import 'package:flutterilk/service/auth.dart';

class TenDigitPhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    String digits = newValue.text.replaceAll(RegExp(r'\D'), '');

    if (digits.startsWith('0')) {
      digits = digits.substring(1);
    }

    if (digits.length > 10) {
      digits = digits.substring(0, 10);
    }

    return TextEditingValue(
      text: digits,
      selection: TextSelection.collapsed(offset: digits.length),
    );
  }
}

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final TextEditingController activationKeyController = TextEditingController();

  bool isPasswordVisible = false;
  bool isConfirmPasswordVisible = false;
  String? errorMessage;

  String _selectedCountryCode = '+90';
  final List<String> _countryCodes = ['+90', '+1', '+44', '+49', '+33'];

  Future<bool> isActivationKeyValid(String key) async {
    final response = await Supabase.instance.client
        .from('activation_key')
        .select('id')
        .eq('code', int.tryParse(key))
        .maybeSingle();

    return response != null;
  }

  Future<void> createUser() async {
    if (!_formKey.currentState!.validate()) return;

    if (passwordController.text != confirmPasswordController.text) {
      setState(() {
        errorMessage = "Passwords do not match";
      });
      return;
    }

    // Get activation key data from DB
    final activationKey = await Supabase.instance.client
        .from('activation_key')
        .select()
        .eq('code', int.tryParse(activationKeyController.text))
        .maybeSingle();

    if (activationKey == null) {
      setState(() {
        errorMessage = "Activation key is invalid";
      });
      return;
    }

    try {
      final response = await AuthService().signUp(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final user = response.user;

      if (user != null) {
        final fullPhone =
            '$_selectedCountryCode${phoneController.text.replaceAll(RegExp(r'\\D'), '')}';

        // ✅ Insert user with activation_key_id
        await Supabase.instance.client.from('users').insert({
          'id': user.id,
          'email': emailController.text.trim(),
          'username': usernameController.text.trim(),
          'phone': fullPhone,
          'activation_key_id': activationKey['id'], // ⭐️ key added here
          'created_at': DateTime.now().toIso8601String(),
        });

        // ✅ Insert to activation_key_users table
        await Supabase.instance.client.from('activation_key_users').insert({
          'activation_key_id': activationKey['id'],
          'user_id': user.id,
        });

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('\u{1F389} Registered successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        setState(() {
          errorMessage = "Registration failed.";
        });
      }
    } on PostgrestException catch (e) {
      final combined = '${e.message ?? ''} ${e.details ?? ''}';
      final errors = <String>[];

      if (combined.contains('users_email_key')) {
        errors.add('A user with this email already exists.');
      }
      if (combined.contains('users_username_key')) {
        errors.add('This username is already taken.');
      }
      if (combined.contains('users_phone_key')) {
        errors.add('A user with this phone number already exists.');
      }

      if (errors.isEmpty) {
        errors.add('Unexpected database error: ${e.message}');
      }

      setState(() {
        errorMessage = errors.join('\n');
      });
    } on AuthException catch (e) {
      setState(() => errorMessage = e.message);
    } catch (e) {
      setState(() => errorMessage = "Unexpected error: $e");
    }
  }


  Widget buildInput({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    bool isObscure = false,
    VoidCallback? toggleObscure,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword ? isObscure : false,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.black),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.black),
        prefixIcon: Icon(icon, color: Colors.black),
        suffixIcon: isPassword
            ? IconButton(
          icon: Icon(
            isObscure ? Icons.visibility : Icons.visibility_off,
            color: Colors.black,
          ),
          onPressed: toggleObscure,
        )
            : null,
        border: const OutlineInputBorder(),
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.black),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.black, width: 1.5),
        ),
      ),
      validator: validator,
    );
  }

  Widget buildPhoneInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCountryCode,
                  items: _countryCodes
                      .map((code) => DropdownMenuItem(value: code, child: Text(code)))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCountryCode = value!;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                inputFormatters: [TenDigitPhoneFormatter()],
                decoration: const InputDecoration(
                  hintText: '5XX XXX XXXX',
                  counterText: '',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final digits = value?.replaceAll(RegExp(r'\D'), '') ?? '';
                  if (digits.length != 10) {
                    return 'Enter a valid 10-digit phone number';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('Register', style: TextStyle(color: Colors.white)),
          backgroundColor: const Color(0xFFFF0000),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                buildInput(
                  label: "Username",
                  controller: usernameController,
                  icon: Icons.person,
                  validator: (value) =>
                  value == null || value.isEmpty ? 'Username is required' : null,
                ),
                const SizedBox(height: 20),
                buildInput(
                  label: "Email",
                  controller: emailController,
                  icon: Icons.email,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Email is required';
                    final emailRegex =
                    RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                    if (!emailRegex.hasMatch(value)) return 'Enter a valid email address';
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                buildPhoneInput(),
                const SizedBox(height: 20),
                buildInput(
                  label: "Activation Key",
                  controller: activationKeyController,
                  icon: Icons.vpn_key,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Activation key is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                buildInput(
                  label: "Password",
                  controller: passwordController,
                  icon: Icons.lock,
                  isPassword: true,
                  isObscure: !isPasswordVisible,
                  toggleObscure: () {
                    setState(() {
                      isPasswordVisible = !isPasswordVisible;
                    });
                  },
                  validator: (value) => value == null || value.length < 6
                      ? 'Password must be at least 6 characters'
                      : null,
                ),
                const SizedBox(height: 20),
                buildInput(
                  label: "Confirm Password",
                  controller: confirmPasswordController,
                  icon: Icons.lock_outline,
                  isPassword: true,
                  isObscure: !isConfirmPasswordVisible,
                  toggleObscure: () {
                    setState(() {
                      isConfirmPasswordVisible = !isConfirmPasswordVisible;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Please confirm your password';
                    if (value != passwordController.text) return 'Passwords do not match';
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                if (errorMessage != null)
                  Text(errorMessage!, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: createUser,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: const Color(0xFFFF0000),
                    foregroundColor: Colors.white,
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
      ),
    );
  }
}
