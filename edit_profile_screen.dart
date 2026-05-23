// lib/screens/profile/edit_profile_screen.dart
import 'package:flutter/material.dart';
import '../../services/firebase_service.dart';
import '../../utils/app_theme.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> existing;
  const EditProfileScreen({super.key, required this.existing});
  @override State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _name, _phone, _city, _bio;
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  String _role = 'worker';
  final List<String> _skills = [];
  final _skillCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name  = TextEditingController(text: (e['name']  as String?) ?? '');
    _phone = TextEditingController(text: (e['phone'] as String?) ?? '');
    _city  = TextEditingController(text: (e['city']  as String?) ?? '');
    _bio   = TextEditingController(text: (e['bio']   as String?) ?? '');
    _role  = (e['role'] as String?) ?? 'worker';
    final s = e['skills'];
    if (s is List) _skills.addAll(s.cast<String>());
  }

  @override
  void dispose() {
    _name.dispose(); _phone.dispose();
    _city.dispose(); _bio.dispose(); _skillCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await UserService.update({
        'name':   _name.text.trim(),
        'phone':  _phone.text.trim(),
        'city':   _city.text.trim(),
        'bio':    _bio.text.trim(),
        'skills': _skills,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('✅ Profile update ho gaya!'),
          backgroundColor: AppTheme.green,
        ));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('❌ $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf0fdf4),
      appBar: AppBar(
        title: const Text('Profile Edit Karo ✏️'),
        backgroundColor: AppTheme.green,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _loading ? null : _save,
            child: const Text('Save',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          // Avatar placeholder
          Center(
            child: Stack(children: [
              CircleAvatar(
                radius: 48,
                backgroundColor: AppTheme.greenPale,
                child: Text(
                  _name.text.isNotEmpty
                      ? _name.text[0].toUpperCase()
                      : 'U',
                  style: const TextStyle(
                      fontSize: 36,
                      color: AppTheme.green,
                      fontWeight: FontWeight.w800),
                ),
              ),
              Positioned(
                right: 0, bottom: 0,
                child: Container(
                  width: 30, height: 30,
                  decoration: const BoxDecoration(
                      color: AppTheme.green, shape: BoxShape.circle),
                  child: const Icon(Icons.camera_alt,
                      color: Colors.white, size: 16),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 24),

          _card([
            _field(_name,  '👤 Full Name',  required: true),
            const SizedBox(height: 12),
            _field(_phone, '📱 Phone Number',
                keyboard: TextInputType.phone),
            const SizedBox(height: 12),
            _field(_city, '📍 City / Location'),
            const SizedBox(height: 12),
            TextFormField(
              controller: _bio,
              maxLines: 3,
              decoration: _decor('📝 Bio / About'),
            ),
          ]),
          const SizedBox(height: 14),

          // Skills section
          _card([
            const Text('🛠️ Your Skills',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: TextFormField(
                controller: _skillCtrl,
                decoration: _decor('Skill likho…'),
              )),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  final s = _skillCtrl.text.trim();
                  if (s.isNotEmpty) {
                    setState(() { _skills.add(s); _skillCtrl.clear(); });
                  }
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.green,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.all(14)),
                child: const Icon(Icons.add, color: Colors.white),
              ),
            ]),
            if (_skills.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(spacing: 8, runSpacing: 8,
                children: _skills.map((s) => Chip(
                  label: Text(s, style: const TextStyle(fontSize: 12)),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: () => setState(() => _skills.remove(s)),
                  backgroundColor: AppTheme.greenPale,
                )).toList()),
            ],
          ]),
          const SizedBox(height: 20),

          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _loading ? null : _save,
              child: _loading
                  ? const CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2)
                  : const Text('💾 Profile Save Karo',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 15)),
            ),
          ),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }

  Widget _card(List<Widget> children) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFe5e7eb))),
    child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: children),
  );

  Widget _field(TextEditingController c, String label,
      {TextInputType? keyboard, bool required = false}) =>
      TextFormField(
        controller: c,
        keyboardType: keyboard,
        validator: required
            ? (v) => (v == null || v.trim().isEmpty)
                ? '$label required hai'
                : null
            : null,
        decoration: _decor(label),
      );

  InputDecoration _decor(String label) => InputDecoration(
    labelText: label,
    filled: true, fillColor: const Color(0xFFf9fafb),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFe5e7eb))),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFe5e7eb))),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.green, width: 2)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
  );
}
