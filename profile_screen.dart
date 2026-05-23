// lib/screens/profile/profile_screen.dart — v2
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/firebase_service.dart';
import '../../providers/app_provider.dart';
import '../../utils/app_theme.dart';
import 'edit_profile_screen.dart';
import '../subscription/subscription_screen.dart';
import '../employer/employer_dashboard.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthService.user;
    final prov = context.watch<AppProvider>();
    final data = prov.profile;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Login karo')));
    }

    final name     = (data['name']         as String?) ?? user.displayName ?? 'User';
    final email    = (data['email']        as String?) ?? user.email ?? '';
    final phone    = (data['phone']        as String?) ?? '';
    final role     = (data['role']         as String?) ?? 'worker';
    final plan     = (data['subscription'] as String?) ?? 'free';
    final verified = (data['verified']     as bool?)   ?? false;
    final city     = (data['city']         as String?) ?? '';
    final applied  = prov.appliedJobs.length;
    final saved    = prov.savedJobs.length;

    return Scaffold(
      backgroundColor: const Color(0xFFf0fdf4),
      body: CustomScrollView(slivers: [
        // ── Profile header ──────────────────────────────────
        SliverAppBar(
          expandedHeight: 220,
          pinned: true,
          automaticallyImplyLeading: false,
          backgroundColor: AppTheme.green,
          actions: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Colors.white),
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(
                      builder: (_) =>
                          EditProfileScreen(existing: data))),
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF15803d), Color(0xFF16a34a)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
              ),
              child: SafeArea(child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  // Avatar
                  Stack(children: [
                    CircleAvatar(
                      radius: 38,
                      backgroundColor: Colors.white30,
                      backgroundImage: user.photoURL != null
                          ? NetworkImage(user.photoURL!) : null,
                      child: user.photoURL == null
                          ? Text(
                              name.isNotEmpty
                                  ? name[0].toUpperCase()
                                  : 'U',
                              style: const TextStyle(
                                  fontSize: 32,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800))
                          : null,
                    ),
                    if (verified)
                      Positioned(
                        right: 0, bottom: 0,
                        child: Container(
                          width: 22, height: 22,
                          decoration: const BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle),
                          child: const Icon(Icons.check,
                              color: Colors.white, size: 14),
                        ),
                      ),
                  ]),
                  const SizedBox(height: 10),
                  Text(name, style: const TextStyle(
                      color: Colors.white, fontSize: 20,
                      fontWeight: FontWeight.w800)),
                  Text(
                    city.isNotEmpty ? '📍 $city' :
                    email.isNotEmpty ? email : phone,
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 8),
                  // Badges row
                  Wrap(
                    spacing: 6,
                    children: [
                      _badge(role == 'admin' ? '🛡️ Admin'
                          : role == 'employer' ? '🏢 Employer'
                          : '👷 Worker', Colors.white),
                      _badge(plan == 'premium' ? '💎 Premium'
                          : plan == 'basic' ? '⭐ Basic'
                          : '🆓 Free', Colors.white),
                    ],
                  ),
                ],
              )),
            ),
          ),
        ),

        SliverToBoxAdapter(child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            // ── Stats ──────────────────────────────────────
            Row(children: [
              _statCard('$applied', 'Applied'),
              const SizedBox(width: 10),
              _statCard('$saved', 'Saved'),
              const SizedBox(width: 10),
              _statCard(plan[0].toUpperCase() + plan.substring(1), 'Plan'),
            ]),
            const SizedBox(height: 14),

            // ── Quick actions ──────────────────────────────
            if (role == 'employer')
              _actionCard(
                icon: Icons.business_center,
                label: 'Employer Dashboard',
                subtitle: 'Jobs manage karo, applications dekho',
                color: AppTheme.green,
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(
                        builder: (_) => const EmployerDashboard())),
              ),
            const SizedBox(height: 10),

            // ── Main menu ─────────────────────────────────
            _menuCard([
              _menuItem(Icons.person_outline, 'Edit Profile', () =>
                  Navigator.push(context, MaterialPageRoute(
                      builder: (_) => EditProfileScreen(existing: data)))),
              _menuItem(Icons.description_outlined, 'My Applications', () {}),
              _menuItem(Icons.favorite_border, 'Saved Jobs', () {}),
              _menuItem(Icons.bar_chart_outlined, 'Application Status', () {}),
            ]),
            const SizedBox(height: 10),

            // ── Premium + Settings ─────────────────────────
            _menuCard([
              _menuItem(
                Icons.diamond_outlined,
                plan == 'free'
                    ? 'Upgrade to Premium 🚀'
                    : '${plan[0].toUpperCase()}${plan.substring(1)} Plan Active ✅',
                () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => const SubscriptionScreen())),
                color: AppTheme.green,
              ),
              _menuItem(Icons.notifications_outlined,
                  'Notification Settings', () {}),
              _menuItem(Icons.language, 'Language: Hindi/English', () {}),
              _menuItem(Icons.privacy_tip_outlined, 'Privacy Policy', () {}),
              _menuItem(Icons.help_outline, 'Help & Support', () {}),
              _menuItem(Icons.info_outline, 'About Work Mitra', () {}),
            ]),
            const SizedBox(height: 14),

            // ── Logout ──────────────────────────────────
            SizedBox(
              width: double.infinity, height: 50,
              child: OutlinedButton.icon(
                onPressed: () async {
                  context.read<AppProvider>().reset();
                  await AuthService.signOut();
                },
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text('Logout',
                    style: TextStyle(
                        color: Colors.red, fontWeight: FontWeight.w700)),
                style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14))),
              ),
            ),
            const SizedBox(height: 6),
            const Text('Work Mitra v2.0 • com.workmitra.india',
                style: TextStyle(color: Colors.grey, fontSize: 11)),
            const SizedBox(height: 30),
          ]),
        )),
      ]),
    );
  }

  static Widget _badge(String label, Color c) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
            color: c.withOpacity(0.2),
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: c.withOpacity(0.4))),
        child: Text(label,
            style: TextStyle(color: c, fontSize: 10,
                fontWeight: FontWeight.w700)));

  Widget _statCard(String val, String label) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFe5e7eb))),
      child: Column(children: [
        Text(val, style: const TextStyle(
            fontSize: 18, fontWeight: FontWeight.w900,
            color: AppTheme.green),
            maxLines: 1, overflow: TextOverflow.ellipsis),
        Text(label, style: const TextStyle(
            fontSize: 10, color: Colors.grey)),
      ]),
    ),
  );

  Widget _actionCard({
    required IconData icon, required String label,
    required String subtitle, required Color color,
    required VoidCallback onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(0.3))),
          child: Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                  color: color, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(
                    fontWeight: FontWeight.w800, color: color)),
                Text(subtitle, style: const TextStyle(
                    color: Colors.grey, fontSize: 11)),
              ],
            )),
            Icon(Icons.arrow_forward_ios, color: color, size: 16),
          ]),
        ),
      );

  Widget _menuCard(List<Widget> items) => Container(
    decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFe5e7eb))),
    child: Column(children: items),
  );

  Widget _menuItem(IconData icon, String label, VoidCallback onTap,
      {Color? color}) =>
      ListTile(
        leading: Icon(icon, color: color ?? AppTheme.green, size: 22),
        title: Text(label,
            style: TextStyle(fontWeight: FontWeight.w600,
                fontSize: 13, color: color)),
        trailing: const Icon(Icons.chevron_right,
            size: 18, color: Colors.grey),
        onTap: onTap, dense: true,
      );
}
