import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart'; // for navigatorKey

// Notification instance
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

// Listen to fire notifications
void listenToFireNotifications() {
  print("📡 Listening for notifications from Supabase...");
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

      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) return;

      // ✅ Filter for this user only
      if (newNotification['user_id'] == currentUser.id) {
        final message = newNotification['message'] ?? 'New fire alert';
        print("🔥 New notification received for this user: $message");
        showFireNotification(newNotification);
      } else {
        print("🙅 Notification is not for this user. Ignored.");
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
          title: const Text(fireDetectedTitle),
          content: Text(notification['message'] ?? 'Please review the fire incident.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Dismiss'),
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
