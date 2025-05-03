import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _client = Supabase.instance.client;

  // 🔐 Orijinal fonksiyonlar (DEĞİŞMEDİ) -----------------
  Future<AuthResponse> signUp({required String email, required String password}) async {
    return await _client.auth.signUp(email: email, password: password);
  }

  Future<AuthResponse> signIn({required String email, required String password}) async {
    return await _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<AuthResponse> createUser({required String email, required String password}) async {
    return await _client.auth.signUp(email: email, password: password);
  }
  // ------------------------------------------------------

  // 🔄 YENİ GÜNCELLENMİŞ ŞİFRE SIFIRLAMA FONKSİYONU -----
  Future<void> sendPasswordResetEmail(String email) async {
    await _client.auth.resetPasswordForEmail(
      email,
      redirectTo: 'io.supabase.flutter://reset-callback/',
    );
  }

  Future<void> updatePasswordWithToken({
    required String email, // Yeni eklenen parametre
    required String token,
    required String newPassword,
  }) async {
    // 1. OTP'yi doğrula (currentUser yerine direkt email kullan)
    await _client.auth.verifyOTP(
      type: OtpType.recovery,
      token: token,
      email: email, // currentUser.email kullanılmıyor
    );

    // 2. Şifreyi güncelle (orijinal mantık korundu)
    await _client.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }
  // ------------------------------------------------------

  // ✅ Orijinal fonksiyonlar (DEĞİŞMEDİ) -----------------
  User? get currentUser => _client.auth.currentUser;
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;
// ------------------------------------------------------
}