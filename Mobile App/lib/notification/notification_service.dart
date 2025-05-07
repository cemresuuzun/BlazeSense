import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart'; // for navigatorKey

// Notification instance
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

void listenToFireNotifications() async {
  print("📡 Listening for notifications from Supabase...");

  final currentUser = Supabase.instance.client.auth.currentUser;
  if (currentUser == null) {
    print("❌ No user logged in.");
    return;
  }

  // 🔐 Step 1: Fetch activation_key_ids linked to this user
  final response = await Supabase.instance.client
      .from('activation_key_users')
      .select('activation_key_id')
      .eq('user_id', currentUser.id)
      .execute();

  if (response.data == null || (response.data is List && response.data.isEmpty)) {
    print("❌ No activation keys found for this user.");
    return;
  }

  final userKeys = (response.data as List)
      .map((e) => e['activation_key_id'].toString())
      .toList();

  print("✅ User is linked to these activation keys: $userKeys");

  // 🔥 Step 2: Listen to fire notifications
  Supabase.instance.client
      .channel('public:notifications')
      .on(
    RealtimeListenTypes.postgresChanges,
    ChannelFilter(
      event: 'INSERT',
      schema: 'public',
      table: 'notifications',
    ),
        (payload, [ref]) async {
      final newNotification = payload['new'] as Map<String, dynamic>;
      final notificationKey = newNotification['activation_key_id']?.toString();

      print("📩 Received notification for activation key: $notificationKey");

      if (notificationKey != null && userKeys.contains(notificationKey)) {
        print("🔥 Notification is for this user!");
        showFireNotification(newNotification);
      } else {
        print("🙅 Notification ignored: activation key mismatch.");
      }
    },
  )
      .subscribe();
}

// Show notification and handle dialog + DB update
Future<void> showFireNotification(Map<String, dynamic> notification) async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return;

  final settingsResponse = await Supabase.instance.client
      .from('settings')
      .select('in_app_notifications')
      .eq('user_id', user.id)
      .single();

  final inApp = settingsResponse['in_app_notifications'] ?? true;

  final android = AndroidNotificationDetails(
    'fire_channel',
    'Fire Alerts',
    channelDescription: 'Notifications for fire detections',
    importance: Importance.max,
    priority: Priority.high,
  );

  final iOS = DarwinNotificationDetails(
    sound: 'fire.caf',
  );

  final platform = NotificationDetails(
    android: android,
    iOS: iOS,
  );

  final isAppInForeground = navigatorKey.currentContext != null;

  if (isAppInForeground && inApp) {
    final context = navigatorKey.currentContext;
    const fireDetectedTitle = '🔥 Fire Detected!';

    if (context != null && context.mounted) {
      await Future.delayed(Duration.zero);

      await flutterLocalNotificationsPlugin.show(
        0,
        fireDetectedTitle,
        notification['message'] ?? 'Fire detected!',
        platform,
      );

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFFF2F2F6),
          title: const Text(fireDetectedTitle),
          content: Text(notification['message'] ?? 'Please review the fire incident.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Not Confirmed'),
            ),
            TextButton(
              onPressed: () async {
                // ✅ Mark notification as reviewed
                await Supabase.instance.client
                    .from('notifications')
                    .update({'is_reviewed': true})
                    .eq('id', notification['id'])
                    .execute();

                // ✅ Log into detection_log
                await Supabase.instance.client.from('detection_log').insert({
                  'user_id': user.id,
                  'camera_id': notification['camera_id'],
                  'confirmed': true,
                  'detected_at': notification['timestamp'],
                }).execute();

                Navigator.pop(context);
              },
              child: const Text('Mark as Reviewed'),
            ),
          ],
        ),
      );
    } else {
      print("⚠️ Could not show dialog: context is null or not mounted");
    }
  }
}

// Update user notification preference
Future<void> updateUserPreference(String key, bool value) async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return;

  await Supabase.instance.client
      .from('settings')
      .update({key: value})
      .eq('user_id', user.id);
}
