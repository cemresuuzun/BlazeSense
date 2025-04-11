import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final SupabaseClient supabase = Supabase.instance.client;

  final TextEditingController usernameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  bool isLoading = true;
  bool isUpdating = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final userId = supabase.auth.currentUser?.id;

      if (userId == null) {
        throw Exception('User not logged in.');
      }

      final response = await supabase
          .from('users')
          .select()
          .eq('id', userId)
          .single();

      usernameController.text = response['username'] ?? '';
      phoneController.text = response['phone'] ?? '';
    } catch (e) {
      errorMessage = 'Failed to load user data: $e';
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> updateProfile() async {
    final username = usernameController.text.trim();
    final phone = phoneController.text.trim();

    if (username.isEmpty || phone.isEmpty) {
      setState(() {
        errorMessage = 'Username and phone cannot be empty.';
      });
      return;
    }

    setState(() {
      isUpdating = true;
      errorMessage = null;
    });

    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not found.');

      await supabase.from('users').update({
        'username': username,
        'phone': phone,
      }).eq('id', userId);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Profile updated!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to update profile: $e';
      });
    } finally {
      setState(() => isUpdating = false);
    }
  }

  Widget _buildField(String label, TextEditingController controller, IconData icon, TextInputType inputType) {
    return TextField(
      controller: controller,
      keyboardType: inputType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: const Color(0xFFFF416C),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _buildField('Username', usernameController, Icons.person, TextInputType.name),
            const SizedBox(height: 20),
            _buildField('Phone', phoneController, Icons.phone, TextInputType.phone),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: isUpdating ? null : updateProfile,
              icon: isUpdating
                  ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
                  : const Icon(Icons.save),
              label: const Text('Update Profile'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF416C),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            if (errorMessage != null) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
