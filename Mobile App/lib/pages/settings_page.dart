import 'package:flutter/material.dart';
import 'package:flutterilk/pages/about_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutterilk/pages/profile_page.dart';
import 'package:flutterilk/pages/login_register.dart'; // LoginPage import
import 'package:flutterilk/service/auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutterilk/pages/notification_preferences_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final user = Supabase.instance.client.auth.currentUser;

  bool inAppNotifications = true;

  String username = '';
  String avatarUrl = 'assets/elcik.png';

  final List<String> avatarList = [
    'assets/batman.png',
    'assets/wonderwoman.png',
    'assets/elcik.png',
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
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.account_circle,
                  size: 50,
                  color: Colors.black,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Choose Avatar',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  child: Column(
                    children: avatarList.map((avatar) {
                      return ListTile(
                        leading: Image.asset(avatar, width: 50, height: 50),
                        title:
                            Text(avatar.split('/').last.replaceAll('.png', '')),
                        onTap: () {
                          Navigator.pop(context, avatar);
                        },
                      );
                    }).toList(),
                  ),
                ),
              ],
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

  // Logout popup function
  Future<void> _handleLogout(BuildContext context) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.logout_rounded,
                size: 50,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              const Text(
                "Log Out?",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Are you sure you want to log out from your account?",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[200],
                      foregroundColor: Colors.black87,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text("Cancel"),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () async {
                      await AuthService().signOut();

                      // Show Toast Message
                      Fluttertoast.showToast(
                        msg: "You have been logged out.",
                        toastLength: Toast.LENGTH_SHORT,
                        gravity: ToastGravity.BOTTOM,
                        backgroundColor: Colors.green,
                        textColor: Colors.white,
                        fontSize: 16.0,
                      );

                      if (context.mounted) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const LoginRegisterPage()),
                        );
                      }
                    },
                    child: const Text("Log out"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard({
    String? title,
    IconData? icon,
    required List<Widget> children,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: const Color(0xFFFFFFFF),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null && icon != null) ...[
              Row(
                children: [
                  Icon(icon, color: const Color(0xFF282828)),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF282828),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildTile(IconData icon, String title, String subtitle) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF282828)),
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
      activeColor: const Color(0xFF282828),
      onChanged: (bool newValue) async => await onChanged(newValue),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F6),
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: const Color(0xFF282828),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => _handleLogout(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildCard(
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
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const ProfilePage()),
                        );
                      },
                      child: ListTile(
                        leading: const Icon(Icons.account_circle,
                            color: Color(0xFF282828)),
                        title: const Text(
                          'Edit Profile',
                          style: TextStyle(
                            fontSize: 14,
                          ),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Card(
              margin: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              color: const Color(0xFFFFFFFF),
              elevation: 0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const NotificationPreferencesPage()),
                      );
                    },
                    child: ListTile(
                      leading: const Icon(Icons.notifications_active,
                          color: Color(0xFF282828)),
                      title: const Text(
                        'Notification Settings',
                        style: TextStyle(
                          fontSize: 14,
                        ),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    ),
                  ),
                ),
              ),
            ),
            Card(
              margin: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              color: const Color(0xFFFFFFFF),
              elevation: 0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AboutPage()),
                      );
                    },
                    child: ListTile(
                      leading: const Icon(Icons.info_outline, color: Color(0xFF282828)),
                      title: const Text(
                        'About',
                        style: TextStyle(
                          fontSize: 14,
                        ),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
