// lib/screens/applications/my_applications_screen.dart
// STEP 13B — My Applications with Status Tracking

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firebase_service.dart';
import '../../utils/app_theme.dart';
import '../../models/job_model.dart';
import '../jobs/job_detail_screen.dart';

class MyApplicationsScreen extends StatelessWidget {
  const MyApplicationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf0fdf4),
      appBar: AppBar(
        title: const Text('My Applications 📋'),
        backgroundColor: AppTheme.green,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: JobsService.myApplications(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: AppTheme.green));
          }
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) return _empty();

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final d     = docs[i].data();
              final jobId = (d['jobId']  as String?) ?? '';
              final status = (d['status'] as String?) ?? 'pending';
              final msg    = (d['message'] as String?) ?? '';
              final ts     = (d['appliedAt'] as Timestamp?)?.toDate();

              return FutureBuilder<DocumentSnapshot<Map<String,dynamic>>>(
                future: FirebaseFirestore.instance
                    .collection('jobs').doc(jobId).get(),
                builder: (_, jSnap) {
                  final jd = jSnap.data?.data() ?? {};
                  final title   = (jd['title']   as String?) ?? 'Job';
                  final company = (jd['company'] as String?) ?? '';
                  final salary  = (jd['salary']  as String?) ?? '';
                  final cat     = (jd['category'] as String?) ?? '';

                  // status color
                  final statusColor = status == 'accepted'
                      ? AppTheme.green
                      : status == 'rejected'
                          ? Colors.red
                          : Colors.orange;
                  final statusIcon = status == 'accepted'
                      ? '✅' : status == 'rejected' ? '❌' : '⏳';

                  return GestureDetector(
                    onTap: () {
                      if (!jSnap.hasData || !jSnap.data!.exists) return;
                      Navigator.push(context, MaterialPageRoute(
                          builder: (_) => JobDetailScreen(
                              job: Job.fromFirestore(jSnap.data!))));
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                              color: statusColor.withOpacity(0.3))),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Container(
                              width: 42, height: 42,
                              decoration: BoxDecoration(
                                  color: AppTheme.greenPale,
                                  borderRadius: BorderRadius.circular(12)),
                              child: Center(child: Text(
                                _catEmoji(cat),
                                style: const TextStyle(fontSize: 22))),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(title, style: const TextStyle(
                                    fontWeight: FontWeight.w800, fontSize: 14)),
                                Text(company, style: const TextStyle(
                                    color: Colors.grey, fontSize: 12)),
                                Text(salary, style: const TextStyle(
                                    color: AppTheme.green,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12)),
                              ],
                            )),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10)),
                              child: Text('$statusIcon $status',
                                  style: TextStyle(
                                      color: statusColor,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11)),
                            ),
                          ]),

                          // Progress bar
                          const SizedBox(height: 12),
                          _StatusProgress(status: status),

                          if (msg.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                  color: const Color(0xFFf0fdf4),
                                  borderRadius: BorderRadius.circular(8)),
                              child: Text('"$msg"',
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                      fontStyle: FontStyle.italic)),
                            ),
                          ],

                          if (ts != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              'Applied: ${ts.day}/${ts.month}/${ts.year}',
                              style: const TextStyle(
                                  fontSize: 10, color: Colors.grey)),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  String _catEmoji(String cat) => const {
    'delivery': '🛵', 'driver': '🚗', 'electrician': '⚡',
    'labour': '🔨', 'shop': '🏪', 'office': '💼',
    'teacher': '📚', 'tailor': '🪡', 'mechanic': '🔧',
    'beauty': '💅', 'hotel': '🍽️', 'security': '🛡️',
    'construction': '🏗️', 'online': '💻', 'data': '📊',
  }[cat] ?? '💼';

  Widget _empty() => const Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('📋', style: TextStyle(fontSize: 56)),
          SizedBox(height: 12),
          Text('Koi application nahi',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          Text('Jobs pe "Apply Now" press karo',
              style: TextStyle(color: Colors.grey, fontSize: 13)),
        ]),
      );
}

class _StatusProgress extends StatelessWidget {
  final String status;
  const _StatusProgress({required this.status});

  @override
  Widget build(BuildContext context) {
    final steps = ['Applied', 'Viewed', 'Shortlisted', 'Decision'];
    final idx = status == 'pending'
        ? 0 : status == 'viewed'
            ? 1 : status == 'accepted'
                ? 3 : status == 'rejected' ? 3 : 0;

    return Row(children: List.generate(steps.length * 2 - 1, (i) {
      if (i.isOdd) {
        // connector line
        final filled = i ~/ 2 < idx;
        return Expanded(child: Container(
            height: 2,
            color: filled ? AppTheme.green : const Color(0xFFe5e7eb)));
      }
      final stepIdx = i ~/ 2;
      final done = stepIdx <= idx;
      final isRejected = status == 'rejected' && stepIdx == idx;
      return Column(children: [
        Container(
          width: 22, height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isRejected
                ? Colors.red
                : done
                    ? AppTheme.green
                    : const Color(0xFFe5e7eb),
          ),
          child: Icon(
              isRejected
                  ? Icons.close
                  : done ? Icons.check : Icons.circle,
              size: 12,
              color: done || isRejected ? Colors.white : Colors.grey),
        ),
        const SizedBox(height: 3),
        Text(steps[stepIdx],
            style: TextStyle(
                fontSize: 8,
                color: done ? AppTheme.green : Colors.grey,
                fontWeight: FontWeight.w600)),
      ]);
    }));
  }
}
