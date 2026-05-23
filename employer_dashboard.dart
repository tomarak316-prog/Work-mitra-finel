// lib/screens/employer/employer_dashboard.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firebase_service.dart';
import '../../utils/app_theme.dart';
import '../jobs/post_job_screen.dart';

class EmployerDashboard extends StatefulWidget {
  const EmployerDashboard({super.key});
  @override State<EmployerDashboard> createState() => _EmployerDashboardState();
}

class _EmployerDashboardState extends State<EmployerDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final uid = AuthService.uid ?? '';
    return Scaffold(
      backgroundColor: const Color(0xFFf0fdf4),
      appBar: AppBar(
        title: const Text('Employer Dashboard 🏢'),
        backgroundColor: AppTheme.green,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'My Jobs'),
            Tab(text: 'Applications'),
            Tab(text: 'Analytics'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const PostJobScreen())),
        backgroundColor: AppTheme.green,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Post Job',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: TabBarView(controller: _tabs, children: [
        // ── My Jobs tab ──────────────────────────────────────
        _MyJobsTab(uid: uid),
        // ── Applications tab ─────────────────────────────────
        _ApplicationsTab(uid: uid),
        // ── Analytics tab ────────────────────────────────────
        _AnalyticsTab(uid: uid),
      ]),
    );
  }
}

// ── My Jobs ──────────────────────────────────────────────────────
class _MyJobsTab extends StatelessWidget {
  final String uid;
  const _MyJobsTab({required this.uid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('jobs')
          .where('employerId', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: AppTheme.green));
        }
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('💼', style: TextStyle(fontSize: 48)),
              SizedBox(height: 12),
              Text('Abhi koi job post nahi ki',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              Text('FAB button se job post karo',
                  style: TextStyle(color: Colors.grey)),
            ],
          ));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(14),
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemCount: docs.length,
          itemBuilder: (_, i) {
            final d  = docs[i].data();
            final id = docs[i].id;
            final status = (d['status'] as String?) ?? 'pending';
            final statusColor = status == 'active'
                ? AppTheme.green
                : status == 'rejected'
                    ? Colors.red
                    : Colors.orange;

            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFe5e7eb))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(child: Text(
                        (d['title'] as String?) ?? '',
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 14))),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(99)),
                      child: Text(status,
                          style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 11)),
                    ),
                  ]),
                  const SizedBox(height: 4),
                  Text('${d['company']} • ${d['city']}',
                      style: const TextStyle(
                          color: Colors.grey, fontSize: 12)),
                  Text((d['salary'] as String?) ?? '',
                      style: const TextStyle(
                          color: AppTheme.green,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  Row(children: [
                    _infoChip('👥 ${d['applicants'] ?? 0} applied',
                        Colors.blue),
                    const SizedBox(width: 8),
                    _infoChip((d['urgent'] as bool? ?? false)
                        ? '🔴 Urgent' : '⏱ Normal',
                        (d['urgent'] as bool? ?? false)
                            ? Colors.red : Colors.grey),
                    const Spacer(),
                    // Delete job
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: Colors.red, size: 20),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Job delete karo?'),
                            actions: [
                              TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Cancel')),
                              ElevatedButton(
                                  onPressed: () =>
                                      Navigator.pop(context, true),
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red),
                                  child: const Text('Delete',
                                      style: TextStyle(
                                          color: Colors.white))),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await FirebaseFirestore.instance
                              .collection('jobs')
                              .doc(id)
                              .delete();
                        }
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ]),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _infoChip(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(99)),
        child: Text(label,
            style: TextStyle(
                color: color, fontSize: 10, fontWeight: FontWeight.w700)),
      );
}

// ── Applications tab ──────────────────────────────────────────────
class _ApplicationsTab extends StatelessWidget {
  final String uid;
  const _ApplicationsTab({required this.uid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('applications')
          .orderBy('appliedAt', descending: true)
          .snapshots(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: AppTheme.green));
        }
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(
              child: Text('Koi application nahi aayi abhi',
                  style: TextStyle(color: Colors.grey)));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(14),
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemCount: docs.length,
          itemBuilder: (_, i) {
            final d       = docs[i].data();
            final appId   = docs[i].id;
            final userId  = (d['userId'] as String?) ?? '';
            final status  = (d['status'] as String?) ?? 'pending';

            return FutureBuilder<Map<String, dynamic>?>(
              future: UserService.profile(userId),
              builder: (_, uSnap) {
                final u    = uSnap.data ?? {};
                final name = (u['name'] as String?) ?? 'Applicant';
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border:
                          Border.all(color: const Color(0xFFe5e7eb))),
                  child: Row(children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: AppTheme.greenPale,
                      child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : 'A',
                          style: const TextStyle(
                              color: AppTheme.green,
                              fontWeight: FontWeight.w800)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: const TextStyle(
                            fontWeight: FontWeight.w700)),
                        Text((u['phone'] as String?) ?? '',
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 12)),
                        if ((d['message'] as String? ?? '').isNotEmpty)
                          Text('"${d['message']}"',
                              style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 11,
                                  fontStyle: FontStyle.italic)),
                      ],
                    )),
                    PopupMenuButton<String>(
                      onSelected: (s) async {
                        await FirebaseFirestore.instance
                            .collection('applications')
                            .doc(appId)
                            .update({'status': s});
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                            value: 'accepted',
                            child: Text('✅ Accept')),
                        const PopupMenuItem(
                            value: 'rejected',
                            child: Text('❌ Reject')),
                        const PopupMenuItem(
                            value: 'pending',
                            child: Text('⏳ Pending')),
                      ],
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                            color: (status == 'accepted'
                                    ? AppTheme.green
                                    : status == 'rejected'
                                        ? Colors.red
                                        : Colors.orange)
                                .withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8)),
                        child: Text(status,
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: status == 'accepted'
                                    ? AppTheme.green
                                    : status == 'rejected'
                                        ? Colors.red
                                        : Colors.orange)),
                      ),
                    ),
                  ]),
                );
              },
            );
          },
        );
      },
    );
  }
}

// ── Analytics tab ─────────────────────────────────────────────────
class _AnalyticsTab extends StatelessWidget {
  final String uid;
  const _AnalyticsTab({required this.uid});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance
          .collection('jobs')
          .where('employerId', isEqualTo: uid)
          .get(),
      builder: (ctx, snap) {
        if (!snap.hasData) {
          return const Center(
              child: CircularProgressIndicator(color: AppTheme.green));
        }
        final jobs = snap.data!.docs;
        final totalJobs = jobs.length;
        final totalApps = jobs.fold<int>(
            0, (s, d) => s + ((d.data()['applicants'] as num?)?.toInt() ?? 0));
        final activeJobs = jobs
            .where((d) => d.data()['status'] == 'active')
            .length;
        final urgentJobs = jobs
            .where((d) => d.data()['urgent'] == true)
            .length;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            // Stats grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.3,
              children: [
                _statCard('📋', 'Total Jobs', '$totalJobs',
                    AppTheme.green),
                _statCard('👥', 'Applications', '$totalApps',
                    Colors.blue),
                _statCard('✅', 'Active Jobs', '$activeJobs',
                    Colors.teal),
                _statCard('🔴', 'Urgent Jobs', '$urgentJobs',
                    Colors.red),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFe5e7eb))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('📈 Tips',
                      style: TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 15)),
                  const SizedBox(height: 12),
                  ...const [
                    '✅ Urgent tag se 3x zyada views milte hain',
                    '📍 Location sahi bharke nearby workers tak pahuncho',
                    '💰 Salary range clearly likhne se 2x applications aate hain',
                    '📞 Contact number se direct calls enable hota hai',
                    '⭐ Premium plan se featured listing milti hai',
                  ].map((t) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text('  $t',
                            style: const TextStyle(
                                fontSize: 13, height: 1.5)),
                      )),
                ],
              ),
            ),
          ]),
        );
      },
    );
  }

  Widget _statCard(String icon, String label, String val, Color color) =>
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.3))),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          Text(icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 6),
          Text(val,
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: color)),
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: Colors.grey)),
        ]),
      );
}
