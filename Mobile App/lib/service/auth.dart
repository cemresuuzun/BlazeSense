import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _client = Supabase.instance.client;
  final String backendBaseUrl = "http://localhost:8000"; // Change if deployed

  // ✅ Sign Up
  Future<AuthResponse> signUp({required String email, required String password}) async {
    final response = await _client.auth.signUp(email: email, password: password);

    // Optionally fetch camera info
    if (response.user != null) {
      await fetchAndPrintCameraInfo(response.user!.id);
    }

    return response;
  }

  // ✅ Sign In
  Future<AuthResponse> signIn({required String email, required String password}) async {
    final response = await _client.auth.signInWithPassword(email: email, password: password);

    if (response.user != null) {
      final userId = response.user!.id;

      // Step 1: Fetch activation key from Supabase
      try {
        print("🔍 Fetching activation key for userId: $userId");

        final userData = await _client
            .from('users')
            .select('activation_key_id')
            .eq('id', userId)
            .maybeSingle()
            .timeout(const Duration(seconds: 10), onTimeout: () {
          throw Exception("🔥 Supabase query timeout");
        });

        final activationKeyId = userData?['activation_key_id'];
        if (activationKeyId == null) {
          print("❌ User has no activation_key_id.");
          return response;
        }

        // Step 2: Notify Python backend
        try {
          print("📡 Notifying backend with activationKeyId: $activationKeyId");
          await notifyBackendWithActivationKey(activationKeyId).timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception("🚨 Backend notification timed out");
            },
          );
        } catch (e) {
          print("⚠️ Could not notify backend: $e");
          // Optionally: Show error or let user proceed anyway
        }

      } catch (e) {
        print("❌ Failed to fetch user data or notify backend: $e");
        // Optional: You can throw here or allow login to continue
      }
    }

    return response;
  }

  // ✅ Sign Out
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  // ✅ Reset Password Flow
  Future<void> sendPasswordResetEmail(String email) async {
    await _client.auth.resetPasswordForEmail(
      email,
      redirectTo: 'io.supabase.flutter://reset-callback/',
    );
  }

  Future<void> updatePasswordWithToken({
    required String email,
    required String token,
    required String newPassword,
  }) async {
    await _client.auth.verifyOTP(
      type: OtpType.recovery,
      token: token,
      email: email,
    );

    await _client.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }

  // ✅ Notify Backend with Activation Key
  Future<void> notifyBackendWithActivationKey(String activationKeyId) async {
    final url = Uri.parse('$backendBaseUrl/update-activation');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"activation_key_id": activationKeyId}),
    );

    if (response.statusCode == 200) {
      print("✅ Activation key sent to backend.");
    } else {
      print("❌ Error sending activation key: ${response.body}");
    }
  }

  // ✅ Fetch and Print Camera Info (Optional/Debug)
  Future<void> fetchAndPrintCameraInfo(String userId) async {
    try {
      final userRow = await _client
          .from('users')
          .select('activation_key_id')
          .eq('id', userId)
          .single();

      final activationKeyId = userRow['activation_key_id'];
      if (activationKeyId == null) {
        print("❌ User has no activation_key_id.");
        return;
      }

      final url = Uri.parse('$backendBaseUrl/camera-info/$activationKeyId');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final cameras = data['cameras'];

        if (cameras.isEmpty) {
          print("🚫 No cameras found.");
          return;
        }

        final firstCamera = cameras[0];
        print("✅ Backend user ID: ${data['user_id']}");
        print("📷 Camera ID: ${firstCamera['id']}");
        print("🌐 Camera IP: ${firstCamera['ip_address']}");
      } else {
        print("❌ Backend error: ${response.body}");
      }
    } catch (e) {
      print("❌ Exception while fetching camera info: $e");
    }
  }

  // ✅ Getters
  User? get currentUser => _client.auth.currentUser;
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;
}
