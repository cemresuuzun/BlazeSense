import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutterilk/pages/change_view_page.dart';
import 'package:flutterilk/pages/detection_logs_page.dart';
import 'package:flutterilk/pages/login_register.dart';
import 'package:flutterilk/pages/notification_logs_page.dart';
import 'package:flutterilk/pages/profile_page.dart';
import 'package:flutterilk/pages/settings_page.dart';
import 'package:flutterilk/notification/notification_service.dart';
import 'package:flutterilk/service/auth.dart';
import 'package:camera/camera.dart';

import 'camera_view.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;
  late RealtimeChannel detectionChannel;
  late RealtimeChannel notificationChannel;

  final List<Widget> _pages = [
    CameraView(), // 👈 this is your beautiful camera UI
    const NotificationLogPage(),
    const ChangeViewPage(),
    const DetectionLogsPage(),
    const SettingsPage(),
  ];

  Future<void> _handleLogout() async {
    await AuthService().signOut();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginRegisterPage()),
      );
    }
  }

  @override
  void initState() {
    super.initState();

    listenToFireNotifications(); // ✅ 👈 Add this!

    final supabase = Supabase.instance.client;

    detectionChannel = supabase.channel('public:detection_log');
    detectionChannel
        .on(
      RealtimeListenTypes.postgresChanges,
      ChannelFilter(
        event: 'INSERT',
        schema: 'public',
        table: 'notifications',
      ),
          (payload, [ref]) {
        if (!mounted) return;

        final dynamic cam = payload['new']['camera_id'];
        final String msg = '🔥 Fire detected on camera $cam';
        final String id = payload['new']['id']; // 👈 this is your notificationId

        showFireNotification(msg); // ✅
      },
    )

        .subscribe();

    notificationChannel = supabase.channel('public:notifications');

    notificationChannel
        .on(
      RealtimeListenTypes.postgresChanges,
      ChannelFilter(event: 'INSERT', schema: 'public', table: 'notifications'),
          (payload, [ref]) {
        if (!mounted) return;

        final String msg = payload['new']['message'] ?? 'New notification';
        final String id = payload['new']['id']; // 🔥 this is the UUID you need

        showFireNotification(msg);
      },
    )
        .subscribe();

  }


  @override
  void dispose() {
    Supabase.instance.client.removeChannel(detectionChannel);
    Supabase.instance.client.removeChannel(notificationChannel);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.logout),
          onPressed: _handleLogout,
        ),

        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              AuthService().currentUser?.email ?? 'User',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              // You can expand this for a drawer or settings
            },
          ),
        ],
        centerTitle: true,
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Main'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Notifications'),
          BottomNavigationBarItem(icon: Icon(Icons.swap_horiz), label: 'Change View'),
          BottomNavigationBarItem(icon: Icon(Icons.warning), label: 'Detection'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}
