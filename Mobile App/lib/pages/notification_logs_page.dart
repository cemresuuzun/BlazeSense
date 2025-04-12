import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Assume this exists!
import 'settings_page.dart';

class NotificationLogPage extends StatefulWidget {
  const NotificationLogPage({super.key});

  @override
  State<NotificationLogPage> createState() => _NotificationLogPageState();
}

class _NotificationLogPageState extends State<NotificationLogPage> {
  Future<List<Map<String, dynamic>>> fetchNotifications() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    print("👀 Logged in user ID: $userId");

    if (userId == null || userId.isEmpty) {
      return [];
    }

    final response = await Supabase.instance.client
        .from('notifications')
        .select('id, message, timestamp, is_reviewed, ip_cameras!fk_notifications_camera(name)')
        .eq('user_id', userId)
        .order('timestamp', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: FutureBuilder(
          future: fetchNotifications(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              print("🔥 Error fetching notifications: ${snapshot.error}");
              return Center(child: Text("Something went wrong: ${snapshot.error}"));
            }

            final notifications = snapshot.data ?? [];

            return ListView(
              children: [
                _buildHeader(),
                ...notifications.map((notif) => _buildNotificationCard(notif)),
                _buildInfoCard(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.red.shade700,
      child: Row(
        children: [
          const Icon(Icons.home, color: Colors.white),
          const SizedBox(width: 10),
          const Text(
            'BlazeSense',
            style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          const Icon(Icons.notifications, color: Colors.white),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> data) {
    final timestamp = DateTime.parse(data['timestamp']);
    final dateString = "${timestamp.day.toString().padLeft(2, '0')}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.year}";
    final cameraName = data['ip_cameras']['name'] ?? 'CAM';
    final isReviewed = data['is_reviewed'] ?? false;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ListTile(
          leading: Icon(
            isReviewed ? Icons.verified : Icons.notifications_active,
            color: isReviewed ? Colors.green : Colors.red,
          ),
          title: Text("$cameraName  Fire is detected"),
          subtitle: Text(data['message']),
          trailing: Text(dateString),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ListTile(
          leading: const Icon(Icons.campaign, color: Colors.blue),
          title: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
            child: const Text(
              "Haven't customized your notifications? Go to settings to choose which alarms you want to receive.",
              style: TextStyle(
                fontSize: 13,
                color: Colors.blue,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
