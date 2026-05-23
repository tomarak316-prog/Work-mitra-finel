// lib/screens/auth/login_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firebase_service.dart';
import '../../utils/app_theme.dart';
import 'otp_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  int    _tab     = 0; // 0=phone, 1=email
  bool   _loading = false;
  bool   _showPw  = false;
  String _err     = '';

  final _phone    = TextEditingController();
  final _email    = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _phone.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _setErr(String e)  => setState(() => _err = e);
  void _setLoad(bool v)   => setState(() => _loading = v);

  // ── Phone OTP ─────────────────────────────────────────────────
  Future<void> _sendOTP() async {
    final p = _phone.text.trim();
    if (p.length < 10) { _setErr('Valid phone number enter karo'); return; }
    _setLoad(true); _setErr('');
    await AuthService.sendOTP(
      phone: p,
      onSent: (vid, token) {
        _setLoad(false);
        if (!mounted) return;
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) =>
                    OTPScreen(phone: p, verificationId: vid)));
      },
      onError: (e) { _setLoad(false); _setErr(e); },
    );
  }

  // ── Email Login ───────────────────────────────────────────────
  Future<void> _emailLogin() async {
    final e = _email.text.trim();
    final p = _password.text;
    if (e.isEmpty || p.isEmpty) {
      _setErr('Email aur password bharo');
      return;
    }
    _setLoad(true); _setErr('');
    try {
      await AuthService.loginEmail(e, p);
      // StreamBuilder in AuthGate navigates automatically
    } on FirebaseAuthException catch (ex) {
      _setErr(ex.message ?? 'Login failed');
    } catch (ex) {
      _setErr(ex.toString());
    } finally {
      if (mounted) _setLoad(false);
    }
  }

  // ── Google Login ──────────────────────────────────────────────
  Future<void> _googleLogin() async {
    _setLoad(true); _setErr('');
    try {
      await AuthService.loginGoogle();
    } catch (e) {
      _setErr(e.toString());
    } finally {
      if (mounted) _setLoad(false);
    }
  }

  // ── Forgot Password ───────────────────────────────────────────
  Future<void> _forgotPassword() async {
    final e = _email.text.trim();
    if (e.isEmpty) {
      _setErr('Pehle email daalo, phir reset karo');
      return;
    }
    try {
      await AuthService.resetPassword(e);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('✅ Reset link bheja: $e'),
            backgroundColor: AppTheme.green),
      );
    } catch (ex) {
      _setErr(ex.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(children: [
            // ── Hero gradient header ──────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF15803d),
                    Color(0xFF16a34a),
                    Color(0xFF22c55e),
                  ],
                ),
              ),
              child: Column(children: [
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Center(
                      child: Text('💼',
                          style: TextStyle(fontSize: 42))),
                ),
                const SizedBox(height: 12),
                const Text('Work Mitra',
                    style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.5)),
                const Text('आपका काम, आपके पास',
                    style: TextStyle(
                        color: Colors.white70, fontSize: 13)),
              ]),
            ),

            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Login Karo 👋',
                      style: TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  const Text('Apne account mein sign in karo',
                      style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 20),

                  // ── Tab selector ──────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                        color: AppTheme.greenPale,
                        borderRadius: BorderRadius.circular(14)),
                    child: Row(children: [
                      _tabBtn('📱 OTP', 0),
                      _tabBtn('📧 Email', 1),
                    ]),
                  ),
                  const SizedBox(height: 20),

                  // ── Phone tab ─────────────────────────────────
                  if (_tab == 0)
                    _inputField(
                      controller: _phone,
                      label: '📱 Phone Number',
                      hint: '+91 XXXXX XXXXX',
                      keyboard: TextInputType.phone,
                    ),

                  // ── Email tab ─────────────────────────────────
                  if (_tab == 1) ...[
                    _inputField(
                      controller: _email,
                      label: '📧 Email Address',
                      keyboard: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 12),
                    _inputField(
                      controller: _password,
                      label: '🔒 Password',
                      obscure: !_showPw,
                      suffix: IconButton(
                        icon: Icon(
                            _showPw
                                ? Icons.visibility_off
                                : Icons.visibility,
                            size: 20),
                        onPressed: () =>
                            setState(() => _showPw = !_showPw),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _forgotPassword,
                        child: const Text('Password bhool gaye?',
                            style: TextStyle(color: AppTheme.green)),
                      ),
                    ),
                  ],

                  // ── Error box ─────────────────────────────────
                  if (_err.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    _errorBox(_err),
                  ],
                  const SizedBox(height: 8),

                  // ── Primary CTA ───────────────────────────────
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _loading
                          ? null
                          : (_tab == 0 ? _sendOTP : _emailLogin),
                      child: _loading
                          ? const CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2)
                          : Text(
                              _tab == 0
                                  ? '📱 OTP Bhejo'
                                  : '🔐 Login Karo'),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Divider ───────────────────────────────────
                  const Row(children: [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text('ya phir',
                          style: TextStyle(color: Colors.grey)),
                    ),
                    Expanded(child: Divider()),
                  ]),
                  const SizedBox(height: 16),

                  // ── Google button ─────────────────────────────
                  OutlinedButton.icon(
                    onPressed: _loading ? null : _googleLogin,
                    icon: const Text('G',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFea4335))),
                    label: const Text('Google se Login',
                        style:
                            TextStyle(fontWeight: FontWeight.w700)),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Register link ─────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Naya account?'),
                      TextButton(
                        onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    const RegisterScreen())),
                        child: const Text('Register Karo →',
                            style: TextStyle(
                                color: AppTheme.green,
                                fontWeight: FontWeight.w800)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _tabBtn(String label, int index) => Expanded(
        child: GestureDetector(
          onTap: () => setState(() { _tab = index; _err = ''; }),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: _tab == index
                  ? AppTheme.green
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color:
                        _tab == index ? Colors.white : Colors.grey)),
          ),
        ),
      );

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    String? hint,
    bool obscure = false,
    TextInputType? keyboard,
    Widget? suffix,
  }) =>
      TextFormField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboard,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          suffixIcon: suffix,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: AppTheme.green, width: 2)),
        ),
      );

  Widget _errorBox(String msg) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: const Color(0xFFfef2f2),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFfca5a5))),
        child: Text('❌ $msg',
            style: const TextStyle(
                color: Color(0xFFef4444), fontSize: 13)),
      );
}
