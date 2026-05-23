// lib/screens/home/home_screen.dart — v2
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../models/job_model.dart';
import '../../services/firebase_service.dart';
import '../../providers/app_provider.dart';
import '../../utils/app_theme.dart';
import '../jobs/job_detail_screen.dart';
import '../jobs/post_job_screen.dart';
import '../jobs/search_screen.dart';
import '../notifications/notifications_screen.dart';
import '../profile/profile_screen.dart';
import '../chat/chat_list_screen.dart';
import '../admin/admin_screen.dart';
import '../../widgets/job_card.dart';
import '../../widgets/category_grid.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AppProvider>();
    final isAdmin = prov.isAdmin;

    // Dynamic tab list
    final tabs = <Widget>[
      const _HomeTab(),
      const SearchScreen(),
      const ChatListScreen(),
      const NotificationsScreen(),
      const ProfileScreen(),
      if (isAdmin) const AdminScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _tab.clamp(0, tabs.length - 1),
          children: tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab.clamp(0, tabs.length - 1),
        onDestinationSelected: (i) => setState(() => _tab = i),
        backgroundColor: Colors.white,
        indicatorColor: AppTheme.greenPale,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          const NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home, color: AppTheme.green),
              label: 'Home'),
          const NavigationDestination(
              icon: Icon(Icons.search_outlined),
              selectedIcon: Icon(Icons.search, color: AppTheme.green),
              label: 'Search'),
          const NavigationDestination(
              icon: Icon(Icons.chat_bubble_outline),
              selectedIcon:
                  Icon(Icons.chat_bubble, color: AppTheme.green),
              label: 'Chat'),
          NavigationDestination(
              icon: Badge(
                  label: Text('${prov.unread}'),
                  isLabelVisible: prov.unread > 0,
                  child: const Icon(Icons.notifications_outlined)),
              selectedIcon:
                  const Icon(Icons.notifications, color: AppTheme.green),
              label: 'Alerts'),
          const NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person, color: AppTheme.green),
              label: 'Profile'),
          if (isAdmin)
            const NavigationDestination(
                icon: Icon(Icons.admin_panel_settings_outlined),
                selectedIcon: Icon(Icons.admin_panel_settings,
                    color: AppTheme.green),
                label: 'Admin'),
        ],
      ),
      floatingActionButton: _tab == 0
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(
                      builder: (_) => const PostJobScreen())),
              backgroundColor: AppTheme.green,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Post Job',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700)),
            )
          : null,
    );
  }
}

// ── Home Tab ──────────────────────────────────────────────────────
class _HomeTab extends StatefulWidget {
  const _HomeTab();
  @override State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  String _filter = 'All';

  Stream<QuerySnapshot<Map<String, dynamic>>> get _jobStream {
    switch (_filter) {
      case 'Urgent':    return JobsService.stream(urgent: true);
      case 'Part-time': return JobsService.stream(type: 'part-time');
      case 'Full-time': return JobsService.stream(type: 'full-time');
      case 'Daily':     return JobsService.stream(type: 'daily-wage');
      default:          return JobsService.stream();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.user;
    final hour = DateTime.now().hour;
    final greet = hour < 12
        ? 'Suprabhat 🌅'
        : hour < 17 ? 'Namaskar 👋' : 'Shubh Sandhya 🌆';
    final prov = context.watch<AppProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFf0fdf4),
      body: CustomScrollView(slivers: [

        // ── SliverAppBar ─────────────────────────────────────
        SliverAppBar(
          expandedHeight: 190,
          floating: false, pinned: true,
          automaticallyImplyLeading: false,
          backgroundColor: AppTheme.green,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [Color(0xFF15803d), Color(0xFF16a34a),
                    Color(0xFF22c55e)],
                ),
              ),
              child: SafeArea(child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(greet, style: const TextStyle(
                              color: Colors.white70, fontSize: 13)),
                          Text(user?.displayName ?? 'Worker Ji 👷',
                              style: const TextStyle(color: Colors.white,
                                  fontSize: 18, fontWeight: FontWeight.w800)),
                          Text(
                            prov.profile['city'] != null &&
                                (prov.profile['city'] as String).isNotEmpty
                                ? '📍 ${prov.profile['city']}'
                                : '📍 Location set karo',
                            style: const TextStyle(
                                color: Colors.white60, fontSize: 11)),
                        ],
                      )),
                      CircleAvatar(
                        radius: 22, backgroundColor: Colors.white30,
                        backgroundImage: user?.photoURL != null
                            ? NetworkImage(user!.photoURL!) : null,
                        child: user?.photoURL == null
                            ? const Icon(Icons.person,
                                color: Colors.white, size: 26)
                            : null,
                      ),
                    ]),
                    const SizedBox(height: 14),
                    GestureDetector(
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(
                              builder: (_) => const SearchScreen())),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8)]),
                        child: Row(children: [
                          const Icon(Icons.search, color: Colors.grey),
                          const SizedBox(width: 10),
                          const Expanded(child: Text(
                              'Job, skill, company dhundo…',
                              style: TextStyle(
                                  color: Colors.grey, fontSize: 14))),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                                color: AppTheme.green,
                                borderRadius: BorderRadius.circular(8)),
                            child: const Icon(Icons.mic,
                                color: Colors.white, size: 16),
                          ),
                        ]),
                      ),
                    ),
                  ],
                ),
              )),
            ),
          ),
        ),

        // ── Stats ─────────────────────────────────────────────
        SliverToBoxAdapter(child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: Row(children: [
            _statCard('3,847', 'Jobs Today', '🔥'),
            const SizedBox(width: 10),
            _statCard('124', 'Near You', '📍'),
            const SizedBox(width: 10),
            _statCard(
              '${(prov.appliedJobs).length}',
              'Applied', '✅'),
          ]),
        )),

        // ── AI Banner ─────────────────────────────────────────
        SliverToBoxAdapter(child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF15803d), Color(0xFF16a34a)]),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(children: [
              const Text('🤖', style: TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              const Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('AI ne 5 jobs dhundhe aapke liye!',
                      style: TextStyle(color: Colors.white,
                          fontWeight: FontWeight.w800, fontSize: 13)),
                  Text('Profile ke hisaab se best matches',
                      style: TextStyle(
                          color: Colors.white70, fontSize: 11)),
                ],
              )),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                    backgroundColor: Colors.white24,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10))),
                child: const Text('Dekho →',
                    style: TextStyle(color: Colors.white,
                        fontWeight: FontWeight.w700, fontSize: 12)),
              ),
            ]),
          ),
        )),

        // ── Categories ────────────────────────────────────────
        const SliverToBoxAdapter(child: Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text('Categories 📂',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        )),
        const SliverToBoxAdapter(child: CategoryGrid()),

        // ── Filter chips ──────────────────────────────────────
        SliverToBoxAdapter(child: SizedBox(
          height: 46,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemCount: 5,
            itemBuilder: (_, i) {
              final f = ['All', 'Urgent', 'Part-time',
                  'Full-time', 'Daily'][i];
              return ChoiceChip(
                label: Text(f),
                selected: _filter == f,
                onSelected: (_) => setState(() => _filter = f),
                selectedColor: AppTheme.green,
                labelStyle: TextStyle(
                    color: _filter == f ? Colors.white : Colors.grey,
                    fontWeight: FontWeight.w700),
              );
            },
          ),
        )),

        // ── Jobs heading ──────────────────────────────────────
        const SliverToBoxAdapter(child: Padding(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Text('🔥 Trending Jobs',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        )),

        // ── Jobs Realtime Stream ──────────────────────────────
        SliverToBoxAdapter(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _jobStream,
            builder: (ctx, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator(
                      color: AppTheme.green)),
                );
              }
              if (snap.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(20),
                  child: Center(child: Text(
                      'Error: ${snap.error}',
                      style: const TextStyle(color: Colors.red))),
                );
              }
              final docs = snap.data?.docs ?? [];
              if (docs.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: Text(
                      'Abhi koi job nahi 😔\nFilter change karo',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey))),
                );
              }
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemCount: docs.length,
                itemBuilder: (_, i) {
                  final job = Job.fromQueryDoc(docs[i]);
                  return JobCard(
                    job: job,
                    isSaved: prov.isSaved(job.id),
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(
                            builder: (_) => JobDetailScreen(job: job))),
                    onSave: () => JobsService.toggleSave(
                        job.id, saved: prov.isSaved(job.id)),
                  );
                },
              );
            },
          ),
        ),
      ]),
    );
  }

  Widget _statCard(String val, String label, String icon) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFe5e7eb))),
      child: Column(children: [
        Text(icon, style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 4),
        Text(val, style: const TextStyle(
            fontSize: 16, fontWeight: FontWeight.w900,
            color: AppTheme.green)),
        Text(label, style: const TextStyle(
            fontSize: 9, color: Colors.grey)),
      ]),
    ),
  );
}
