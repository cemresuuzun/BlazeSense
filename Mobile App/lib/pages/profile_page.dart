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

      if (userId == null) throw Exception('User not logged in.');

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
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: inputType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          filled: true,
          fillColor: Colors.white,
        ),
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
      backgroundColor: const Color(0xFFF4F4F4), // Hafif gri arka plan
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: const Color(0xFFB5062D),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Kullanıcı Bilgisi Kartı
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Color(0xFFB5062D),
                    child: Icon(Icons.person, color: Colors.white, size: 30),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      usernameController.text.isEmpty
                          ? 'Your Username'
                          : usernameController.text,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Form Alanları
            _buildField('Username', usernameController, Icons.person, TextInputType.name),
            _buildField('Phone', phoneController, Icons.phone, TextInputType.phone),

            // Güncelle Butonu
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
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
                  backgroundColor: const Color(0xFFB5062D),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 4,
                  shadowColor: Colors.black26,
                ),
              ),
            ),

            // Hata Mesajı
            if (errorMessage != null) ...[
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  errorMessage!,
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
