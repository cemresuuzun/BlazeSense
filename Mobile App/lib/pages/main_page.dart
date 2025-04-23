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
import '../main.dart';
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
    CameraView(),
    NotificationLogPage(key: notificationLogKey),
    const ChangeViewPage(),
    const DetectionLogsPage(),
    const SettingsPage(),
  ];

  // Logout işlemi için onay isteyen fonksiyon
  Future<void> _handleLogout(BuildContext context) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to log out?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Log out", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await AuthService().signOut();
      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginRegisterPage()),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();

    listenToFireNotifications();

    final supabase = Supabase.instance.client;
  }

  @override
  void dispose() {
    Supabase.instance.client.removeChannel(detectionChannel);
    Supabase.instance.client.removeChannel(notificationChannel);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    //  EKLENDİ: İkonlar ve label listeleri tanımlandı (daha okunabilir ve özelleştirilebilir yapı için)
    List<IconData> icons = [
      Icons.home,
      Icons.notifications,
      Icons.add,
      Icons.warning,
      Icons.settings,
    ];

    List<String> labels = [
      'Main',
      'Notifications',
      '',
      'Detection',
      'Settings',
    ];

    return Scaffold(
      /*
      appBar: AppBar(
        title: Text(
          AuthService().currentUser?.email ?? 'User',
          style: const TextStyle(fontSize: 16),
        ),
        centerTitle: true, // ✅ Başlığı tam ortaya alır
        actions: [
          // 🔴 Logout butonu sağ köşeye alındı
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: () =>
                _handleLogout(context), // Çıkış yaparken onay sorulacak
          ),
        ],
      ),*/
      body: _pages[_selectedIndex],
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          splashFactory: NoSplash.splashFactory,
          highlightColor: Colors.transparent,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFFFF0000),
          ),
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            currentIndex: _selectedIndex,
            selectedItemColor: Color(0xFFFF0000),
            unselectedItemColor: Colors.black45,
            showUnselectedLabels: true,
            selectedLabelStyle: const TextStyle(
              fontSize: 12,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 12,
            ),
            onTap: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            items: List.generate(icons.length, (index) {
              if (index == 2) {
                // Middle Add button with circle
                return BottomNavigationBarItem(
                  icon: Container(
                    margin: const EdgeInsets.only(top: 11),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey.shade300, // Lighter than black45
                    ),
                    child: Icon(
                      icons[index],
                      size: 28,
                      color: Colors.black, // You can customize this
                    ),
                  ),
                  label: '', // No label for the Add button
                );
              } else {
                return BottomNavigationBarItem(
                  icon: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 8),
                      Icon(icons[index]),
                      Container(height: 5),
                    ],
                  ),
                  label: labels[index],
                );
              }
            }),
          ),
        ),
      ),
    );
  }
}
