// lib/screens/chat/chat_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firebase_service.dart';
import '../../utils/app_theme.dart';

class ChatScreen extends StatefulWidget {
  final String chatId, otherName, otherUid;
  const ChatScreen({
    super.key,
    required this.chatId,
    required this.otherName,
    required this.otherUid,
  });
  @override State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _ctrl   = TextEditingController();
  final _scroll = ScrollController();
  bool _sending = false;

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    _ctrl.clear();
    setState(() => _sending = true);
    try {
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .collection('messages')
          .add({
        'text':      text,
        'senderId':  AuthService.uid,
        'timestamp': FieldValue.serverTimestamp(),
        'read':      false,
      });
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .update({
        'lastMessage':   text,
        'lastMessageAt': FieldValue.serverTimestamp(),
      });
      // scroll to bottom
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) {
          _scroll.animateTo(_scroll.maxScrollExtent,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut);
        }
      });
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final myUid = AuthService.uid ?? '';
    return Scaffold(
      backgroundColor: const Color(0xFFf0fdf4),
      appBar: AppBar(
        backgroundColor: AppTheme.green,
        foregroundColor: Colors.white,
        title: Row(children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.white30,
            child: Text(
              widget.otherName.isNotEmpty
                  ? widget.otherName[0].toUpperCase()
                  : 'U',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 10),
          Text(widget.otherName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        ]),
        actions: [
          IconButton(icon: const Icon(Icons.call_outlined), onPressed: () {}),
        ],
      ),
      body: Column(children: [
        // ── Messages ──────────────────────────────────────────
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('chats')
                .doc(widget.chatId)
                .collection('messages')
                .orderBy('timestamp')
                .snapshots(),
            builder: (ctx, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator(color: AppTheme.green));
              }
              final docs = snap.data?.docs ?? [];
              if (docs.isEmpty) {
                return const Center(
                    child: Text('Pehla message bhejo 👋',
                        style: TextStyle(color: Colors.grey)));
              }
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (_scroll.hasClients) {
                  _scroll.jumpTo(_scroll.maxScrollExtent);
                }
              });
              return ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                itemCount: docs.length,
                itemBuilder: (_, i) {
                  final d    = docs[i].data();
                  final isMe = (d['senderId'] as String?) == myUid;
                  final text = (d['text'] as String?) ?? '';
                  final ts   = (d['timestamp'] as Timestamp?)?.toDate();
                  return _Bubble(
                      text: text, isMe: isMe, timestamp: ts);
                },
              );
            },
          ),
        ),

        // ── Input bar ─────────────────────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
          color: Colors.white,
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: _ctrl,
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Message likho…',
                  filled: true,
                  fillColor: const Color(0xFFf0fdf4),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none),
                ),
                onSubmitted: (_) => _send(),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _sending ? null : _send,
              child: Container(
                width: 46, height: 46,
                decoration: BoxDecoration(
                    color: AppTheme.green,
                    borderRadius: BorderRadius.circular(23)),
                child: _sending
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.send, color: Colors.white, size: 20),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _Bubble extends StatelessWidget {
  final String text;
  final bool isMe;
  final DateTime? timestamp;
  const _Bubble({required this.text, required this.isMe, this.timestamp});

  @override
  Widget build(BuildContext context) {
    final timeStr = timestamp != null
        ? '${timestamp!.hour.toString().padLeft(2, '0')}:'
          '${timestamp!.minute.toString().padLeft(2, '0')}'
        : '';
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.72),
        decoration: BoxDecoration(
          color: isMe ? AppTheme.green : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft:     const Radius.circular(18),
            topRight:    const Radius.circular(18),
            bottomLeft:  Radius.circular(isMe ? 18 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 18),
          ),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 4,
                offset: const Offset(0, 2))
          ],
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(text,
                style: TextStyle(
                    color: isMe ? Colors.white : Colors.black87,
                    fontSize: 14, height: 1.4)),
            const SizedBox(height: 3),
            Text(timeStr,
                style: TextStyle(
                    color: isMe
                        ? Colors.white70
                        : Colors.grey,
                    fontSize: 10)),
          ],
        ),
      ),
    );
  }
}
