import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/app_provider.dart';
import '../widgets/notification_bell.dart';
import 'auth/landing_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  bool _isEditing = false;
  bool _isSaving = false;
  File? _avatarFile;
  bool _uploadingAvatar = false;

  // Holds the last profile map we populated from so we skip redundant fills
  Map<String, dynamic>? _lastFilledProfile;

  @override
  void initState() {
    super.initState();
    // Force a fresh profile fetch so data is always up-to-date
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AppProvider>().refreshProfile();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _populateIfNeeded();
  }

  void _populateIfNeeded() {
    if (_isEditing) return;
    final profile = context.read<AppProvider>().profile;
    if (profile == null) return;
    if (identical(profile, _lastFilledProfile)) return;
    _lastFilledProfile = profile;

    final user = Supabase.instance.client.auth.currentUser;
    final meta = user?.userMetadata ?? {};

    final rawName = profile['name'] as String?;
    final name = (rawName != null && rawName.trim().isNotEmpty)
        ? rawName
        : ((meta['full_name'] as String?) ?? (meta['name'] as String?) ?? '');

    final rawEmail = profile['email'] as String?;
    final email = (rawEmail != null && rawEmail.trim().isNotEmpty)
        ? rawEmail
        : (user?.email ?? '');

    final rawPhone = profile['phone'] as String?;
    final phone = (rawPhone != null && rawPhone.trim().isNotEmpty)
        ? rawPhone
        : (user?.phone ?? '');

    _nameController.text = name;
    _emailController.text = email;
    _phoneController.text = phone;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _saveName() async {
    setState(() => _isSaving = true);
    try {
      await context.read<AppProvider>().updateProfile(
        _nameController.text.trim(),
        _emailController.text.trim(),
        phone: _phoneController.text.trim(),
      );
      if (mounted) setState(() => _isEditing = false);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _pickAndUploadAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );
    if (picked == null) return;

    setState(() {
      _avatarFile = File(picked.path);
      _uploadingAvatar = true;
    });

    try {
      await context.read<AppProvider>().uploadAvatar(_avatarFile!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Profile picture updated!',
              style: GoogleFonts.montserrat(),
            ),
            backgroundColor: const Color(0xFF43A047),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to upload: $e',
              style: GoogleFonts.montserrat(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final profile = provider.profile;

    if (!_isEditing) _populateIfNeeded();

    final user = Supabase.instance.client.auth.currentUser;
    final meta = user?.userMetadata ?? {};

    final String initial = _nameController.text.isNotEmpty
        ? _nameController.text.substring(0, 1).toUpperCase()
        : ((meta['full_name'] as String? ?? meta['name'] as String? ?? '?')
              .substring(0, 1)
              .toUpperCase());

    final String? metaAvatarUrl =
        (meta['avatar_url'] as String?) ?? (meta['picture'] as String?);
    final String? avatarUrl =
        (profile?['avatar_url'] as String?) ?? metaAvatarUrl;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF6FAFC), Color(0xFFDCF2FF), Color(0xFFB4E4FF)],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 36,
                  vertical: 32,
                ),
                child: _buildHeader(initial, avatarUrl),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(
                    left: 36,
                    right: 36,
                    bottom: 40,
                  ),
                  children: [
                    Text(
                      'Profile',
                      style: GoogleFonts.montserrat(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF003CC1),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manage your account settings and personal information.',
                      style: GoogleFonts.montserrat(
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        color: const Color(0xFF7A7A7A),
                      ),
                    ),
                    const SizedBox(height: 28),

                    Center(
                      child: GestureDetector(
                        onTap: _uploadingAvatar ? null : _pickAndUploadAvatar,
                        child: Stack(
                          children: [
                            Card(
                              elevation: 2,
                              margin: EdgeInsets.zero,
                              color: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                                side: BorderSide(
                                  color: Colors.grey.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: _buildAvatarCircle(
                                  avatarUrl: avatarUrl,
                                  initial: initial,
                                  size: 80,
                                ),
                              ),
                            ),
                            if (_uploadingAvatar)
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            Positioned(
                              bottom: 4,
                              right: 4,
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF003CC1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.camera_alt_outlined,
                                  color: Colors.white,
                                  size: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Text(
                        'Tap to change profile picture',
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          color: const Color(0xFF5A5A5A),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Name',
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF2C2C2C),
                          ),
                        ),
                        GestureDetector(
                          onTap: _isSaving
                              ? null
                              : () {
                                  if (_isEditing) {
                                    _saveName();
                                  } else {
                                    setState(() => _isEditing = true);
                                  }
                                },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF003CC1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: _isSaving
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : Text(
                                    _isEditing ? 'Save' : 'Edit',
                                    style: GoogleFonts.montserrat(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _buildInputField(
                      controller: _nameController,
                      enabled: _isEditing,
                    ),
                    const SizedBox(height: 20),

                    Text(
                      'Phone Number',
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2C2C2C),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Phone number — saved to profiles on submit
                    _buildInputField(
                      controller: _phoneController,
                      enabled: _isEditing,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 20),

                    Text(
                      'Email',
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2C2C2C),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildInputField(
                      controller: _emailController,
                      enabled: false,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Email cannot be changed',
                      style: GoogleFonts.montserrat(
                        fontSize: 11,
                        color: const Color(0xFF8B8B8B),
                      ),
                    ),
                    const SizedBox(height: 32),

                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 52,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF0254D8), Color(0xFF003CC1)],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () async {
                                  await context.read<AppProvider>().logout();
                                  if (mounted) {
                                    Navigator.pushAndRemoveUntil(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const LandingScreen(),
                                      ),
                                      (route) => false,
                                    );
                                  }
                                },
                                borderRadius: BorderRadius.circular(14),
                                child: Center(
                                  child: Text(
                                    'Log Out',
                                    style: GoogleFonts.montserrat(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Container(
                            height: 52,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8E8E8),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                // Delete account — removes user from auth and profiles
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: Text(
                                        'Delete Account',
                                        style: GoogleFonts.montserrat(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      content: Text(
                                        'Are you sure you want to delete your account? This cannot be undone.',
                                        style: GoogleFonts.montserrat(
                                          fontSize: 13,
                                        ),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(ctx),
                                          child: Text(
                                            'Cancel',
                                            style: GoogleFonts.montserrat(),
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: () => Navigator.pop(ctx),
                                          child: Text(
                                            'Delete',
                                            style: GoogleFonts.montserrat(
                                              color: Colors.red,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(14),
                                child: Center(
                                  child: Text(
                                    'Delete Account',
                                    style: GoogleFonts.montserrat(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF8B8B8B),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String initial, String? avatarUrl) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFF003CC1), Color(0xFF038AFF), Color(0xFF01A7FF)],
          ).createShader(bounds),
          child: Text(
            'SplitSmart',
            style: GoogleFonts.montserrat(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        Row(
          children: [
            const NotificationBell(),
            const SizedBox(width: 12),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: ClipOval(
                child: _buildAvatarCircle(
                  avatarUrl: avatarUrl,
                  initial: initial,
                  size: 40,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAvatarCircle({
    required String? avatarUrl,
    required String initial,
    double size = 40,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          colors: [Color(0xFF0254D8), Color(0xFF003CC1)],
          center: Alignment.center,
          radius: 0.8,
        ),
        shape: BoxShape.circle,
      ),
      child: ClipOval(
        child: _avatarFile != null
            ? Image.file(_avatarFile!, fit: BoxFit.cover)
            : avatarUrl != null
            ? Image.network(
                avatarUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Center(
                  child: Text(
                    initial,
                    style: GoogleFonts.montserrat(
                      fontSize: size * 0.4,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              )
            : Center(
                child: Text(
                  initial,
                  style: GoogleFonts.montserrat(
                    fontSize: size * 0.4,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    bool enabled = true,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      style: GoogleFonts.montserrat(
        fontSize: 14,
        color: const Color(0xFF2C2C2C),
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: Colors.grey.withOpacity(0.25),
            width: 1,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.2), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF038AFF), width: 1.5),
        ),
      ),
    );
  }
}
