import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vibration/vibration.dart';
import '../main.dart'; // to access navigatorKey from main.dart

//Notification göndermek için variable
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

// Listen for fire notifications
void listenToFireNotifications() {
  print("📡 Listening for notifications from Supabase...");
  final channel = Supabase.instance.client
      .channel('public:notifications')
      .on(
    RealtimeListenTypes.postgresChanges,
    ChannelFilter(
      event: 'INSERT',
      schema: 'public',
      table: 'notifications',
    ),
        (payload, [ref]) {
      final message = payload['new']['message'] ?? 'New notification';
      print("🔥 New notification received: $message");
      showFireNotification(message);
    },
  )
      .subscribe();
}

// Notification göstermek için kullandığımız fonksiyon, user setting seçeneklerini seçip ona göre gösteriyor
Future<void> showFireNotification(String message) async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return;

  final settingsResponse = await Supabase.instance.client
      .from('settings')
      .select('in_app_notifications, sound_enabled, vibration_enabled')
      .eq('user_id', user.id)
      .single();

  final inApp = settingsResponse['in_app_notifications'] ?? true;
  final sound = settingsResponse['sound_enabled'] ?? true;
  final vibrate = settingsResponse['vibration_enabled'] ?? false;

  final android = AndroidNotificationDetails(
    'fire_channel',
    'Fire Alerts',
    channelDescription: 'Notifications for fire detections',
    importance: Importance.max,
    priority: Priority.high,
    playSound: sound,
  );

  final platform = NotificationDetails(android: android);

  //  App is in foreground
  final isAppInForeground = navigatorKey.currentContext != null;

  if (isAppInForeground && inApp) {
    final context = navigatorKey.currentContext;

    if (context != null && context.mounted) {
      // ✨ Ensures the dialog waits for a clean frame
      await Future.delayed(Duration.zero);

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('🔥 Fire Detected!'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } else {
      print("⚠️ Could not show dialog: context is null or not mounted");
    }
  } else {
    // ✅ App is in background — show standard notification
    await flutterLocalNotificationsPlugin.show(
      0,
      '🔥 Fire Detected!',
      message,
      platform,
    );
  }

  //  Vibration (if enabled)
  final hasVibrator = await Vibration.hasVibrator();
  if (vibrate && hasVibrator == true) {
    if (await Vibration.hasAmplitudeControl() ?? false) {
      Vibration.vibrate(duration: 700, amplitude: 128);
    } else {
      Vibration.vibrate(duration: 700);
    }
  }
}

// 🔧 Update user setting
Future<void> updateUserPreference(String key, bool value) async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return;

  await Supabase.instance.client
      .from('settings')
      .update({key: value})
      .eq('user_id', user.id);
}
