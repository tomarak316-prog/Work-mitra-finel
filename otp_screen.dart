// lib/screens/auth/otp_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/firebase_service.dart';
import '../../utils/app_theme.dart';

class OTPScreen extends StatefulWidget {
  final String phone;
  final String verificationId;
  const OTPScreen({super.key, required this.phone, required this.verificationId});
  @override State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  final _controllers = List.generate(6, (_) => TextEditingController());
  final _focusNodes  = List.generate(6, (_) => FocusNode());
  bool   _loading  = false;
  String _err      = '';
  int    _timer    = 60;
  Timer? _countdown;

  @override
  void initState() {
    super.initState();
    _startTimer();
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => _focusNodes[0].requestFocus());
  }

  void _startTimer() {
    _countdown = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_timer <= 0) { t.cancel(); return; }
      setState(() => _timer--);
    });
  }

  @override
  void dispose() {
    _countdown?.cancel();
    for (final c in _controllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
    super.dispose();
  }

  String get _otp => _controllers.map((c) => c.text).join();

  Future<void> _verify() async {
    if (_otp.length < 6) {
      setState(() => _err = '6-digit OTP pura bharo');
      return;
    }
    setState(() { _loading = true; _err = ''; });
    try {
      await AuthService.verifyOTP(widget.verificationId, _otp);
      // Auth state change auto-navigates via StreamBuilder in root
    } catch (e) {
      setState(() => _err = 'Galat OTP. Dobara try karo.');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('📱 OTP Verify Karo',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text('${widget.phone} pe SMS bheja gaya',
                style: const TextStyle(color: Colors.grey, fontSize: 14)),
            const SizedBox(height: 36),

            // ── 6 OTP boxes ──────────────────────────────────
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(6, (i) => SizedBox(
                width: 46, height: 54,
                child: TextFormField(
                  controller: _controllers[i],
                  focusNode: _focusNodes[i],
                  textAlign: TextAlign.center,
                  maxLength: 1,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w900),
                  decoration: InputDecoration(
                    counterText: '',
                    filled: true,
                    fillColor: _controllers[i].text.isNotEmpty
                        ? AppTheme.greenPale : const Color(0xFFf9fafb),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                            color: _controllers[i].text.isNotEmpty
                                ? AppTheme.green
                                : const Color(0xFFe5e7eb))),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: AppTheme.green, width: 2)),
                  ),
                  onChanged: (v) {
                    setState(() {});
                    if (v.isNotEmpty && i < 5) {
                      _focusNodes[i + 1].requestFocus();
                    } else if (v.isEmpty && i > 0) {
                      _focusNodes[i - 1].requestFocus();
                    }
                    if (_otp.length == 6) _verify();
                  },
                ),
              )),
            ),
            const SizedBox(height: 20),

            // ── Error ────────────────────────────────────────
            if (_err.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                    color: const Color(0xFFfef2f2),
                    borderRadius: BorderRadius.circular(10)),
                child: Text('❌ $_err',
                    style: const TextStyle(color: Colors.red, fontSize: 13)),
              ),

            // ── Verify button ────────────────────────────────
            SizedBox(
              width: double.infinity, height: 52,
              child: ElevatedButton(
                onPressed: _loading ? null : _verify,
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.green,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14))),
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('✅ OTP Verify Karo',
                        style: TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 15,
                            color: Colors.white)),
              ),
            ),
            const SizedBox(height: 20),

            // ── Resend ───────────────────────────────────────
            Center(
              child: _timer > 0
                  ? Text('⏱️ Resend in $_timer seconds',
                      style: const TextStyle(color: Colors.grey))
                  : TextButton(
                      onPressed: () {
                        setState(() => _timer = 60);
                        _startTimer();
                        // Re-trigger OTP send from parent or navigate back
                        Navigator.pop(context);
                      },
                      child: const Text('🔄 OTP Dobara Bhejo',
                          style: TextStyle(
                              color: AppTheme.green,
                              fontWeight: FontWeight.w700)),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
