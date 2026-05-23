// lib/screens/auth/register_screen.dart
import 'package:flutter/material.dart';
import '../../services/firebase_service.dart';
import '../../utils/app_theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name    = TextEditingController();
  final _email   = TextEditingController();
  final _phone   = TextEditingController();
  final _pass    = TextEditingController();
  final _conf    = TextEditingController();

  bool   _loading = false;
  bool   _showPw  = false;
  String _err     = '';
  String _role    = 'worker';

  @override
  void dispose() {
    _name.dispose(); _email.dispose(); _phone.dispose();
    _pass.dispose(); _conf.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    final pw = _pass.text;
    final cf = _conf.text;
    if (pw != cf) {
      setState(() => _err = 'Passwords match nahi kar rahe');
      return;
    }
    setState(() { _loading = true; _err = ''; });
    try {
      await AuthService.registerEmail(
        email:    _email.text.trim(),
        password: pw,
        name:     _name.text.trim(),
        phone:    _phone.text.trim(),
      );
      await UserService.update({'role': _role});
      // AuthGate navigates automatically on success
    } catch (ex) {
      setState(() =>
          _err = ex.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
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
        title: const Text('Register Karo',
            style: TextStyle(
                color: Colors.black, fontWeight: FontWeight.w800)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Role selector
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                    color: AppTheme.greenPale,
                    borderRadius: BorderRadius.circular(14)),
                child: Row(children: [
                  _roleBtn('👷 Worker', 'worker'),
                  _roleBtn('🏢 Employer', 'employer'),
                ]),
              ),
              const SizedBox(height: 20),

              _field(_name,  '👤 Full Name',    req: true),
              const SizedBox(height: 12),
              _field(_email, '📧 Email',
                  keyboard: TextInputType.emailAddress, req: true),
              const SizedBox(height: 12),
              _field(_phone, '📱 Phone',
                  keyboard: TextInputType.phone, req: true),
              const SizedBox(height: 12),
              _field(_pass,  '🔒 Password',
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
                  req: true),
              const SizedBox(height: 12),
              _field(_conf, '🔒 Confirm Password',
                  obscure: !_showPw, req: true),

              if (_err.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: const Color(0xFFfef2f2),
                      borderRadius: BorderRadius.circular(10)),
                  child: Text('❌ $_err',
                      style: const TextStyle(
                          color: Colors.red, fontSize: 13)),
                ),
              ],
              const SizedBox(height: 20),

              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _register,
                  child: _loading
                      ? const CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2)
                      : const Text('🚀 Account Banao',
                          style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _roleBtn(String label, String val) => Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _role = val),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: _role == val
                  ? AppTheme.green
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color:
                        _role == val ? Colors.white : Colors.grey)),
          ),
        ),
      );

  Widget _field(
    TextEditingController c,
    String label, {
    bool obscure = false,
    TextInputType? keyboard,
    Widget? suffix,
    required bool req,
  }) =>
      TextFormField(
        controller: c,
        obscureText: obscure,
        keyboardType: keyboard,
        validator: req
            ? (v) =>
                (v == null || v.trim().isEmpty) ? '$label required hai' : null
            : null,
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: suffix,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: AppTheme.green, width: 2)),
        ),
      );
}
