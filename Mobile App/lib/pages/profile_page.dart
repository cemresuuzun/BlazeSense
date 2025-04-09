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
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    final userId = supabase.auth.currentUser?.id;

    final response = await supabase
        .from('users')
        .select()
        .eq('id', userId)
        .single();

    if (response != null) {
      setState(() {
        usernameController.text = response['username'] ?? '';
        phoneController.text = response['phone'] ?? '';
        isLoading = false;
      });
    } else {
      setState(() {
        errorMessage = 'User data not found.';
        isLoading = false;
      });
    }
  }

  Future<void> updateProfile() async {
    final userId = supabase.auth.currentUser?.id;

    try {
      await supabase.from('users').update({
        'username': usernameController.text.trim(),
        'phone': phoneController.text.trim(),
      }).eq('id', userId);

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
    }
  }

  Widget _buildField(String label, TextEditingController controller, IconData icon) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
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
            _buildField('Username', usernameController, Icons.person),
            const SizedBox(height: 20),
            _buildField('Phone', phoneController, Icons.phone),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: updateProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF416C),
                foregroundColor: Colors.white,
              ),
              child: const Text('Update Profile'),
            ),
            if (errorMessage != null) ...[
              const SizedBox(height: 20),
              Text(errorMessage!, style: const TextStyle(color: Colors.red)),
            ],
          ],
        ),
      ),
    );
  }
}
