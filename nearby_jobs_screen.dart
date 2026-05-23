// lib/screens/jobs/nearby_jobs_screen.dart
// STEP 14 — Nearby Jobs with Location Filter

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/job_model.dart';
import '../../services/firebase_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/job_card.dart';
import 'job_detail_screen.dart';

class NearbyJobsScreen extends StatefulWidget {
  const NearbyJobsScreen({super.key});
  @override State<NearbyJobsScreen> createState() => _NearbyJobsScreenState();
}

class _NearbyJobsScreenState extends State<NearbyJobsScreen> {
  List<Job>   _jobs     = [];
  bool        _loading  = true;
  String      _error    = '';
  double      _radius   = 5.0;   // km
  Position?   _pos;
  String?     _category;

  final _cats = ['All', 'Delivery', 'Driver', 'Electrician',
    'Labour', 'Shop', 'Office', 'Mechanic'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = ''; });
    try {
      final pos = await UserService.location();
      setState(() => _pos = pos);
      final raw = await JobsService.nearby(
        lat: pos.latitude, lng: pos.longitude,
        km: _radius,
        category: (_category == null || _category == 'All')
            ? null : _category!.toLowerCase(),
      );
      if (mounted) {
        setState(() {
          _jobs = raw.map((d) => Job(
            id:          d['id']          as String? ?? '',
            title:       d['title']       as String? ?? '',
            company:     d['company']     as String? ?? '',
            salary:      d['salary']      as String? ?? '',
            category:    d['category']    as String? ?? '',
            city:        d['city']        as String? ?? '',
            type:        d['type']        as String? ?? '',
            description: d['description'] as String? ?? '',
            skills:      List<String>.from(d['skills'] as List? ?? []),
            urgent:      d['urgent']      as bool?   ?? false,
            featured:    d['featured']    as bool?   ?? false,
            verified:    d['verified']    as bool?   ?? false,
            applicants: (d['applicants']  as num?)?.toInt() ?? 0,
            lat:        (d['lat']         as num?)?.toDouble() ?? 0,
            lng:        (d['lng']         as num?)?.toDouble() ?? 0,
          )).toList();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf0fdf4),
      appBar: AppBar(
        title: Text(_pos != null
            ? '📍 Nearby Jobs (${_radius.toInt()} km)'
            : '📍 Nearby Jobs'),
        backgroundColor: AppTheme.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _load),
        ],
      ),
      body: Column(children: [
        // ── Radius slider ──────────────────────────────────
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Text('🎯 Radius: ',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                Text('${_radius.toInt()} km',
                    style: const TextStyle(
                        color: AppTheme.green,
                        fontWeight: FontWeight.w800)),
                const Spacer(),
                if (_pos != null)
                  Text(
                    '${_pos!.latitude.toStringAsFixed(3)}, '
                    '${_pos!.longitude.toStringAsFixed(3)}',
                    style: const TextStyle(
                        fontSize: 10, color: Colors.grey)),
              ]),
              Slider(
                value: _radius,
                min: 1, max: 25,
                divisions: 24,
                activeColor: AppTheme.green,
                label: '${_radius.toInt()} km',
                onChanged: (v) => setState(() => _radius = v),
                onChangeEnd: (_) => _load(),
              ),
              // Category filter chips
              SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  separatorBuilder: (_, __) => const SizedBox(width: 6),
                  itemCount: _cats.length,
                  itemBuilder: (_, i) {
                    final c = _cats[i];
                    final sel = (_category ?? 'All') == c;
                    return ChoiceChip(
                      label: Text(c, style: TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w700,
                          color: sel ? Colors.white : Colors.grey)),
                      selected: sel,
                      onSelected: (_) {
                        setState(() => _category = c == 'All' ? null : c);
                        _load();
                      },
                      selectedColor: AppTheme.green,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        // ── Job list ───────────────────────────────────────
        Expanded(child: _loading
            ? const Center(child:
                CircularProgressIndicator(color: AppTheme.green))
            : _error.isNotEmpty
                ? _errorWidget()
                : _jobs.isEmpty
                    ? _empty()
                    : ListView.separated(
                        padding: const EdgeInsets.all(14),
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemCount: _jobs.length,
                        itemBuilder: (_, i) => JobCard(
                          job: _jobs[i],
                          onTap: () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) =>
                                  JobDetailScreen(job: _jobs[i]))),
                        ),
                      )),
      ]),
    );
  }

  Widget _errorWidget() => Center(child: Padding(
    padding: const EdgeInsets.all(24),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Text('📍', style: TextStyle(fontSize: 48)),
      const SizedBox(height: 12),
      const Text('Location access nahi mili',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      const SizedBox(height: 6),
      Text(_error, style: const TextStyle(color: Colors.grey, fontSize: 12),
          textAlign: TextAlign.center),
      const SizedBox(height: 16),
      ElevatedButton.icon(
        onPressed: _load,
        icon: const Icon(Icons.my_location, color: Colors.white),
        label: const Text('Retry', style: TextStyle(color: Colors.white)),
        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.green),
      ),
    ]),
  ));

  Widget _empty() => Center(child: Column(
    mainAxisAlignment: MainAxisAlignment.center, children: [
      const Text('🔍', style: TextStyle(fontSize: 48)),
      const SizedBox(height: 12),
      Text('${_radius.toInt()} km mein koi job nahi',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      const Text('Radius badhao ya category change karo',
          style: TextStyle(color: Colors.grey, fontSize: 13)),
    ],
  ));
}
