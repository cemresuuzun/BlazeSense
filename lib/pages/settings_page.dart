import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final user = FirebaseAuth.instance.currentUser;
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
                title: const Text('Account Created'),
                subtitle: Text(
                  user?.metadata.creationTime?.toString() ?? 'Not available',
                ),
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
            ],
          ),
        ),
      ],
    );
  }
} 