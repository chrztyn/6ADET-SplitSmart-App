import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'providers/app_provider.dart';
import 'screens/auth/landing_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/auth/reset_password_screen.dart';
import 'utils/local_notifications_helper.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  await LocalNotificationsHelper.init();

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppProvider(),
      child: const SplitSmartApp(),
    ),
  );
}

class SplitSmartApp extends StatelessWidget {
  const SplitSmartApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SplitSmart',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      home: const _ConnectivityWrapper(child: _AuthGate()),
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB)),
      scaffoldBackgroundColor: const Color(0xFFF9FAFB),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF2563EB),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2563EB),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      useMaterial3: true,
    );
  }
}

class _AuthGate extends StatefulWidget {
  const _AuthGate();
  @override
  State<_AuthGate> createState() => _AuthGateState();
}

/// Listens to connectivity changes and shows a toast banner when offline.
class _ConnectivityWrapper extends StatefulWidget {
  final Widget child;
  const _ConnectivityWrapper({required this.child});

  @override
  State<_ConnectivityWrapper> createState() => _ConnectivityWrapperState();
}

class _ConnectivityWrapperState extends State<_ConnectivityWrapper> {
  bool _isOffline = false;
  OverlayEntry? _overlayEntry;
  StreamSubscription? _subscription;
  Timer? _autoHideTimer;

  @override
  void initState() {
    super.initState();
    try {
      _subscription = Connectivity().onConnectivityChanged.listen((results) {
        if (!mounted) return;
        final offline = results.every((r) => r == ConnectivityResult.none);
        if (offline == _isOffline) return;
        _isOffline = offline;
        if (offline) {
          _autoHideTimer?.cancel();
          _showBanner(online: false);
        } else {
          _showBanner(online: true);
          _autoHideTimer = Timer(const Duration(seconds: 3), _hideBanner);
        }
      });
    } catch (_) {
      // Plugin not yet linked — safe to ignore until full rebuild
    }
  }

  void _showBanner({required bool online}) {
    _hideBanner(); // remove any existing one first
    _overlayEntry = OverlayEntry(
      builder: (_) => Positioned(
        top: MediaQuery.of(context).padding.top + 8,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: online ? const Color(0xFF2E7D32) : const Color(0xFFD32F2F),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  online ? Icons.wifi : Icons.wifi_off,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    online ? 'Back online' : 'No internet connection',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideBanner() {
    try {
      _overlayEntry?.remove();
    } catch (_) {}
    _overlayEntry = null;
  }

  @override
  void dispose() {
    _autoHideTimer?.cancel();
    _subscription?.cancel();
    _hideBanner();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _AuthGateState extends State<_AuthGate> {
  @override
  void initState() {
    super.initState();

    final existingSession = Supabase.instance.client.auth.currentSession;
    if (existingSession != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.read<AppProvider>().init();
      });
    }

    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (!mounted) return;
      final provider = context.read<AppProvider>();

      if (data.event == AuthChangeEvent.passwordRecovery) {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const ResetPasswordScreen()));
        return;
      }

      if (data.event == AuthChangeEvent.signedIn ||
          data.event == AuthChangeEvent.initialSession) {
        if (data.session != null) provider.init();
      }
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;

    if (session == null) return const LandingScreen();

    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.profile == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return const DashboardScreen();
      },
    );
  }
}
