import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_client.dart';

class AuthService {
  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final res = await supabase.auth.signUp(
      email: email,
      password: password,
      data: {'name': name},
    );
    if (res.user == null) throw Exception('Registration failed');
    // Write name to profiles table so it's visible to other group members
    await supabase.from('profiles').upsert({
      'id': res.user!.id,
      'name': name,
      'email': email,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> login({required String email, required String password}) async {
    await supabase.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> logout() async => await supabase.auth.signOut();

  Future<Map<String, dynamic>> getProfile() async {
    final data = await supabase
        .from('profiles')
        .select()
        .eq('id', currentUserId)
        .single();

    final user = supabase.auth.currentUser;
    final meta = user?.userMetadata ?? {};

    String? name = data['name'] as String?;
    if (name == null || name.trim().isEmpty) {
      name =
          (meta['full_name'] as String?) ??
          (meta['name'] as String?) ??
          (meta['email'] as String?)?.split('@').first;
    }

    final email =
        ((data['email'] as String?)?.trim().isNotEmpty == true
            ? data['email'] as String
            : null) ??
        user?.email;

    final String? avatarUrl =
        (data['avatar_url'] as String?) ??
        (meta['avatar_url'] as String?) ??
        (meta['picture'] as String?);

    return {
      ...data,
      if (name != null) 'name': name,
      if (email != null) 'email': email,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
    };
  }

  Future<Map<String, dynamic>> updateProfile({
    required String name,
    required String email,
    String? phone,
  }) async {
    final data = await supabase
        .from('profiles')
        .update({
          'name': name,
          'email': email,
          if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', currentUserId)
        .select()
        .single();
    return data;
  }

  Future<String> uploadAvatar(File file) async {
    final ext = file.path.split('.').last;
    final path = '$currentUserId/avatar.$ext';

    await supabase.storage
        .from('avatars')
        .upload(path, file, fileOptions: const FileOptions(upsert: true));

    final url = supabase.storage.from('avatars').getPublicUrl(path);

    await supabase
        .from('profiles')
        .update({'avatar_url': url})
        .eq('id', currentUserId);

    return url;
  }

  Future<void> signInWithGoogle() async {
    await supabase.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'io.supabase.splitsmart://login-callback',
      authScreenLaunchMode: LaunchMode.externalApplication,
    );
  }

  Future<void> resetPassword(String email) async {
    await supabase.auth.resetPasswordForEmail(
      email,
      redirectTo: 'io.supabase.splitsmart://reset-callback',
    );
  }

  String get currentUserId => supabase.auth.currentUser!.id;

  Stream<AuthState> get authStateChanges => supabase.auth.onAuthStateChange;

  bool get isLoggedIn => supabase.auth.currentUser != null;
}
