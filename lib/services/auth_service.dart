import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_client.dart';

class AuthService {
  // =========== REGISTER ===========
  Future<void> register({required String name, required String email, required String password}) async {
    // signUp automatically fires the DB trigger that creates a profiles row
    final res = await supabase.auth.signUp(email: email, password: password, data: {'name': name});
    if (res.user == null) throw Exception('Registration failed');
  }

  // =========== LOGIN ===========
  Future<void> login({required String email, required String password}) async {
    await supabase.auth.signInWithPassword(email: email, password: password);
  }

  // =========== LOGOUT ===========
  Future<void> logout() async => await supabase.auth.signOut();

  // =========== PROFILE ===========
  Future<Map<String, dynamic>> getProfile() async {
    final data = await supabase.from('profiles').select().eq('id', currentUserId).single();
    return data;
  }

  // =========== UPDATE PROFILE ===========
  Future<Map<String, dynamic>> updateProfile({required String name, required String email}) async {
    final data = await supabase
        .from('profiles')
        .update({'name': name, 'email': email, 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', currentUserId)
        .select()
        .single();
    return data;
  }

  // =========== UPLOAD IMAGE PROFILE ===========
  Future<String> uploadAvatar(File file) async {
    final ext = file.path.split('.').last;
    final path = '$currentUserId/avatar.$ext';

    await supabase.storage.from('avatars').upload(path, file, fileOptions: const FileOptions(upsert: true));

    final url = supabase.storage.from('avatars').getPublicUrl(path);

    await supabase.from('profiles').update({'avatar_url': url}).eq('id', currentUserId);

    return url;
  }

  // =========== GOOGLE SIGN IN ===========
  Future<void> signInWithGoogle() async {
    await supabase.auth.signInWithOAuth(OAuthProvider.google, redirectTo: 'io.supabase.splitsmart://login-callback');
  }

  // =========== FORGOT PASSWORD ===========
  Future<void> resetPassword(String email) async {
    await supabase.auth.resetPasswordForEmail(email, redirectTo: 'io.supabase.splitsmart://reset-callback');
  }

  String get currentUserId => supabase.auth.currentUser!.id;

  // =========== AUTH STATE ===========
  Stream<AuthState> get authStateChanges => supabase.auth.onAuthStateChange;

  bool get isLoggedIn => supabase.auth.currentUser != null;
}
