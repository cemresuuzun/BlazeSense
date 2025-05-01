import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _client = Supabase.instance.client;

  // 🔐 Sign up user
  Future<AuthResponse> signUp({required String email, required String password}) async {
    return await _client.auth.signUp(email: email, password: password);
  }

  // 🔐 Sign in user
  Future<AuthResponse> signIn({required String email, required String password}) async {
    return await _client.auth.signInWithPassword(email: email, password: password);
  }



  // 🔓 Sign out user
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  //Create user function
  Future<AuthResponse> createUser({required String email, required String password}) async {
    return await Supabase.instance.client.auth.signUp(
      email: email,
      password: password,
    );
  }



  // ✅ Get current user session
  User? get currentUser => _client.auth.currentUser;

  // 📡 Listen for auth state changes (optional)
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;
}
