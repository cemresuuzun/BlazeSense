import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutterilk/pages/profile_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutterilk/notification/notification_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart' as fln;

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final user = Supabase.instance.client.auth.currentUser;

  bool soundEnabled = true;
  bool vibrationEnabled = true;
  bool inAppNotifications = true;

  @override
  void initState() {
    super.initState();
    fetchUserPreferences();
  }

  Future<void> fetchUserPreferences() async {
    try {
      final response = await Supabase.instance.client
          .from('settings')
          .select('sound_enabled, vibration_enabled, in_app_notifications')
          .eq('user_id', user?.id)
          .single();

      setState(() {
        soundEnabled = response['sound_enabled'] ?? true;
        vibrationEnabled = response['vibration_enabled'] ?? true;
        inAppNotifications = response['in_app_notifications'] ?? true;
      });
    } catch (e) {
      print("⚠️ No settings found for this user. Creating defaults...");

      await Supabase.instance.client.from('settings').insert({
        'user_id': user?.id,
        'sound_enabled': true,
        'vibration_enabled': true,
        'in_app_notifications': true,
      });

      setState(() {
        soundEnabled = true;
        vibrationEnabled = true;
        inAppNotifications = true;
      });
    }
  }

  Future<void> updateUserPreference(String key, bool value) async {
    if (user == null) return;

    await Supabase.instance.client
        .from('settings')
        .update({key: value})
        .eq('user_id', user!.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: const Color(0xFFFF416C),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // User Info
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'User Information',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFF416C),
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.email, color: Color(0xFFFF416C)),
                  title: const Text('Email'),
                  subtitle: Text(user?.email ?? 'Not available'),
                ),
                ListTile(
                  leading: const Icon(Icons.access_time, color: Color(0xFFFF416C)),
                  title: const Text('User ID'),
                  subtitle: Text(user?.id ?? 'Not available'),
                ),
                ListTile(
                  leading: const Icon(Icons.account_circle, color: Color(0xFFFF416C)),
                  title: const Text('Edit Profile'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ProfilePage()),
                    );
                  },
                ),
              ],
            ),
          ),
          const Divider(),

          // Notification Settings
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Notification Preferences',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFF416C),
                  ),
                ),
                const SizedBox(height: 16),

                SwitchListTile(
                  title: const Text('Sound'),
                  subtitle: const Text('Play sound for notifications'),
                  value: soundEnabled,
                  activeColor: const Color(0xFFFF416C),
                  onChanged: (bool value) async {
                    setState(() {
                      soundEnabled = value;
                    });
                    await updateUserPreference('sound_enabled', value);
                  },
                ),
                SwitchListTile(
                  title: const Text('Vibration'),
                  subtitle: const Text('Vibrate on notifications'),
                  value: vibrationEnabled,
                  activeColor: const Color(0xFFFF416C),
                  onChanged: (bool value) async {
                    setState(() {
                      vibrationEnabled = value;
                    });
                    await updateUserPreference('vibration_enabled', value);
                  },
                ),
                SwitchListTile(
                  title: const Text('In-app Notifications'),
                  subtitle: const Text('Show alerts inside the app'),
                  value: inAppNotifications,
                  activeColor: const Color(0xFFFF416C),
                  onChanged: (bool value) async {
                    setState(() {
                      inAppNotifications = value;
                    });
                    await updateUserPreference('in_app_notifications', value);
                  },
                ),
                const SizedBox(height: 20),

                Center(
                  child: ElevatedButton(
                    onPressed: () async {
                      print("⏳ Waiting 5 seconds before notification...");
                      await Future.delayed(const Duration(seconds: 5));
                      print("🔥 Triggering showFireNotification manually...");
                      await showFireNotification('This is a test fire alert from the settings page!');
                    },
                    child: const Text('Test Fire Notification (5s Delay)'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
