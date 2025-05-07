import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter/services.dart';
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
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Color(0xFF282828),
      statusBarIconBrightness: Brightness.light,
    ));
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      if (!mounted) return;
      setState(() => _hasLoaded = true);
      return;
    }

    try {
      // 1. Get activation_key_id from users table
      final userRow = await Supabase.instance.client
          .from('users')
          .select('activation_key_id')
          .eq('id', user.id)
          .single();

      final activationKeyId = userRow['activation_key_id'];
      if (activationKeyId == null) throw Exception('No activation key found');

      // 2. Fetch all cameras tied to that key
      final cameraRows = await Supabase.instance.client
          .from('ip_cameras')
          .select('id')
          .eq('activation_key_id', activationKeyId);

      final cameraIds = cameraRows.map((cam) => cam['id']).toList();

      if (cameraIds.isEmpty) {
        setState(() {
          _localNotifications = [];
          _hasLoaded = true;
        });
        return;
      }

      // 3. Fetch notifications for those camera IDs
      final response = await Supabase.instance.client
          .from('notifications')
          .select('id, message, timestamp, is_reviewed, ip_cameras(id, name)')
          .in_('camera_id', cameraIds)
          .eq('is_reviewed', false)
          .order('timestamp', ascending: false);


      if (!mounted) return;

      setState(() {
        _localNotifications =
        List<Map<String, dynamic>>.from(response);
        _hasLoaded = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hasLoaded = true;
        _localNotifications = [];
      });
      print("❌ Error fetching notifications: $e");
    }
  }



  void addNotificationToUI({
    required String message,
    required String cameraName,
  }) {
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
      appBar: AppBar(
        title: const Text('Notification Log'),
        backgroundColor: const Color(0xFF282828),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: !_hasLoaded
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
          onRefresh: fetchNotifications,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              ..._localNotifications
                  .map((notif) => _buildNotificationCard(notif)),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteNotification(String id) async {
    await Supabase.instance.client
        .from('notifications')
        .delete()
        .eq('id', id)
        .execute();

    setState(() {
      _localNotifications.removeWhere((notif) => notif['id'] == id);
    });
  }

  Widget _buildNotificationCard(Map<String, dynamic> data) {
    final timestamp = DateTime.parse(data['timestamp']);
    final dateString = "${timestamp.day.toString().padLeft(2, '0')}-"
        "${timestamp.month.toString().padLeft(2, '0')}-"
        "${timestamp.year} \n"
        "${timestamp.hour.toString().padLeft(2, '0')}:"
        "${timestamp.minute.toString().padLeft(2, '0')}";
    final cameraName = data['ip_cameras']['name'] ?? 'CAM';
    final isReviewed = data['is_reviewed'] ?? false;
    final id = data['id'];

    return Column(
      children: [
        Slidable(
          key: ValueKey(id),
          endActionPane: ActionPane(
            motion: const DrawerMotion(),
            children: [
              if (!isReviewed)
                CustomSlidableAction(
                  onPressed: (_) async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: const Color(0xFFF2F2F6),
                        title: const Text('Mark as Reviewed'),
                        content: const Text(
                            'Are you sure you want to mark this as reviewed?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () async {
                              final user =
                                  Supabase.instance.client.auth.currentUser;
                              if (user == null) return;

                              await Supabase.instance.client
                                  .from('notifications')
                                  .update({'is_reviewed': true})
                                  .eq('id', id)
                                  .execute();

                              await Supabase.instance.client
                                  .from('detection_log')
                                  .insert({
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
                  child: const Icon(Icons.verified_outlined,
                      size: 30, color: Colors.white),
                ),
              CustomSlidableAction(
                onPressed: (_) async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: const Color(0xFFF2F2F6),
                      title: const Text('Are you sure?'),
                      content: const Text(
                          'Do you really want to delete this notification?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Delete',
                              style: TextStyle(color: Color(0xFFFF0000))),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    await _deleteNotification(id);
                  }
                },
                backgroundColor: const Color(0xFFFF0000),
                child: const Icon(Icons.delete_outline_outlined,
                    size: 30, color: Colors.white),
              ),
            ],
          ),
          child: ListTile(
            dense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            leading: Icon(
              Icons.notifications_active,
              color: const Color(0xFFFF0000),
              size: 24,
            ),
            title: Text(
              "$cameraName Fire is detected",
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            subtitle: Text(
              data['message'],
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black54,
              ),
            ),
            trailing: Text(
              dateString,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black45,
              ),
            ),
          ),
        ),
        const Divider(
          height: 1,
          thickness: 0.7,
          color: Color(0xFFDDDDDD),
          indent: 16,
          endIndent: 16,
        ),
      ],
    );
  }
}
