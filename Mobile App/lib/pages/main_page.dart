// ✅ Merged MainPage from camera view logic and deep link / Supabase channel logic
import 'package:flutter/material.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
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
import 'package:flutterilk/pages/device_notifier.dart';
import 'package:flutter/services.dart';


class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> cameras = [];
  int currentCameraIndex = 0;
  VlcPlayerController? _videoPlayerController;
  bool isLoading = true;
  String? errorMessage;
  int _selectedIndex = 0;

  late RealtimeChannel detectionChannel;
  late RealtimeChannel notificationChannel;

  final List<Widget> _pages = [
    const SizedBox(),
    NotificationLogPage(),
    const ChangeViewPage(),
    const DetectionLogsPage(),
    const SettingsPage(),
  ];

  @override
  void initState() {
    super.initState();
    listenToFireNotifications();
    _initializeChannels();
    loadCameras();
    deviceChangeNotifier.addListener(_onDeviceChanged);
    AuthService().ensureBackendNotifiedOnStartup();
  }

  void _onDeviceChanged() {
    if (mounted) {
      loadCameras();
    }
  }

  @override
  void dispose() {
    deviceChangeNotifier.removeListener(_onDeviceChanged);
    _videoPlayerController?.dispose();
    detectionChannel.unsubscribe();
    notificationChannel.unsubscribe();
    super.dispose();
  }

  void _initializeChannels() {
    detectionChannel = Supabase.instance.client.channel('detection_channel');
    notificationChannel = Supabase.instance.client.channel('notification_channel');

    detectionChannel.subscribe();
    notificationChannel.subscribe();
  }

  Future<void> loadCameras() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      // Step 1: Get activation_key_id from users table
      final userRow = await supabase
          .from('users')
          .select('activation_key_id')
          .eq('id', user.id)
          .single();

      final activationKeyId = userRow['activation_key_id'];
      if (activationKeyId == null) throw Exception('No activation key found');

      // Step 2: Fetch cameras by activation_key_id
      final response = await supabase
          .from('ip_cameras')
          .select()
          .eq('activation_key_id', activationKeyId)
          .order('created_at');

      final newCameras = (response as List).cast<Map<String, dynamic>>();

      if (newCameras.isEmpty) {
        await _videoPlayerController?.dispose();
        setState(() {
          cameras = [];
          currentCameraIndex = 0;
          _videoPlayerController = null;
        });
      } else {
        int newIndex = currentCameraIndex >= newCameras.length ? 0 : currentCameraIndex;
        setState(() {
          cameras = newCameras;
          currentCameraIndex = newIndex;
        });
        initializePlayer(newIndex);
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load cameras: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }


  Future<void> initializePlayer(int index) async {
    if (cameras.isEmpty || index >= cameras.length) return;

    setState(() {
      isLoading = true;
    });

    // Dispose the old controller and wait for it to finish
    if (_videoPlayerController != null) {
      await _videoPlayerController!.dispose();
      _videoPlayerController = null;
      // Add a short delay to ensure resources are released
      await Future.delayed(const Duration(milliseconds: 200));
    }

    final camera = cameras[index];
    final rtspUrl = camera['ip_address'] as String;

    _videoPlayerController = VlcPlayerController.network(
      rtspUrl,
      hwAcc: HwAcc.full,
      autoPlay: true,
      options: VlcPlayerOptions(
        advanced: VlcAdvancedOptions([
          VlcAdvancedOptions.networkCaching(2000),
        ]),
        rtp: VlcRtpOptions([
          VlcRtpOptions.rtpOverRtsp(true),
        ]),
      ),
    );

    setState(() {
      currentCameraIndex = index;
      isLoading = false;
    });
  }

  void switchCamera(int index) {
    if (isLoading) return; // Prevent switching while loading
    if (index != currentCameraIndex && index < cameras.length) {
      initializePlayer(index);
    }
  }

  Widget _buildCameraView() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (cameras.isEmpty || currentCameraIndex >= cameras.length) {
      return Column(
        children: [
          Container(
            height: MediaQuery.of(context).size.height * 0.4,
            color: Colors.black,
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.videocam_off, color: Colors.white54, size: 48),
                  SizedBox(height: 16),
                  Text(
                    'No cameras available',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  Text(
                    'Add a camera to start monitoring',
                    style: TextStyle(color: Colors.white54, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }
    return Column(
      children: [
        Container(
          height: MediaQuery.of(context).size.height * 0.4,
          color: Colors.black,
          child: Stack(
            children: [
              SizedBox.expand(
                child: _videoPlayerController != null
                    ? VlcPlayer(controller: _videoPlayerController!, aspectRatio: 16 / 9)
                    : const Center(child: CircularProgressIndicator()),
              ),
              Positioned(
                top: 16,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    cameras[currentCameraIndex]['name'] ?? 'Camera',
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
        if (cameras.length > 1 && currentCameraIndex < cameras.length)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: cameras.length == 5
                ? Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(4, (index) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: ElevatedButton(
                            onPressed: isLoading ? null : () => switchCamera(index),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: currentCameraIndex == index ? const Color(0xFF555555) : Colors.white,
                              foregroundColor: currentCameraIndex == index ? Colors.white : const Color(0xFF555555),
                              shape: const CircleBorder(),
                              minimumSize: const Size(50, 50),
                              elevation: 0,
                            ),
                            child: Text('${index + 1}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          ),
                        )),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: ElevatedButton(
                              onPressed: isLoading ? null : () => switchCamera(4),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: currentCameraIndex == 4 ? const Color(0xFF555555) : Colors.white,
                                foregroundColor: currentCameraIndex == 4 ? Colors.white : const Color(0xFF555555),
                                shape: const CircleBorder(),
                                minimumSize: const Size(50, 50),
                                elevation: 0,
                              ),
                              child: const Text('5', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      cameras.length,
                      (index) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: ElevatedButton(
                          onPressed: isLoading ? null : () => switchCamera(index),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: currentCameraIndex == index ? const Color(0xFF555555) : Colors.white,
                            foregroundColor: currentCameraIndex == index ? Colors.white : const Color(0xFF555555),
                            shape: const CircleBorder(),
                            minimumSize: const Size(50, 50),
                            elevation: 0,
                          ),
                          child: Text('${index + 1}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                  ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    List<IconData> icons = [Icons.home, Icons.notifications, Icons.add, Icons.warning, Icons.settings];
    List<String> labels = ['Main', 'Notifications', '', 'Detection', 'Settings'];

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F6),
      body: Container(
        color: _selectedIndex == 0 ? const Color(0xFF282828) : const Color(0xFFF2F2F6),
        child: SafeArea(
          child: Column(
            children: [
              if (_selectedIndex == 0)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'LIVE',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F2F6),
                    borderRadius: _selectedIndex == 0
                        ? const BorderRadius.vertical(top: Radius.circular(20))
                        : null,
                  ),
                  child: IndexedStack(
                    index: _selectedIndex,
                    children: [_buildCameraView(), ..._pages.sublist(1)],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          splashFactory: NoSplash.splashFactory,
          highlightColor: Colors.transparent,
        ),
        child: Container(
          decoration: const BoxDecoration(color: Colors.white),
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