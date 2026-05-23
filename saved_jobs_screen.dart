// lib/screens/saved/saved_jobs_screen.dart
// STEP 13A — Saved Jobs Screen

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../models/job_model.dart';
import '../../providers/app_provider.dart';
import '../../services/firebase_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/job_card.dart';
import '../jobs/job_detail_screen.dart';

class SavedJobsScreen extends StatelessWidget {
  const SavedJobsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final savedIds = context.watch<AppProvider>().savedJobs;

    return Scaffold(
      backgroundColor: const Color(0xFFf0fdf4),
      appBar: AppBar(
        title: const Text('Saved Jobs ❤️'),
        backgroundColor: AppTheme.green,
        foregroundColor: Colors.white,
      ),
      body: savedIds.isEmpty
          ? _empty()
          : FutureBuilder<List<Job>>(
              future: _fetchSaved(savedIds),
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child:
                      CircularProgressIndicator(color: AppTheme.green));
                }
                final jobs = snap.data ?? [];
                if (jobs.isEmpty) return _empty();
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemCount: jobs.length,
                  itemBuilder: (_, i) => JobCard(
                    job: jobs[i],
                    isSaved: true,
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(
                            builder: (_) => JobDetailScreen(job: jobs[i]))),
                    onSave: () => JobsService.toggleSave(
                        jobs[i].id, saved: true),
                  ),
                );
              },
            ),
    );
  }

  Future<List<Job>> _fetchSaved(Set<String> ids) async {
    final futures = ids.map((id) =>
        FirebaseFirestore.instance.collection('jobs').doc(id).get());
    final snaps = await Future.wait(futures);
    return snaps
        .where((s) => s.exists)
        .map((s) => Job.fromFirestore(s))
        .toList();
  }

  Widget _empty() => const Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('🤍', style: TextStyle(fontSize: 56)),
          SizedBox(height: 12),
          Text('Koi saved job nahi',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          Text('Jobs pe ❤️ press karo save karne ke liye',
              style: TextStyle(color: Colors.grey, fontSize: 13)),
        ]),
      );
}
