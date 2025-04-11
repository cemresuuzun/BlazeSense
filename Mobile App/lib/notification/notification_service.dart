import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vibration/vibration.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';


final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();


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
      print("🔥 New notification received: $message"); // 👈 add this!
      showFireNotification(message);
    },
  )
      .subscribe();
}

Future<void> showFireNotification(String message) async {
  const android = AndroidNotificationDetails(
    'fire_channel',
    'Fire Alerts',
    channelDescription: 'Notifications for fire detections',
    importance: Importance.max,
    priority: Priority.high,
  );

  const platform = NotificationDetails(android: android);

  // ✅ Show the notification
  await flutterLocalNotificationsPlugin.show(
    0,
    '🔥 Fire Detected!',
    message,
    platform,
  );

  // ✅ Check if vibration is enabled
  final shouldVibrate = await isVibrationEnabled();

  final hasVibrator = await Vibration.hasVibrator();
  if (shouldVibrate && hasVibrator == true) {
    if (await Vibration.hasAmplitudeControl() ?? false) {
      Vibration.vibrate(duration: 700, amplitude: 128);
    } else {
      Vibration.vibrate(duration: 700);
    }
  }
}

Future<bool> isVibrationEnabled() async {
  final user = Supabase.instance.client.auth.currentUser;

  if (user == null) return false;

  final response = await Supabase.instance.client
      .from('users')
      .select('vibration_enabled')
      .eq('id', user.id)
      .single();

  return response['vibration_enabled'] ?? false;
}