
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutterilk/pages/profile_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutterilk/notification/notification_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart' as fln;



//Supabase doesn’t expose creationTime like Firebase, but you can:
// Store it manually during sign-up.
// Or create a users table and store additional metadata there (like name, registration date, etc.).

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final user = Supabase.instance.client.auth.currentUser;
  bool notificationsEnabled = true;
  bool soundEnabled = true;
  bool vibrationEnabled = true;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // User Information Section
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
        // Notification Preferences Section
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
                title: const Text('Enable Notifications'),
                subtitle: const Text('Receive alerts for fire detection'),
                value: notificationsEnabled,
                activeColor: const Color(0xFFFF416C),
                onChanged: (bool value) {
                  setState(() {
                    notificationsEnabled = value;
                  });
                },
              ),
              SwitchListTile(
                title: const Text('Sound'),
                subtitle: const Text('Play sound for notifications'),
                value: soundEnabled,
                activeColor: const Color(0xFFFF416C),
                onChanged: notificationsEnabled
                    ? (bool value) {
                  setState(() {
                    soundEnabled = value;
                  });
                }
                    : null,
              ),
              SwitchListTile(
                title: const Text('Vibration'),
                subtitle: const Text('Vibrate on notifications'),
                value: vibrationEnabled,
                activeColor: const Color(0xFFFF416C),
                onChanged: notificationsEnabled
                    ? (bool value) {
                  setState(() {
                    vibrationEnabled = value;
                  });
                }
                    : null,
              ),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: () async {
                    print("⏳ Waiting 5 seconds before notification...");

                    await Future.delayed(const Duration(seconds: 5));

                    final androidDetails = fln.AndroidNotificationDetails(
                      'test_channel',
                      'Test Notifications',
                      channelDescription: 'Used for testing local notifications',
                      importance: fln.Importance.max,
                      priority: fln.Priority.high,
                    );

                    final notificationDetails = fln.NotificationDetails(android: androidDetails);

                    print("🔥 Showing notification now!");

                    await flutterLocalNotificationsPlugin.show(
                      0,
                      '🔥 Fire Detected!',
                      'This is a delayed notification (5 seconds later)',
                      notificationDetails,
                    );
                  },
                  child: const Text('Test Fire Notification (5s Delay)'),
                ),

              ),


            ],
          ),
        ),
      ],
    );
  }
}
