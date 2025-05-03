import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationPreferencesPage extends StatefulWidget {
  const NotificationPreferencesPage({super.key});

  @override
  State<NotificationPreferencesPage> createState() => _NotificationPreferencesPageState();
}

class _NotificationPreferencesPageState extends State<NotificationPreferencesPage> {
  final user = Supabase.instance.client.auth.currentUser;
  
  bool inAppNotifications = true;
  bool whatsappNotifications = true;
  bool emailNotifications = true;

  @override
  void initState() {
    super.initState();
    fetchUserPreferences();
  }

  Future<void> fetchUserPreferences() async {
    try {
      final response = await Supabase.instance.client
          .from('settings')
          .select('in_app_notifications, whatsapp_notifications, email_notifications')
          .eq('user_id', user?.id)
          .single();

      setState(() {
        inAppNotifications = response['in_app_notifications'] ?? true;
        whatsappNotifications = response['whatsapp_notifications'] ?? true;
        emailNotifications = response['email_notifications'] ?? true;
      });
    } catch (e) {
      await Supabase.instance.client.from('settings').insert({
        'user_id': user?.id,
        'in_app_notifications': true,
        'whatsapp_notifications': true,
        'email_notifications': true,
      });

      setState(() {
        inAppNotifications = true;
        whatsappNotifications = true;
        emailNotifications = true;
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

  Widget _buildSwitchTile(String title, String subtitle, bool value, Function(bool) onChanged) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SwitchListTile(
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        value: value,
        activeColor: const Color(0xFF282828),
        onChanged: onChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFDFD),
      appBar: AppBar(
        title: const Text('Notification Preferences'),
        backgroundColor: const Color(0xFF282828),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Notification Settings',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF282828),
                ),
              ),
            ),
            _buildSwitchTile(
              'In-app Notifications',
              'Show alerts inside the app',
              inAppNotifications,
              (val) async {
                setState(() => inAppNotifications = val);
                await updateUserPreference('in_app_notifications', val);
              },
            ),
            _buildSwitchTile(
              'WhatsApp Notifications',
              'Receive alerts via WhatsApp',
              whatsappNotifications,
              (val) async {
                setState(() => whatsappNotifications = val);
                await updateUserPreference('whatsapp_notifications', val);
              },
            ),
            _buildSwitchTile(
              'Email Notifications',
              'Receive alerts via email',
              emailNotifications,
              (val) async {
                setState(() => emailNotifications = val);
                await updateUserPreference('email_notifications', val);
              },
            ),
          ],
        ),
      ),
    );
  }
} 