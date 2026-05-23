// lib/screens/notifications/notifications_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firebase_service.dart';
import '../../utils/app_theme.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf0fdf4),
      appBar: AppBar(
        title: const Text('Notifications 🔔'),
        backgroundColor: AppTheme.green,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: () async {
              final uid = AuthService.uid;
              if (uid == null) return;
              final snap = await FirebaseFirestore.instance
                  .collection('notifications')
                  .doc(uid)
                  .collection('items')
                  .where('read', isEqualTo: false)
                  .get();
              for (final doc in snap.docs) {
                await doc.reference.update({'read': true});
              }
            },
            child: const Text('Sab padha',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: AuthService.uid == null
          ? _loginPrompt()
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: NotifService.stream(),
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(
                          color: AppTheme.green));
                }
                if (snap.hasError) {
                  return Center(
                      child: Text('Error: ${snap.error}',
                          style:
                              const TextStyle(color: Colors.red)));
                }
                final docs = snap.data?.docs ?? [];
                if (docs.isEmpty) return _empty();

                return ListView.separated(
                  padding: const EdgeInsets.all(14),
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: 8),
                  itemCount: docs.length,
                  itemBuilder: (_, i) {
                    final d   = docs[i].data();
                    final id  = docs[i].id;
                    final unread = !(d['read'] as bool? ?? false);
                    return _NotifCard(
                      icon:   d['icon']  as String? ?? '🔔',
                      title:  d['title'] as String? ?? '',
                      body:   d['body']  as String? ?? '',
                      time:   d['time']  as String? ?? '',
                      unread: unread,
                      onTap:  () => NotifService.markRead(id),
                    );
                  },
                );
              },
            ),
    );
  }

  static Widget _loginPrompt() => const Center(
        child: Text('Login karo notifications dekhne ke liye',
            style: TextStyle(color: Colors.grey)),
      );

  static Widget _empty() => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('🔕', style: TextStyle(fontSize: 48)),
            SizedBox(height: 12),
            Text('Abhi koi notification nahi',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700)),
            Text('Job alerts yahan aayenge',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
}

// ── Individual notification card ──────────────────────────────────
class _NotifCard extends StatelessWidget {
  final String icon, title, body, time;
  final bool unread;
  final VoidCallback? onTap;

  const _NotifCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.time,
    this.unread = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: unread
                    ? AppTheme.green.withOpacity(0.4)
                    : const Color(0xFFe5e7eb)),
          ),
          child:
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                  color: AppTheme.greenPale,
                  borderRadius: BorderRadius.circular(13)),
              child: Center(
                  child: Text(icon,
                      style: const TextStyle(fontSize: 22))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(
                      child: Text(title,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13)),
                    ),
                    if (unread)
                      Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                              color: AppTheme.green,
                              borderRadius:
                                  BorderRadius.circular(4))),
                  ]),
                  const SizedBox(height: 3),
                  Text(body,
                      style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                          height: 1.4)),
                  const SizedBox(height: 4),
                  Text(time,
                      style: const TextStyle(
                          color: Colors.grey, fontSize: 10)),
                ],
              ),
            ),
          ]),
        ),
      );
}
