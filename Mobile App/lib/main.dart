import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:flutterilk/pages/login_register.dart';
import 'package:flutterilk/pages/main_page.dart';
import 'package:flutterilk/notification/notification_service.dart';
import 'package:flutterilk/notification/notification_service.dart';


//notification widget herhangi bir yerde açılabilsin diye eklenen navigator variable
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

Future<void> setupNotifications() async {
  const iosSettings = DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );

  const settings = InitializationSettings(
    iOS: iosSettings,
    android: AndroidInitializationSettings('@mipmap/ic_launcher'),
  );

  await flutterLocalNotificationsPlugin.initialize(settings);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://lxdxswcfjyxbiyofvwkt.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imx4ZHhzd2Nmanl4Yml5b2Z2d2t0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDE3Nzc1MjksImV4cCI6MjA1NzM1MzUyOX0.xMDumCcc9QssCQPR77PThnMFPltLbroiav7NNv9OsZA',
  );
  await setupNotifications();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      title: 'BlazeSense',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
        useMaterial3: true,
      ),
      home: const SplashGate(),
    );
  }
}

class SplashGate extends StatefulWidget {
  const SplashGate({super.key});

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> {
  bool _checkingSession = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkSession();
    checkUnreviewedNotifications(); //  Check for fire review!
    listenToFireNotifications(); //  Real-time fire alert
  }

  Future<void> _checkSession() async {
    final session = Supabase.instance.client.auth.currentSession;

    // Optional smooth transition delay
    await Future.delayed(const Duration(milliseconds: 500));

    setState(() {
      _isLoggedIn = session != null;
      _checkingSession = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingSession) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return _isLoggedIn ? const MainPage() : const LoginRegisterPage();
  }
}
Future<void> checkUnreviewedNotifications() async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return;

  final response = await Supabase.instance.client
      .from('notifications')
      .select()
      .eq('user_id', user.id)
      .eq('is_reviewed', false)
      .order('timestamp', ascending: false)
      .limit(1)
      .maybeSingle();

  if (response != null) {
    // Show dialog to review
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: navigatorKey.currentContext!,
        builder: (context) {
          return AlertDialog(
            title: const Text('🚨 Fire Detected!'),
            content: const Text('Please review the fire incident.'),
            actions: [
              TextButton(
                child: const Text('Dismiss'),
                onPressed: () => Navigator.pop(context),
              ),
              TextButton(
                child: const Text('Mark as Reviewed'),
                onPressed: () async {
                  await Supabase.instance.client
                      .from('notifications')
                      .update({'is_reviewed': true})
                      .eq('id', response['id'])
                      .execute();

                  // Optional: insert into detection_log
                  await Supabase.instance.client
                      .from('detection_log')
                      .insert({
                    'user_id': user.id,
                    'camera_id': response['camera_id'],
                    'confirmed': true,
                    'detected_at': response['timestamp'],
                  })
                      .execute();

                  Navigator.pop(context);
                },
              ),
            ],
          );
        },
      );
    });
  }
}
