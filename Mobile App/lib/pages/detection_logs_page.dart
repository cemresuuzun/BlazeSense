import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DetectionLogsPage extends StatefulWidget {
  const DetectionLogsPage({super.key});

  @override
  State<DetectionLogsPage> createState() => _DetectionLogsPageState();
}

class _DetectionLogsPageState extends State<DetectionLogsPage> {
  List<Map<String, dynamic>> _reviewedNotifs = [];
  bool _hasLoaded = false;

  @override
  void initState() {
    super.initState();
    fetchReviewedNotifications();
  }

  Future<void> fetchReviewedNotifications() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;

    if (userId == null || userId.isEmpty) {
      setState(() => _hasLoaded = true);
      return;
    }

    final response = await Supabase.instance.client
        .from('notifications')
        .select('id, message, timestamp, ip_cameras!fk_notifications_camera(name)')
        .eq('user_id', userId)
        .eq('is_reviewed', true)
        .order('timestamp', ascending: false)
        .execute();


    setState(() {
      _reviewedNotifs = List<Map<String, dynamic>>.from(response.data ?? []);
      _hasLoaded = true;
    });
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
          : ListView.builder(
        itemCount: _reviewedNotifs.length,
        itemBuilder: (context, index) {
          final data = _reviewedNotifs[index];
          final timestamp = DateTime.parse(data['timestamp']);
          final cameraName = data['ip_cameras']['name'] ?? 'CAM';
          final dateString =
              "${timestamp.day.toString().padLeft(2, '0')}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.year}";

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              color: Colors.grey.shade200,
              child: ListTile(
                leading: const Icon(Icons.verified, color: Colors.green),
                title: Text("$cameraName  Fire reviewed"),
                subtitle: Text(data['message']),
                trailing: Text(dateString),
              ),
            ),
          );
        },
      ),
    );
  }
}
