import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutterilk/pages/manage_devices_page.dart';

class ChangeViewPage extends StatefulWidget {
  final void Function()? onDevicesChanged;
  const ChangeViewPage({super.key, this.onDevicesChanged});

  @override
  State<ChangeViewPage> createState() => _ChangeViewPageState();
}

class _ChangeViewPageState extends State<ChangeViewPage> {
  final SupabaseClient supabase = Supabase.instance.client;
  final TextEditingController cameraNameController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController camIpController = TextEditingController();

  bool isLoading = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
  }

  String constructRtspUrl(String username, String password, String ipAddress) {
    return "rtsp://$username:$password@$ipAddress:554/Streaming/Channels/101";
  }

  Widget _buildField(String label, TextEditingController controller, IconData icon, {bool isPassword = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: const Color(0xFF333333)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }

  Future<void> addDevice() async {
    final cameraName = cameraNameController.text.trim();
    final username = usernameController.text.trim();
    final password = passwordController.text.trim();
    final camIp = camIpController.text.trim();

    if (cameraName.isEmpty || username.isEmpty || password.isEmpty || camIp.isEmpty) {
      setState(() {
        errorMessage = 'All fields are required.';
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      final activationKeyRow = await supabase
          .from('users')
          .select('activation_key_id')
          .eq('id', user.id)
          .maybeSingle();

      if (activationKeyRow == null || activationKeyRow['activation_key_id'] == null) {
        throw Exception('Activation key not found');
      }

      final activationKeyId = activationKeyRow['activation_key_id'];

      final cameras = await supabase
          .from('ip_cameras')
          .select('id')
          .eq('activation_key_id', activationKeyId);

      if (cameras.length >= 5) {
        setState(() {
          errorMessage = 'You can only add up to 5 cameras.';
        });
        return;
      }

      final rtspUrl = constructRtspUrl(username, password, camIp);

      await supabase.from('ip_cameras').insert({
        'activation_key_id': activationKeyId,
        'user_id': user.id,
        'name': cameraName,
        'ip_address': rtspUrl,
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Camera added successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to add camera: $e';
      });
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF282828),
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF2F2F6),
        appBar: AppBar(
          title: const Text('Add Device'),
          backgroundColor: const Color(0xFF282828),
          foregroundColor: Colors.white,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _buildField('Camera Name', cameraNameController, Icons.videocam),
              _buildField('Username', usernameController, Icons.camera_alt),
              _buildField('Password', passwordController, Icons.lock, isPassword: true),
              _buildField('Cam IP', camIpController, Icons.link),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: isLoading ? null : addDevice,
                child: Container(
                  width: double.infinity,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF0000),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: isLoading
                        ? const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF555555)),
                    )
                        : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Add Device',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ManageDevicesPage(
                        onDevicesChanged: widget.onDevicesChanged,
                      ),
                    ),
                  );
                },
                child: Container(
                  width: double.infinity,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.settings, color: Color(0xFF555555)),
                        SizedBox(width: 10),
                        Text(
                          'Manage Devices',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFF555555),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (errorMessage != null) ...[
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    errorMessage!,
                    style: const TextStyle(
                      color: Color(0xFFFF0000),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
