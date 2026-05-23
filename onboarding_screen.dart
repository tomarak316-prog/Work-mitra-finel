// lib/screens/onboarding/onboarding_screen.dart
// STEP 12 — First-time user onboarding

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/app_theme.dart';
import '../auth/login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageCtrl = PageController();
  int _current = 0;

  static const _pages = [
    _OBPage(
      emoji: '🇮🇳',
      title: 'India ka #1\nLocal Job App',
      subtitle: 'Delivery, Driver, Shop, Labour,\nElectrician — har kaam yahan milega',
      bg1: Color(0xFF15803d),
      bg2: Color(0xFF22c55e),
    ),
    _OBPage(
      emoji: '📍',
      title: 'Ghar ke Paas\nJob Dhundo',
      subtitle: 'Location se 1-10 km ke andar\nsabse close jobs dikhte hain',
      bg1: Color(0xFF1d4ed8),
      bg2: Color(0xFF3b82f6),
    ),
    _OBPage(
      emoji: '🤖',
      title: 'AI Smart\nJob Matching',
      subtitle: 'Aapke skills ke hisaab se\nAI best jobs recommend karta hai',
      bg1: Color(0xFF7c3aed),
      bg2: Color(0xFFa78bfa),
    ),
    _OBPage(
      emoji: '⚡',
      title: 'One-Click\nApply Karo',
      subtitle: 'Resume upload, WhatsApp contact,\naur direct employer call — sab easy',
      bg1: Color(0xFFb45309),
      bg2: Color(0xFFf59e0b),
    ),
  ];

  void _next() {
    if (_current < _pages.length - 1) {
      _pageCtrl.nextPage(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut);
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    if (!mounted) return;
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  void dispose() { _pageCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(children: [
        // Pages
        PageView.builder(
          controller: _pageCtrl,
          onPageChanged: (i) => setState(() => _current = i),
          itemCount: _pages.length,
          itemBuilder: (_, i) => _pages[i],
        ),

        // Skip button
        Positioned(
          top: MediaQuery.of(context).padding.top + 16,
          right: 20,
          child: TextButton(
            onPressed: _finish,
            child: const Text('Skip',
                style: TextStyle(color: Colors.white70,
                    fontWeight: FontWeight.w600)),
          ),
        ),

        // Bottom controls
        Positioned(
          bottom: 48, left: 24, right: 24,
          child: Column(children: [
            // Dots
            Row(mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_pages.length, (i) =>
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _current == i ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                        color: _current == i
                            ? Colors.white
                            : Colors.white38,
                        borderRadius: BorderRadius.circular(4)),
                  ))),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity, height: 54,
              child: ElevatedButton(
                onPressed: _next,
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: _pages[_current].bg1,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 0),
                child: Text(
                    _current == _pages.length - 1
                        ? 'Shuru Karo 🚀'
                        : 'Aage Chalo →',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 16)),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _OBPage extends StatelessWidget {
  final String emoji, title, subtitle;
  final Color bg1, bg2;
  const _OBPage({required this.emoji, required this.title,
    required this.subtitle, required this.bg1, required this.bg2});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [bg1, bg2])),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 96)),
              const SizedBox(height: 32),
              Text(title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      height: 1.2)),
              const SizedBox(height: 16),
              Text(subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      height: 1.6)),
            ],
          ),
        ),
      ),
    );
  }
}
