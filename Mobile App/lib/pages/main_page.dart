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
import 'package:flutterilk/pages/ip_camera_view.dart';
import 'package:flutterilk/pages/reset_password_page.dart';
import 'package:uni_links/uni_links.dart'; // Deep link işlemleri için import

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
    IPCameraView(),
    NotificationLogPage(),  // notificationLogKey'i kaldırdım
    const ChangeViewPage(),
    const DetectionLogsPage(),
    const SettingsPage(),
  ];

  @override
  void initState() {
    super.initState();
    listenToFireNotifications();
    _initializeChannels();
    _initDeepLink(); // Deep link için başlatma
  }

  // Deep link başlatma işlemi
  void _initDeepLink() async {
    try {
      // İlk başta gelen link
      final initialLink = await getInitialLink();
      if (initialLink != null) {
        _handleDeepLink(initialLink); // İlk gelen linki işle
      }

      // Uygulama açıkken gelen deep link'leri dinleme
      linkStream.listen((String? link) {
        if (link != null) {
          _handleDeepLink(link); // Gelen linki işle
        }
      });
    } catch (e) {
      debugPrint('Error handling deep link: $e');
    }
  }

  // Deep link işleme
  void _handleDeepLink(String link) {
    final uri = Uri.parse(link);
    debugPrint('Deep Link URI: $uri');

    if (uri.scheme == 'blazesense' && uri.host == 'reset-password') {
      final refreshToken = uri.queryParameters['refresh_token'] ?? '';
      debugPrint('Refresh Token: $refreshToken');

      // Eğer refresh token varsa, ResetPasswordPage'e yönlendir
      if (refreshToken.isNotEmpty && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => ResetPasswordPage(refreshToken: refreshToken),
            ),
          );
        });
      }
    }
  }

  // Supabase kanallarını başlatma
  void _initializeChannels() {
    detectionChannel = Supabase.instance.client.channel('detection_channel');
    notificationChannel = Supabase.instance.client.channel('notification_channel');

    detectionChannel.subscribe();
    notificationChannel.subscribe();
  }

  // Uygulama içerisinde çıkış yapma işlemi
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
  void dispose() {
    detectionChannel.unsubscribe();
    notificationChannel.unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            selectedItemColor: const Color(0xFFFF0000),
            unselectedItemColor: Colors.black45,
            showUnselectedLabels: true,
            selectedLabelStyle: const TextStyle(fontSize: 12),
            unselectedLabelStyle: const TextStyle(fontSize: 12),
            onTap: (index) => setState(() => _selectedIndex = index),
            items: List.generate(icons.length, (index) {
              if (index == 2) {
                return BottomNavigationBarItem(
                  icon: Container(
                    margin: const EdgeInsets.only(top: 11),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey.shade300,
                    ),
                    child: Icon(icons[index], size: 28, color: Colors.black),
                  ),
                  label: '',
                );
              }
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
            }),
          ),
        ),
      ),
    );
  }
}
