import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_slidable/flutter_slidable.dart';


import 'settings_page.dart';

class NotificationLogPage extends StatefulWidget {
  const NotificationLogPage({super.key});

  @override
  State<NotificationLogPage> createState() => NotificationLogPageState();
}

class NotificationLogPageState extends State<NotificationLogPage> {
  List<Map<String, dynamic>> _localNotifications = [];
  bool _hasLoaded = false;

  @override
  void initState() {
    super.initState();
    fetchNotifications();
  }


  Future<void> fetchNotifications() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    print("👀 Logged in user ID: $userId");

    if (userId == null || userId.isEmpty) {
      setState(() {
        _hasLoaded = true;
      });
      return;
    }

    final response = await Supabase.instance.client
        .from('notifications')
        .select('id, message, timestamp, is_reviewed, ip_cameras(id)')
        .eq('user_id', userId)
        .order('timestamp', ascending: false)
        .execute();

    print("📦 Supabase response: ${response.data}");

    setState(() {
      _localNotifications = List<Map<String, dynamic>>.from(response.data ?? []);
      _hasLoaded = true;
    });

  }

  // 👑 This is what you'll call from anywhere via the GlobalKey!
  void addNotificationToUI({
    required String message,
    required String cameraName,
  }) {
    print("🔥 addNotificationToUI called with: $message from $cameraName");

    final now = DateTime.now();

    final newNotif = {
      'id': UniqueKey().toString(),
      'message': message,
      'timestamp': now.toIso8601String(),
      'is_reviewed': false,
      'ip_cameras': {'name': cameraName},
    };

    setState(() {
      _localNotifications.insert(0, newNotif);
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: !_hasLoaded
            ? const Center(child: CircularProgressIndicator())
            : ListView(
          children: [
            _buildHeader(),
            ..._localNotifications.map((notif) => _buildNotificationCard(notif)),
            _buildInfoCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Image.asset(
      'assets/3.png',
      width: double.infinity,
      fit: BoxFit.cover,
    );
  }



  Future<void> _deleteNotification(String id) async {
    final response = await Supabase.instance.client
        .from('notifications')
        .delete()
        .eq('id', id)
        .execute();


    setState(() {
      _localNotifications.removeWhere((notif) => notif['id'] == id);
    });

    print("🗑️ Notification deleted");
  }


  Widget _buildNotificationCard(Map<String, dynamic> data) {
    final timestamp = DateTime.parse(data['timestamp']);
    final dateString = "${timestamp.day.toString().padLeft(2, '0')}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.year}";
    final cameraName = data['ip_cameras']['name'] ?? 'CAM';
    final isReviewed = data['is_reviewed'] ?? false;
    final id = data['id'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Slidable(
        key: ValueKey(id),
        endActionPane: ActionPane(
          motion: const DrawerMotion(),
          children: [
            if (!isReviewed)
              SlidableAction(
                onPressed: (_) async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Mark as Reviewed'),
                      content: const Text('Are you sure you want to mark this as reviewed?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () async {
                            final user = Supabase.instance.client.auth.currentUser;
                            if (user == null) return;

                            await Supabase.instance.client
                                .from('notifications')
                                .update({'is_reviewed': true})
                                .eq('id', id)
                                .execute();

                            await Supabase.instance.client.from('detection_log').insert({
                              'user_id': user.id,
                              'camera_id': data['ip_cameras']['id'],
                              'confirmed': true,
                              'detected_at': data['timestamp'],
                            }).execute();

                            setState(() {
                              data['is_reviewed'] = true;
                            });

                            Navigator.pop(context, true);
                          },
                          child: const Text('Yes'),
                        ),
                      ],
                    ),
                  );
                },
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                icon: Icons.check,
                label: 'Review',
              ),
            SlidableAction(
              onPressed: (_) async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Notification'),
                    content: const Text('Do you really want to delete this notification?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Delete', style: TextStyle(color: Color(0xFFFF0000))),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  await _deleteNotification(id);
                }
              },
              backgroundColor: const Color(0xFFFF0000),
              foregroundColor: Colors.white,
              icon: Icons.delete,
              label: 'Delete',
            ),
          ],
        ),
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: ListTile(
            leading: Icon(
              isReviewed ? Icons.verified : Icons.notifications_active,
              color: isReviewed ? Colors.green : const Color(0xFFFF0000),
            ),
            title: Text("$cameraName  Fire is detected"),
            subtitle: Text(data['message']),
            trailing: Text(dateString),
          ),
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
