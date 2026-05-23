// lib/screens/chat/chat_list_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firebase_service.dart';
import '../../utils/app_theme.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = AuthService.uid ?? '';
    return Scaffold(
      backgroundColor: const Color(0xFFf0fdf4),
      appBar: AppBar(
        title: const Text('Messages 💬'),
        backgroundColor: AppTheme.green,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('chats')
            .where('participants', arrayContains: uid)
            .orderBy('lastMessageAt', descending: true)
            .snapshots(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: AppTheme.green));
          }
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) return _empty();

          return ListView.separated(
            padding: const EdgeInsets.all(14),
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final d      = docs[i].data();
              final chatId = docs[i].id;
              final otherUid = (d['participants'] as List)
                  .firstWhere((p) => p != uid, orElse: () => '');
              final lastMsg = (d['lastMessage'] as String?) ?? '';
              final jobId   = (d['jobId'] as String?) ?? '';

              return FutureBuilder<Map<String, dynamic>?>(
                future: UserService.profile(otherUid),
                builder: (_, uSnap) {
                  final other = uSnap.data ?? {};
                  final name  = (other['name'] as String?) ?? 'User';
                  return _ChatTile(
                    name:    name,
                    lastMsg: lastMsg,
                    jobId:   jobId,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          chatId:     chatId,
                          otherName:  name,
                          otherUid:   otherUid,
                        ),
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

  Widget _empty() => const Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('💬', style: TextStyle(fontSize: 52)),
          SizedBox(height: 12),
          Text('Koi conversation nahi',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          Text('Job detail se employer ko message karo',
              style: TextStyle(color: Colors.grey, fontSize: 13)),
        ]),
      );
}

class _ChatTile extends StatelessWidget {
  final String name, lastMsg, jobId;
  final VoidCallback onTap;
  const _ChatTile(
      {required this.name, required this.lastMsg,
       required this.jobId, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFe5e7eb))),
          child: Row(children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppTheme.greenPale,
              child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'U',
                  style: const TextStyle(
                      color: AppTheme.green, fontWeight: FontWeight.w800,
                      fontSize: 18)),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 14)),
                const SizedBox(height: 3),
                Text(lastMsg.isEmpty ? 'Conversation start karo…' : lastMsg,
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            )),
            const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
          ]),
        ),
      );
}
