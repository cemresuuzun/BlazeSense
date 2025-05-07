import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';

class DetectionLogsPage extends StatefulWidget {
  const DetectionLogsPage({super.key});

  @override
  State<DetectionLogsPage> createState() => DetectionLogsPageState();
}

class DetectionLogsPageState extends State<DetectionLogsPage> {
  List<Map<String, dynamic>> _reviewedNotifs = [];
  bool _hasLoaded = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Color(0xFF282828),
      statusBarIconBrightness: Brightness.light,
    ));
    fetchReviewedNotifications();
  }

  Future<void> fetchReviewedNotifications() async {
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      if (!mounted) return;
      setState(() => _hasLoaded = true);
      return;
    }

    try {
      final userRow = await Supabase.instance.client
          .from('users')
          .select('activation_key_id')
          .eq('id', user.id)
          .single();

      final activationKeyId = userRow['activation_key_id'];
      if (activationKeyId == null) throw Exception('No activation key found');

      final cameraRows = await Supabase.instance.client
          .from('ip_cameras')
          .select('id')
          .eq('activation_key_id', activationKeyId);

      final cameraIds = cameraRows.map((cam) => cam['id']).toList();

      if (cameraIds.isEmpty) {
        setState(() {
          _reviewedNotifs = [];
          _hasLoaded = true;
        });
        return;
      }

      final response = await Supabase.instance.client
          .from('notifications')
          .select('id, message, timestamp, video_url, ip_cameras(id, name)')
          .in_('camera_id', cameraIds)
          .eq('is_reviewed', true)
          .order('timestamp', ascending: false);

      if (!mounted) return;

      setState(() {
        _reviewedNotifs = List<Map<String, dynamic>>.from(response);
        _hasLoaded = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hasLoaded = true;
        _reviewedNotifs = [];
      });
      print("❌ Error fetching reviewed notifications: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Detection Log'),
        backgroundColor: const Color(0xFF282828),
        foregroundColor: Colors.white,
      ),
      body: !_hasLoaded
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: fetchReviewedNotifications,
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: _reviewedNotifs.length,
          itemBuilder: (context, index) {
            final data = _reviewedNotifs[index];
            final timestamp = DateTime.parse(data['timestamp']);
            final cameraName = data['ip_cameras']['name'] ?? 'CAM';
            final dateString =
                "${timestamp.day.toString().padLeft(2, '0')}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.year}\n"
                "${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}";

            return Column(
              children: [
                ListTile(
                  onTap: () {
                    final videoUrl = data['video_url'];
                    if (videoUrl != null && videoUrl.isNotEmpty) {
                      showDialog(
                        context: context,
                        builder: (_) => VideoDialog(videoUrl: videoUrl),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('No video available for this detection')),
                      );
                    }
                  },
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  leading: const Icon(
                    Icons.warning,
                    color: Color(0xFFFF0000),
                    size: 24,
                  ),
                  title: Text(
                    "$cameraName  Fire reviewed",
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  subtitle: Text(
                    data['message'],
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black54,
                    ),
                  ),
                  trailing: Text(
                    dateString,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black45,
                    ),
                  ),
                ),
                const Divider(
                  height: 1,
                  thickness: 0.7,
                  color: Color(0xFFDDDDDD),
                  indent: 16,
                  endIndent: 16,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class VideoDialog extends StatefulWidget {
  final String videoUrl;

  const VideoDialog({super.key, required this.videoUrl});

  @override
  State<VideoDialog> createState() => _VideoDialogState();
}

class _VideoDialogState extends State<VideoDialog> {
  late VlcPlayerController _vlcController;

  @override
  void initState() {
    super.initState();
    _vlcController = VlcPlayerController.network(
      widget.videoUrl,
      hwAcc: HwAcc.full,
      autoPlay: true,
      options: VlcPlayerOptions(),
    );
  }

  @override
  void dispose() {
    _vlcController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFFF2F2F6),
      content: AspectRatio(
        aspectRatio: 16 / 9,
        child: VlcPlayer(
          controller: _vlcController,
          aspectRatio: 16 / 9,
          placeholder: const Center(child: CircularProgressIndicator()),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        )
      ],
    );
  }
}
