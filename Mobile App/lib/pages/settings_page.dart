import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutterilk/pages/profile_page.dart';
import 'package:flutterilk/notification/notification_service.dart';
import 'package:flutterilk/pages/about_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final user = Supabase.instance.client.auth.currentUser;

  bool inAppNotifications = true;

  String username = '';
  String avatarUrl = 'assets/batman.png';

  final List<String> avatarList = [
    'assets/batman.png',
    'assets/wonderwoman.png',
  ];

  @override
  void initState() {
    super.initState();
    fetchUserPreferences();
    fetchUsername();
  }

  Future<void> fetchUserPreferences() async {
    try {
      final response = await Supabase.instance.client
          .from('settings')
          .select('in_app_notifications')
          .eq('user_id', user?.id)
          .single();

      setState(() {
        inAppNotifications = response['in_app_notifications'] ?? true;
      });
    } catch (e) {
      await Supabase.instance.client.from('settings').insert({
        'user_id': user?.id,
        'in_app_notifications': true,
      });

      setState(() {
        inAppNotifications = true;
      });
    }
  }

  Future<void> fetchUsername() async {
    try {
      final response = await Supabase.instance.client
          .from('users')
          .select('username')
          .eq('id', user?.id)
          .single();

      setState(() {
        username = response['username'] ?? '';
      });
    } catch (e) {
      setState(() {
        username = 'Unknown User';
      });
    }
  }

  Future<void> updateUserPreference(String key, bool value) async {
    if (user == null) return;

    await Supabase.instance.client
        .from('settings')
        .update({key: value}).eq('user_id', user!.id);
  }

  void _selectAvatar() async {
    final String? selectedAvatar = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Choose Avatar'),
          content: SingleChildScrollView(
            child: Column(
              children: avatarList.map((avatar) {
                return ListTile(
                  leading: Image.asset(avatar, width: 50, height: 50),
                  title: Text(avatar.split('/').last.replaceAll('.png', '')),
                  onTap: () {
                    Navigator.pop(context, avatar);
                  },
                );
              }).toList(),
            ),
          ),
        );
      },
    );

    if (selectedAvatar != null) {
      setState(() {
        avatarUrl = selectedAvatar;
      });
    }
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: const Color(0xFFF7F7F7),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFFFF0000)),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFF0000),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildTile(IconData icon, String title, String subtitle) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFFFF0000)),
      title: Text(title),
      subtitle: Text(subtitle),
    );
  }

  Widget _buildSwitchTile(
      String title, String subtitle, bool value, Function(bool) onChanged) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      activeColor: const Color(0xFFFF0000),
      onChanged: (bool newValue) async => await onChanged(newValue),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFDFD),
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: const Color(0xFFFF0000),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildCard(
              title: 'User Information',
              icon: Icons.person,
              children: [
                Center(
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _selectAvatar,
                        child: CircleAvatar(
                          radius: 40,
                          backgroundImage: AssetImage(avatarUrl),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        username.isNotEmpty ? username : 'Username',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _buildTile(
                    Icons.email, 'Email', user?.email ?? 'Not available'),
                _buildTile(Icons.perm_identity, 'User ID',
                    user?.id ?? 'Not available'),
                ListTile(
                  leading: const Icon(Icons.account_circle,
                      color: Color(0xFFFF0000)),
                  title: const Text('Edit Profile'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const ProfilePage()),
                    );
                  },
                ),
              ],
            ),
            _buildCard(
              title: 'Notification Preferences',
              icon: Icons.notifications_active,
              children: [
                _buildSwitchTile(
                    'In-app Notifications',
                    'Show alerts inside the app',
                    inAppNotifications, (val) async {
                  setState(() => inAppNotifications = val);
                  await updateUserPreference('in_app_notifications', val);
                }),
              ],
            ),
            _buildCard(
              title: 'About',
              icon: Icons.info_outline,
              children: [
                ListTile(
                  title: const Text('About This App'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const AboutPage()),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF0000),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () async {
                await Future.delayed(const Duration(seconds: 5));
                //await showFireNotification('This is a test fire alert from the settings page!');
              },
              child: const Text('Test Fire Notification (5s Delay)'),
            ),
          ],
        ),
      ),
    );
  }
}
