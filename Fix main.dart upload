// lib/main.dart — Work Mitra v3.0 (Step 17)
// Package: com.workmitra.india | Firebase: work-mitra

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'services/firebase_service.dart';
import 'providers/app_provider.dart';
import 'screens/home/home_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'utils/notif_helper.dart';
import 'utils/app_theme.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

@pragma('vm:entry-point')
Future<void> _bgFCMHandler(RemoteMessage msg) async {
  await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform);

  FirebaseMessaging.onBackgroundMessage(_bgFCMHandler);

  await NotifHelper.init();

  FirebaseMessaging.onMessage.listen((msg) {
    final n = msg.notification;
    if (n != null) NotifHelper.show(title: n.title ?? '', body: n.body ?? '');
  });

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppProvider(),
      child: const WorkMitraApp(),
    ),
  );
}

class WorkMitraApp extends StatelessWidget {
  const WorkMitraApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Work Mitra',
    debugShowCheckedModeBanner: false,
    navigatorKey: navigatorKey,
    theme: AppTheme.light(),
    darkTheme: AppTheme.dark(),
    themeMode: ThemeMode.system,
    home: const _Root(),
  );
}

// ── Root: decides onboarding vs auth vs home ──────────────────────
class _Root extends StatefulWidget {
  const _Root();
  @override State<_Root> createState() => _RootState();
}

class _RootState extends State<_Root> {
  bool? _onboardingDone;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((p) {
      if (mounted) {
        setState(() =>
            _onboardingDone = p.getBool('onboarding_done') ?? false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_onboardingDone == null) return const _SplashScreen();
    if (!_onboardingDone!) return const OnboardingScreen();

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const _SplashScreen();
        }
        if (snap.hasData && snap.data != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.read<AppProvider>().init();
          });
          AuthService.refreshToken();
          return const HomeScreen();
        }
        return const LoginScreen();
      },
    );
  }
}

// ── Splash Screen ─────────────────────────────────────────────────
class _SplashScreen extends StatefulWidget {
  const _SplashScreen();
  @override State<_SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<_SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade, _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 900))..forward();
    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _scale = Tween(begin: 0.85, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    body: Center(
      child: FadeTransition(opacity: _fade,
        child: ScaleTransition(scale: _scale,
          child: Column(mainAxisAlignment: MainAxisAlignment.center,
            children: [
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF15803d), Color(0xFF22c55e)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [BoxShadow(
                    color: const Color(0xFF16a34a).withOpacity(0.3),
                    blurRadius: 24, offset: const Offset(0, 8))],
              ),
              child: const Center(child: Text('💼',
                  style: TextStyle(fontSize: 52))),
            ),
            const SizedBox(height: 20),
            const Text('Work Mitra', style: TextStyle(
                fontSize: 30, fontWeight: FontWeight.w900,
                color: Color(0xFF15803d), letterSpacing: -0.5)),
            const SizedBox(height: 6),
            const Text('आपका काम, आपके पास', style: TextStyle(
                color: Color(0xFF16a34a), fontSize: 14)),
            const SizedBox(height: 40),
            const SizedBox(width: 140,
              child: LinearProgressIndicator(
                  backgroundColor: Color(0xFFdcfce7),
                  color: Color(0xFF16a34a), minHeight: 3)),
          ]),
        ),
      ),
    ),
  );
}
