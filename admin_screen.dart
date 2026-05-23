// lib/screens/admin/admin_screen.dart
// STEP 15 — Full Admin Panel v2

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firebase_service.dart';
import '../../utils/app_theme.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});
  @override State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  Map<String, int> _stats = {};
  bool _statsLoading = true;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
    _loadStats();
  }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  Future<void> _loadStats() async {
    final s = await AdminService.stats();
    if (mounted) setState(() { _stats = s; _statsLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf0fdf4),
      appBar: AppBar(
        title: const Text('Admin Panel 🛡️'),
        backgroundColor: const Color(0xFF1e3a5f),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(icon: const Icon(Icons.refresh),
              onPressed: () { setState(() => _statsLoading = true); _loadStats(); }),
        ],
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          isScrollable: true,
          tabs: const [
            Tab(text: '📊 Dashboard'),
            Tab(text: '💼 Jobs'),
            Tab(text: '👥 Users'),
            Tab(text: '📢 Broadcast'),
          ],
        ),
      ),
      body: TabBarView(controller: _tabs, children: [
        _DashboardTab(stats: _stats, loading: _statsLoading),
        const _JobsTab(),
        const _UsersTab(),
        const _BroadcastTab(),
      ]),
    );
  }
}

// ── Dashboard Tab ─────────────────────────────────────────────────
class _DashboardTab extends StatelessWidget {
  final Map<String, int> stats;
  final bool loading;
  const _DashboardTab({required this.stats, required this.loading});

  @override
  Widget build(BuildContext context) {
    final cards = [
      _S('👥', 'Total Users',   stats['users']   ?? 0, Colors.blue),
      _S('💼', 'Active Jobs',   stats['jobs']    ?? 0, AppTheme.green),
      _S('📋', 'Applications',  stats['apps']    ?? 0, Colors.purple),
      _S('⏳', 'Pending Jobs',  stats['pending'] ?? 0, Colors.orange),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        // Stats grid
        GridView.count(
          crossAxisCount: 2, crossAxisSpacing: 12,
          mainAxisSpacing: 12, childAspectRatio: 1.4,
          shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          children: loading
              ? List.generate(4, (_) => _shimmerCard())
              : cards.map((s) => _statCard(s)).toList(),
        ),
        const SizedBox(height: 16),

        // Quick actions
        _section('⚡ Quick Actions', Column(children: [
          _action('✅ Approve All Pending Jobs', Colors.green, () async {
            final snap = await FirebaseFirestore.instance
                .collection('jobs')
                .where('status', isEqualTo: 'pending').get();
            for (final d in snap.docs) {
              await d.reference.update({'status': 'active'});
            }
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('✅ Sare pending jobs approve ho gaye!'),
              backgroundColor: AppTheme.green));
          }),
          const SizedBox(height: 8),
          _action('🗑️ Delete Expired Jobs', Colors.red, () async {
            final now = DateTime.now();
            final snap = await FirebaseFirestore.instance
                .collection('jobs')
                .where('status', isEqualTo: 'active').get();
            int deleted = 0;
            for (final d in snap.docs) {
              final exp = (d.data()['expiresAt'] as Timestamp?)?.toDate();
              if (exp != null && exp.isBefore(now)) {
                await d.reference.delete();
                deleted++;
              }
            }
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('🗑️ $deleted expired jobs delete ho gaye'),
              backgroundColor: Colors.red));
          }),
          const SizedBox(height: 8),
          _action('📊 Export User Data (log)', Colors.blue, () {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Export feature — production mein implement karo')));
          }),
        ])),
        const SizedBox(height: 16),

        // Recent activity
        _section('🕐 Recent Jobs', StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('jobs')
              .orderBy('createdAt', descending: true).limit(5).snapshots(),
          builder: (_, snap) {
            final docs = snap.data?.docs ?? [];
            return Column(children: docs.map((d) {
              final data = d.data();
              final status = (data['status'] as String?) ?? 'pending';
              final color = status == 'active' ? AppTheme.green
                  : status == 'rejected' ? Colors.red : Colors.orange;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                    backgroundColor: color.withOpacity(0.15),
                    child: Text(_emoji(data['category'] as String? ?? ''),
                        style: const TextStyle(fontSize: 18))),
                title: Text((data['title'] as String?) ?? '',
                    style: const TextStyle(fontWeight: FontWeight.w700,
                        fontSize: 13)),
                subtitle: Text('${data['company']} • $status'),
                trailing: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8)),
                    child: Text(status, style: TextStyle(
                        color: color, fontSize: 10,
                        fontWeight: FontWeight.w700))),
              );
            }).toList());
          },
        )),
      ]),
    );
  }

  String _emoji(String cat) => const {
    'delivery': '🛵', 'driver': '🚗', 'electrician': '⚡',
    'labour': '🔨', 'shop': '🏪', 'office': '💼',
  }[cat] ?? '💼';

  Widget _statCard(_S s) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: s.color.withOpacity(0.25))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(s.icon, style: const TextStyle(fontSize: 26)),
      const Spacer(),
      Text('${s.val}', style: TextStyle(
          fontSize: 28, fontWeight: FontWeight.w900, color: s.color)),
      Text(s.label, style: const TextStyle(
          color: Colors.grey, fontSize: 11)),
    ]),
  );

  Widget _shimmerCard() => Container(
    decoration: BoxDecoration(color: const Color(0xFFe5e7eb),
        borderRadius: BorderRadius.circular(16)));

  Widget _section(String title, Widget child) => Container(
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFe5e7eb))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(
          fontWeight: FontWeight.w800, fontSize: 15)),
      const SizedBox(height: 12),
      child,
    ]),
  );

  Widget _action(String label, Color color, VoidCallback onTap) =>
      SizedBox(width: double.infinity, height: 46,
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
              backgroundColor: color.withOpacity(0.1),
              foregroundColor: color,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: color.withOpacity(0.3)))),
          child: Text(label,
              style: TextStyle(fontWeight: FontWeight.w700, color: color)),
        ));
}

class _S { final String icon, label; final int val; final Color color;
  const _S(this.icon, this.label, this.val, this.color); }

// ── Jobs Tab ──────────────────────────────────────────────────────
class _JobsTab extends StatefulWidget {
  const _JobsTab();
  @override State<_JobsTab> createState() => _JobsTabState();
}

class _JobsTabState extends State<_JobsTab> {
  String _filter = 'pending';

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // Filter row
      Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(children: [
          for (final f in ['pending', 'active', 'rejected'])
            Expanded(child: GestureDetector(
              onTap: () => setState(() => _filter = f),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                    color: _filter == f ? const Color(0xFF1e3a5f) : Colors.transparent,
                    borderRadius: BorderRadius.circular(10)),
                child: Text(f, textAlign: TextAlign.center,
                    style: TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 12,
                        color: _filter == f ? Colors.white : Colors.grey)),
              ),
            )),
        ]),
      ),

      Expanded(child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('jobs')
            .where('status', isEqualTo: _filter)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (_, snap) {
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(child: Text('$_filter jobs nahi hain',
                style: const TextStyle(color: Colors.grey)));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final d   = docs[i].data();
              final id  = docs[i].id;
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFe5e7eb))),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text((d['title'] as String?) ?? '',
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 14)),
                    Text('${d['company']} • ${d['city']} • ${d['salary']}',
                        style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    const SizedBox(height: 10),
                    Row(children: [
                      if (_filter == 'pending') ...[
                        _adminBtn('✅ Approve', AppTheme.green, () =>
                            AdminService.setJobStatus(id, 'active')),
                        const SizedBox(width: 8),
                        _adminBtn('❌ Reject', Colors.red, () =>
                            AdminService.setJobStatus(id, 'rejected')),
                      ],
                      if (_filter == 'active')
                        _adminBtn('🚫 Suspend', Colors.orange, () =>
                            AdminService.setJobStatus(id, 'rejected')),
                      if (_filter == 'rejected')
                        _adminBtn('✅ Re-approve', AppTheme.green, () =>
                            AdminService.setJobStatus(id, 'active')),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.red, size: 20),
                        onPressed: () async {
                          await FirebaseFirestore.instance
                              .collection('jobs').doc(id).delete();
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
      )),
    ]);
  }

  Widget _adminBtn(String label, Color color, VoidCallback onTap) =>
      ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
            backgroundColor: color.withOpacity(0.1),
            foregroundColor: color, elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: color.withOpacity(0.4)))),
        child: Text(label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                color: color)),
      );
}

// ── Users Tab ─────────────────────────────────────────────────────
class _UsersTab extends StatefulWidget {
  const _UsersTab();
  @override State<_UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<_UsersTab> {
  String _roleFilter = 'all';

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(children: [
          for (final r in ['all', 'worker', 'employer', 'admin'])
            Expanded(child: GestureDetector(
              onTap: () => setState(() => _roleFilter = r),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                padding: const EdgeInsets.symmetric(vertical: 7),
                decoration: BoxDecoration(
                    color: _roleFilter == r
                        ? const Color(0xFF1e3a5f)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8)),
                child: Text(r, textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: _roleFilter == r
                            ? Colors.white : Colors.grey)),
              ),
            )),
        ]),
      ),
      Expanded(child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _roleFilter == 'all'
            ? AdminService.allUsers()
            : FirebaseFirestore.instance.collection('users')
                .where('role', isEqualTo: _roleFilter)
                .orderBy('createdAt', descending: true).snapshots(),
        builder: (_, snap) {
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('Koi user nahi',
                style: TextStyle(color: Colors.grey)));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final d    = docs[i].data();
              final uid  = docs[i].id;
              final name = (d['name']  as String?) ?? 'User';
              final role = (d['role']  as String?) ?? 'worker';
              final plan = (d['subscription'] as String?) ?? 'free';
              final email = (d['email'] as String?) ?? '';
              final banned = role == 'banned';

              return Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                    color: banned
                        ? const Color(0xFFfef2f2)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: banned
                            ? Colors.red.withOpacity(0.3)
                            : const Color(0xFFe5e7eb))),
                child: Row(children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppTheme.greenPale,
                    child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : 'U',
                        style: const TextStyle(
                            color: AppTheme.green,
                            fontWeight: FontWeight.w800)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 13)),
                      Text(email, style: const TextStyle(
                          color: Colors.grey, fontSize: 11),
                          overflow: TextOverflow.ellipsis),
                      Row(children: [
                        _roleBadge(role),
                        const SizedBox(width: 4),
                        _planBadge(plan),
                      ]),
                    ],
                  )),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert,
                        size: 18, color: Colors.grey),
                    onSelected: (action) async {
                      switch (action) {
                        case 'make_admin':
                          await AdminService.setRole(uid, 'admin'); break;
                        case 'make_worker':
                          await AdminService.setRole(uid, 'worker'); break;
                        case 'make_employer':
                          await AdminService.setRole(uid, 'employer'); break;
                        case 'ban':
                          await AdminService.setRole(uid, 'banned'); break;
                        case 'unban':
                          await AdminService.setRole(uid, 'worker'); break;
                      }
                    },
                    itemBuilder: (_) => [
                      if (!banned) ...[
                        const PopupMenuItem(value: 'make_admin',
                            child: Text('🛡️ Make Admin')),
                        const PopupMenuItem(value: 'make_worker',
                            child: Text('👷 Make Worker')),
                        const PopupMenuItem(value: 'make_employer',
                            child: Text('🏢 Make Employer')),
                        const PopupMenuItem(value: 'ban',
                            child: Text('🚫 Ban User')),
                      ] else
                        const PopupMenuItem(value: 'unban',
                            child: Text('✅ Unban User')),
                    ],
                  ),
                ]),
              );
            },
          );
        },
      )),
    ]);
  }

  Widget _roleBadge(String r) {
    final color = r == 'admin' ? Colors.purple
        : r == 'employer' ? Colors.blue
        : r == 'banned' ? Colors.red : AppTheme.green;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6)),
      child: Text(r, style: TextStyle(
          fontSize: 9, color: color, fontWeight: FontWeight.w700)));
  }

  Widget _planBadge(String p) {
    final color = p == 'premium' ? Colors.amber
        : p == 'basic' ? Colors.blue : Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6)),
      child: Text(p, style: TextStyle(
          fontSize: 9, color: color, fontWeight: FontWeight.w700)));
  }
}

// ── Broadcast Tab ─────────────────────────────────────────────────
class _BroadcastTab extends StatefulWidget {
  const _BroadcastTab();
  @override State<_BroadcastTab> createState() => _BroadcastTabState();
}

class _BroadcastTabState extends State<_BroadcastTab> {
  final _title   = TextEditingController();
  final _body    = TextEditingController();
  final _city    = TextEditingController();
  bool _loading  = false;
  String _target = 'all';

  @override
  void dispose() {
    _title.dispose(); _body.dispose(); _city.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_title.text.trim().isEmpty || _body.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Title aur message bharo')));
      return;
    }
    setState(() => _loading = true);
    try {
      await FirebaseFirestore.instance.collection('admin_broadcasts').add({
        'title':     _title.text.trim(),
        'body':      _body.text.trim(),
        'city':      _city.text.trim().isEmpty ? null : _city.text.trim(),
        'target':    _target,
        'status':    'pending',
        'sentBy':    AuthService.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });
      _title.clear(); _body.clear(); _city.clear();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('📢 Broadcast scheduled!'),
        backgroundColor: AppTheme.green));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Target selector
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFe5e7eb))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('📢 Push Notification Bhejo',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            const SizedBox(height: 14),
            const Text('Target Users:',
                style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Row(children: [
              for (final t in ['all', 'workers', 'employers'])
                Expanded(child: GestureDetector(
                  onTap: () => setState(() => _target = t),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                        color: _target == t
                            ? const Color(0xFF1e3a5f)
                            : const Color(0xFFf0fdf4),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: _target == t
                                ? const Color(0xFF1e3a5f)
                                : const Color(0xFFe5e7eb))),
                    child: Text(t, textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _target == t
                                ? Colors.white : Colors.grey)),
                  ),
                )),
            ]),
            const SizedBox(height: 14),
            _field(_title, '📌 Notification Title'),
            const SizedBox(height: 10),
            TextFormField(
              controller: _body, maxLines: 3,
              decoration: _decor('📝 Message'),
            ),
            const SizedBox(height: 10),
            _field(_city, '🏙️ City (optional — empty = sabko bhejo)'),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton.icon(
                onPressed: _loading ? null : _send,
                icon: const Icon(Icons.send, color: Colors.white),
                label: _loading
                    ? const CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2)
                    : const Text('Notification Bhejo',
                        style: TextStyle(color: Colors.white,
                            fontWeight: FontWeight.w800)),
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1e3a5f),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
              ),
            ),
          ]),
        ),

        const SizedBox(height: 16),

        // Broadcast history
        const Text('📜 Recent Broadcasts',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
        const SizedBox(height: 10),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('admin_broadcasts')
              .orderBy('createdAt', descending: true)
              .limit(10).snapshots(),
          builder: (_, snap) {
            final docs = snap.data?.docs ?? [];
            if (docs.isEmpty) {
              return const Text('Abhi koi broadcast nahi bheja',
                  style: TextStyle(color: Colors.grey));
            }
            return Column(children: docs.map((d) {
              final data = d.data();
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFe5e7eb))),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text((data['title'] as String?) ?? '',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700)),
                    Text((data['body'] as String?) ?? '',
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 12)),
                    const SizedBox(height: 4),
                    Row(children: [
                      _chip('→ ${data['target'] ?? 'all'}', Colors.blue),
                      const SizedBox(width: 6),
                      _chip(data['status'] ?? 'pending', AppTheme.green),
                    ]),
                  ],
                ),
              );
            }).toList());
          },
        ),
      ]),
    );
  }

  Widget _field(TextEditingController c, String label) =>
      TextFormField(controller: c, decoration: _decor(label));

  InputDecoration _decor(String label) => InputDecoration(
    labelText: label, filled: true,
    fillColor: const Color(0xFFf9fafb),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFe5e7eb))),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFe5e7eb))),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF1e3a5f), width: 2)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
  );

  Widget _chip(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6)),
    child: Text(label, style: TextStyle(
        fontSize: 10, color: color, fontWeight: FontWeight.w700)));
}
