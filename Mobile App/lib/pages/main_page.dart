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
    // 🔥 EKLENDİ: İkonlar ve label listeleri tanımlandı (daha okunabilir ve özelleştirilebilir yapı için)
    List<IconData> icons = [
      Icons.home_rounded,
      Icons.notifications,
      Icons.swap_horiz,
      Icons.warning,
      Icons.settings,
    ];

    List<String> labels = [
      'Main',
      'Notifications',
      'Change View',
      'Detection',
      'Settings',
    ];

    return Scaffold(
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
            onPressed: () => _handleLogout(context), // Çıkış yaparken onay sorulacak
          ),
        ],
      ),
      body: _pages[_selectedIndex],

      // 🔥 GÜNCELLENDİ: Yeni animasyonlu ve modern BottomNavigationBar
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.red,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white, // 🔥 Arka plan kırmızı yapıldı
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.red,
          unselectedItemColor: Colors.black45,
          showUnselectedLabels: true,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          items: List.generate(icons.length, (index) {
            return BottomNavigationBarItem(
              icon: AnimatedContainer( // 🔥 Seçilen item için animasyonlu gösterge
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.only(top: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icons[index]),
                    const SizedBox(height: 4),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: 4,
                      width: _selectedIndex == index ? 20 : 0,
                      decoration: BoxDecoration(
                        color: Colors.red, // 🔥 Alt çizgi beyaz
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
              ),
              label: labels[index],
            );
          }),
        ),
      ),
    );
  }
}
