// lib/screens/jobs/search_screen.dart
import 'package:flutter/material.dart';
import '../../models/job_model.dart';
import '../../services/firebase_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/job_card.dart';
import 'job_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _ctrl    = TextEditingController();
  List<Job> _results = [];
  bool _loading  = false;
  bool _searched = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _search(String q) async {
    if (q.trim().isEmpty) return;
    setState(() { _loading = true; _searched = true; });
    try {
      final raw = await JobsService.search(q);
      final jobs = raw.map((d) => Job(
        id:          d['id']          as String? ?? '',
        title:       d['title']       as String? ?? '',
        company:     d['company']     as String? ?? '',
        salary:      d['salary']      as String? ?? '',
        category:    d['category']    as String? ?? '',
        city:        d['city']        as String? ?? '',
        type:        d['type']        as String? ?? '',
        description: d['description'] as String? ?? '',
        skills:      List<String>.from(d['skills'] as List? ?? []),
        phone:       d['phone']       as String? ?? '',
        urgent:      d['urgent']      as bool?   ?? false,
        featured:    d['featured']    as bool?   ?? false,
        verified:    d['verified']    as bool?   ?? false,
        applicants: (d['applicants']  as num?)?.toInt() ?? 0,
      )).toList();
      if (mounted) setState(() { _results = jobs; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf0fdf4),
      appBar: AppBar(
        backgroundColor: AppTheme.green,
        automaticallyImplyLeading: false,
        title: TextField(
          controller: _ctrl,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Job, skill, company dhundo…',
            hintStyle: TextStyle(color: Colors.white60),
            border: InputBorder.none,
            prefixIcon: Icon(Icons.search, color: Colors.white70),
            filled: false,
          ),
          onSubmitted: _search,
        ),
        actions: [
          if (_searched)
            IconButton(
              icon: const Icon(Icons.clear, color: Colors.white),
              onPressed: () {
                _ctrl.clear();
                setState(() { _results = []; _searched = false; });
              },
            ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.green))
          : !_searched
              ? _suggestions()
              : _results.isEmpty
                  ? _empty()
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 10),
                      itemCount: _results.length,
                      itemBuilder: (_, i) => JobCard(
                        job: _results[i],
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    JobDetailScreen(job: _results[i]))),
                      ),
                    ),
    );
  }

  Widget _suggestions() => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          const Text('Popular Searches 🔥',
              style: TextStyle(
                  fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              'Delivery Boy',
              'Electrician',
              'Driver',
              'Data Entry',
              'Shop Helper',
              'Teacher',
              'Security Guard',
              'Labour',
            ]
                .map((q) => ActionChip(
                      label: Text(q,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600)),
                      backgroundColor: AppTheme.greenPale,
                      onPressed: () {
                        _ctrl.text = q;
                        _search(q);
                      },
                    ))
                .toList(),
          ),
        ]),
      );

  Widget _empty() => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('😔', style: TextStyle(fontSize: 48)),
            SizedBox(height: 12),
            Text('Koi job nahi mili',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700)),
            Text('Alag keyword try karo',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
}
