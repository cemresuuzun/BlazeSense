import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutterilk/pages/device_notifier.dart';

class ManageDevicesPage extends StatefulWidget {
  final void Function()? onDevicesChanged;
  const ManageDevicesPage({super.key, this.onDevicesChanged});

  @override
  State<ManageDevicesPage> createState() => _ManageDevicesPageState();
}

class _ManageDevicesPageState extends State<ManageDevicesPage> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> devices = [];
  bool isLoading = true;
  String? errorMessage;
  bool deviceDeleted = false;

  @override
  void initState() {
    super.initState();
    fetchDevices();
  }

  Future<void> fetchDevices() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      // Step 1: Fetch activation_key_id from users table
      final userData = await supabase
          .from('users')
          .select('activation_key_id')
          .eq('id', user.id)
          .single();

      final activationKeyId = userData['activation_key_id'];
      if (activationKeyId == null) throw Exception('User has no activation key assigned');

      // Step 2: Fetch devices by activation_key_id
      final response = await supabase
          .from('ip_cameras')
          .select()
          .eq('activation_key_id', activationKeyId)
          .order('created_at');

      devices = (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      errorMessage = 'Failed to load devices: $e';
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }


  Future<void> deleteDevice(int index) async {
    final device = devices[index];
    final deviceId = device['id'];
    try {
      await supabase.from('ip_cameras').delete().eq('id', deviceId);
      deviceChangeNotifier.value++;
      if (widget.onDevicesChanged != null) {
        widget.onDevicesChanged!();
      }
      Navigator.of(context).pop(true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete device: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void confirmDelete(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Device'),
        content: const Text('Are you sure you want to delete this device?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await deleteDevice(index);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Devices'),
        backgroundColor: const Color(0xFF333333),
        foregroundColor: Colors.white,
      ),
      backgroundColor: const Color(0xFFF2F2F6),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(child: Text(errorMessage!))
              : devices.isEmpty
                  ? const Center(child: Text('No devices found.'))
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: devices.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final device = devices[index];
                        final name = device['name'] ?? 'Unnamed';
                        final createdAt = device['created_at'] != null
                            ? DateTime.tryParse(device['created_at'])
                            : null;
                        final dateStr = createdAt != null
                            ? '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')}'
                            : 'Unknown';
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('Added: $dateStr'),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => confirmDelete(index),
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
} 