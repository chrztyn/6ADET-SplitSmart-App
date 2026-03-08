import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> with SingleTickerProviderStateMixin {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _success = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic));
    _animationController.forward();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _updatePassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await Supabase.instance.client.auth.updateUser(UserAttributes(password: _passwordController.text));
      if (mounted) setState(() => _success = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString(), style: GoogleFonts.montserrat()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
          child: SlideTransition(
            position: _slideAnimation,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: MediaQuery.of(context).size.height * 0.75,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(40), topRight: Radius.circular(40)),
                  boxShadow: [BoxShadow(color: Color(0x1A000000), blurRadius: 20, offset: Offset(0, -5))],
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  child: _success ? _buildSuccess() : _buildForm(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          Text(
            'Reset Password',
            style: GoogleFonts.montserrat(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF2D3142)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 5),
          Text(
            'Enter your new password below',
            style: GoogleFonts.montserrat(fontSize: 12, color: const Color(0xFF6B7280)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),

          // New Password
          Text(
            'New Password',
            style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF075EFB)),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            style: GoogleFonts.montserrat(),
            decoration: InputDecoration(
              hintText: 'Enter new password',
              hintStyle: GoogleFonts.montserrat(color: const Color(0xFFBDC3C7), fontSize: 14),
              filled: true,
              fillColor: Colors.white,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFB1B1B0), width: 0.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFA0A0A0), width: 0.5),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red, width: 0.5),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red, width: 0.5),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: const Color(0xFF9CA3AF),
                  size: 18,
                ),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Please enter a password';
              if (value.length < 6) return 'Password must be at least 6 characters';
              return null;
            },
          ),
          const SizedBox(height: 20),

          // Confirm Password
          Text(
            'Confirm Password',
            style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF075EFB)),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _confirmController,
            obscureText: _obscureConfirm,
            style: GoogleFonts.montserrat(),
            decoration: InputDecoration(
              hintText: 'Confirm new password',
              hintStyle: GoogleFonts.montserrat(color: const Color(0xFFBDC3C7), fontSize: 14),
              filled: true,
              fillColor: Colors.white,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFB1B1B0), width: 0.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFA0A0A0), width: 0.5),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red, width: 0.5),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red, width: 0.5),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                  color: const Color(0xFF9CA3AF),
                  size: 18,
                ),
                onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Please confirm your password';
              if (value != _passwordController.text) return 'Passwords do not match';
              return null;
            },
          ),
          const SizedBox(height: 32),

          // Update Password button
          GestureDetector(
            onTap: _loading ? null : _updatePassword,
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF075EFB), Color(0xFF0041C6)]),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF075EFB).withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Center(
                child: _loading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        'Update Password',
                        style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccess() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 40),
        const Icon(Icons.check_circle_outline, size: 80, color: Color(0xFF075EFB)),
        const SizedBox(height: 24),
        Text(
          'Password Updated!',
          style: GoogleFonts.montserrat(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF2D3142)),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'Your password has been successfully updated.',
          style: GoogleFonts.montserrat(fontSize: 13, color: const Color(0xFF6B7280)),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),
        GestureDetector(
          onTap: () {
            Navigator.of(
              context,
            ).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const _LoginRedirect()), (route) => false);
          },
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF075EFB), Color(0xFF0041C6)]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                'Back to Sign In',
                style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Helper widget to navigate back to login
class _LoginRedirect extends StatefulWidget {
  const _LoginRedirect();
  @override
  State<_LoginRedirect> createState() => _LoginRedirectState();
}

class _LoginRedirectState extends State<_LoginRedirect> {
  @override
  void initState() {
    super.initState();
    Supabase.instance.client.auth.signOut();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(
        context,
      ).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const _AuthGateRedirect()), (route) => false);
    });
  }

  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: CircularProgressIndicator()));
}

class _AuthGateRedirect extends StatelessWidget {
  const _AuthGateRedirect();
  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
