// lib/screens/jobs/post_job_screen.dart
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/firebase_service.dart';
import '../../utils/app_theme.dart';

class PostJobScreen extends StatefulWidget {
  const PostJobScreen({super.key});
  @override State<PostJobScreen> createState() => _PostJobScreenState();
}

class _PostJobScreenState extends State<PostJobScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title   = TextEditingController();
  final _company = TextEditingController();
  final _salary  = TextEditingController();
  final _desc    = TextEditingController();
  final _city    = TextEditingController();
  final _phone   = TextEditingController();

  String _category = 'delivery';
  String _type     = 'full-time';
  bool   _urgent   = false;
  bool   _loading  = false;
  List<String> _skills = [];
  final _skillCtrl = TextEditingController();
  double _lat = 28.6139, _lng = 77.2090; // Default Delhi

  final _categories = [
    'delivery','driver','electrician','labour','shop','office',
    'teacher','tailor','mechanic','beauty','hotel','security',
    'construction','online','data',
  ];
  final _types = ['full-time','part-time','daily-wage','contract'];

  Future<void> _getLocation() async {
    try {
      final pos = await UserService.getLocation();
      setState(() { _lat = pos.latitude; _lng = pos.longitude; });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('📍 Location set!'), backgroundColor: AppTheme.green));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await JobsService.post(
        title:       _title.text.trim(),
        company:     _company.text.trim(),
        salary:      _salary.text.trim(),
        category:    _category,
        city:        _city.text.trim(),
        type:        _type,
        description: _desc.text.trim(),
        skills:      _skills,
        phone:       _phone.text.trim(),
        lat:         _lat, lng: _lng,
        urgent:      _urgent,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('✅ Job post kar diya! Admin approve karega.'),
          backgroundColor: AppTheme.green));
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ $e'), backgroundColor: Colors.red));
    } finally { setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf0fdf4),
      appBar: AppBar(
        title: const Text('Job Post Karo 📢'),
        backgroundColor: AppTheme.green,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          _card(children: [
            const Text('Basic Information',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            const SizedBox(height: 14),
            _fld(_title,   'Job Title *', 'Delivery Boy, Electrician…'),
            const SizedBox(height: 12),
            _fld(_company, 'Company Name *', 'Aapki company/shop ka naam'),
            const SizedBox(height: 12),
            _fld(_salary,  'Salary *', '₹15,000/month ya ₹500/day'),
            const SizedBox(height: 12),
            _fld(_phone,   'Contact Number', '+91 XXXXX XXXXX',
                keyboard: TextInputType.phone, required: false),
          ]),
          const SizedBox(height: 12),

          _card(children: [
            const Text('Job Details',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            const SizedBox(height: 14),

            // Category
            DropdownButtonFormField<String>(
              value: _category,
              decoration: _decor('Category *'),
              items: _categories.map((c) => DropdownMenuItem(
                value: c, child: Text(c[0].toUpperCase() + c.substring(1)))).toList(),
              onChanged: (v) => setState(() => _category = v!),
            ),
            const SizedBox(height: 12),

            // Type
            DropdownButtonFormField<String>(
              value: _type,
              decoration: _decor('Job Type *'),
              items: _types.map((t) => DropdownMenuItem(
                value: t, child: Text(t))).toList(),
              onChanged: (v) => setState(() => _type = v!),
            ),
            const SizedBox(height: 12),
            _fld(_city, 'City *', 'Delhi, Mumbai, Jaipur…'),
            const SizedBox(height: 12),

            // Description
            TextFormField(
              controller: _desc,
              maxLines: 4,
              decoration: _decor('Job Description'),
              validator: (v) => null,
            ),
          ]),
          const SizedBox(height: 12),

          // Skills
          _card(children: [
            const Text('Required Skills',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: TextFormField(
                controller: _skillCtrl,
                decoration: _decor('Skill daalo (Enter press karo)'),
                validator: (_) => null,
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
                        borderRadius: BorderRadius.circular(10))),
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
          const SizedBox(height: 12),

          // Location + Options
          _card(children: [
            const Text('Location & Options',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _getLocation,
              icon: const Icon(Icons.my_location, color: Colors.white),
              label: const Text('Current Location Set Karo',
                  style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.green,
                  minimumSize: const Size(double.infinity, 46),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
            ),
            const SizedBox(height: 10),
            Text('📍 Lat: ${_lat.toStringAsFixed(4)}, Lng: ${_lng.toStringAsFixed(4)}',
                style: const TextStyle(fontSize: 11, color: Colors.grey)),
            const SizedBox(height: 12),
            SwitchListTile(
              value: _urgent,
              onChanged: (v) => setState(() => _urgent = v),
              title: const Text('🔴 Urgent Hiring',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: const Text('Urgent badge dikhega'),
              activeColor: AppTheme.green,
              contentPadding: EdgeInsets.zero,
            ),
          ]),
          const SizedBox(height: 20),

          // Submit
          SizedBox(height: 54, child: ElevatedButton(
            onPressed: _loading ? null : _submit,
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.green,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14))),
            child: _loading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('📢 Job Post Karo',
                    style: TextStyle(color: Colors.white,
                        fontWeight: FontWeight.w800, fontSize: 16)),
          )),
          const SizedBox(height: 8),
          const Text('Note: Admin approval ke baad job live hogi',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }

  Widget _card({required List<Widget> children}) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFe5e7eb))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
  );

  Widget _fld(TextEditingController c, String label, String hint,
      {TextInputType? keyboard, bool required = true}) =>
      TextFormField(
        controller: c, keyboardType: keyboard,
        validator: required ? (v) => v!.isEmpty ? '$label required hai' : null : null,
        decoration: _decor(label, hint: hint),
      );

  InputDecoration _decor(String label, {String? hint}) => InputDecoration(
    labelText: label, hintText: hint,
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
