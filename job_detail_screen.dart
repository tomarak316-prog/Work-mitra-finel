// lib/screens/jobs/job_detail_screen.dart
// STEP 16 — Job Detail v2: Share, Report, Chat, Apply Tracking

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/job_model.dart';
import '../../services/firebase_service.dart';
import '../../providers/app_provider.dart';
import '../../utils/app_theme.dart';
import '../chat/chat_screen.dart';

class JobDetailScreen extends StatefulWidget {
  final Job job;
  const JobDetailScreen({super.key, required this.job});
  @override State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  bool _applying  = false;
  String _appMsg  = '';
  bool _reported  = false;

  Job get job => widget.job;

  @override
  Widget build(BuildContext context) {
    final prov    = context.watch<AppProvider>();
    final applied = prov.isApplied(job.id);
    final saved   = prov.isSaved(job.id);

    return Scaffold(
      backgroundColor: const Color(0xFFf0fdf4),
      body: CustomScrollView(slivers: [
        // ── App Bar ──────────────────────────────────────────
        SliverAppBar(
          expandedHeight: 170,
          pinned: true,
          backgroundColor: AppTheme.green,
          actions: [
            IconButton(
              icon: Icon(saved ? Icons.favorite : Icons.favorite_border,
                  color: saved ? Colors.red : Colors.white),
              onPressed: () =>
                  JobsService.toggleSave(job.id, saved: saved),
            ),
            IconButton(
              icon: const Icon(Icons.share_outlined, color: Colors.white),
              onPressed: _share,
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onSelected: (v) {
                if (v == 'report') _showReportDialog();
                if (v == 'copy')   _copyLink();
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'copy',   child: Text('🔗 Link Copy Karo')),
                PopupMenuItem(value: 'report', child: Text('🚩 Fake Job Report Karo')),
              ],
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                    colors: [Color(0xFF15803d), Color(0xFF16a34a)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight)),
              child: SafeArea(child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 52, 20, 16),
                child: Row(children: [
                  Container(
                    width: 56, height: 56,
                    decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(16)),
                    child: Center(child: Text(job.categoryEmoji,
                        style: const TextStyle(fontSize: 30))),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(job.title, style: const TextStyle(
                          color: Colors.white, fontSize: 20,
                          fontWeight: FontWeight.w900)),
                      Row(children: [
                        Text(job.company, style: const TextStyle(
                            color: Colors.white70, fontSize: 13)),
                        if (job.verified) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.verified,
                              color: Colors.lightBlueAccent, size: 14),
                        ],
                      ]),
                      Text('📍 ${job.city}', style: const TextStyle(
                          color: Colors.white60, fontSize: 11)),
                    ],
                  )),
                ]),
              )),
            ),
          ),
        ),

        SliverToBoxAdapter(child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // ── Key info row ─────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFe5e7eb))),
              child: Row(children: [
                _infoCol('💰', job.salary, 'Salary'),
                _divider(),
                _infoCol('⏰', job.type, 'Type'),
                _divider(),
                _infoCol('👥', '${job.applicants}', 'Applied'),
              ]),
            ),
            const SizedBox(height: 14),

            // ── Tags ─────────────────────────────────────────
            Wrap(spacing: 8, runSpacing: 8, children: [
              if (job.urgent)   _tag('🔴 Urgent', Colors.red),
              if (job.featured) _tag('⭐ Featured', AppTheme.green),
              if (job.verified) _tag('✔ Verified', Colors.blue),
              _tag('📂 ${job.category}', Colors.purple),
            ]),
            const SizedBox(height: 14),

            // ── Skills ───────────────────────────────────────
            if (job.skills.isNotEmpty) ...[
              _heading('🛠️ Required Skills'),
              Wrap(spacing: 8, runSpacing: 8,
                children: job.skills.map((s) => Chip(
                  label: Text(s, style: const TextStyle(fontSize: 12)),
                  backgroundColor: AppTheme.greenPale,
                  side: const BorderSide(color: AppTheme.green, width: 0.5),
                )).toList()),
              const SizedBox(height: 14),
            ],

            // ── Description ──────────────────────────────────
            if (job.description.isNotEmpty) ...[
              _heading('📋 Job Description'),
              Text(job.description,
                  style: const TextStyle(color: Colors.black87, height: 1.7)),
              const SizedBox(height: 14),
            ],

            // ── Apply message box ─────────────────────────────
            if (!applied) ...[
              _heading('✍️ Cover Message (optional)'),
              TextFormField(
                maxLines: 3,
                onChanged: (v) => _appMsg = v,
                decoration: InputDecoration(
                  hintText:
                      'Apne baare mein kuch likho — skills, experience…',
                  filled: true, fillColor: Colors.white,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: AppTheme.green, width: 2)),
                ),
              ),
              const SizedBox(height: 14),
            ],

            // ── Reported banner ───────────────────────────────
            if (_reported)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: const Color(0xFFfef2f2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200)),
                child: const Row(children: [
                  Icon(Icons.flag, color: Colors.red, size: 18),
                  SizedBox(width: 8),
                  Text('Report submit ho gaya. Team review karegi.',
                      style: TextStyle(color: Colors.red, fontSize: 12)),
                ]),
              ),

            const SizedBox(height: 80),
          ]),
        )),
      ]),

      // ── Bottom action bar ─────────────────────────────────
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
        decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFe5e7eb)))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Apply button
          SizedBox(
            width: double.infinity, height: 52,
            child: ElevatedButton(
              onPressed: applied || _applying ? null : _apply,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    applied ? Colors.grey.shade300 : AppTheme.green,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14))),
              child: _applying
                  ? const CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2)
                  : Text(
                      applied ? '✅ Applied!' : '⚡ Apply Now',
                      style: TextStyle(
                          color: applied ? Colors.grey : Colors.white,
                          fontWeight: FontWeight.w800, fontSize: 15)),
            ),
          ),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _actionBtn(
                icon: Icons.call,
                label: 'Call',
                color: AppTheme.green,
                onTap: job.phone.isNotEmpty ? _call : null)),
            const SizedBox(width: 8),
            Expanded(child: _actionBtn(
                icon: Icons.chat_bubble_outline,
                label: 'Chat',
                color: Colors.blue,
                onTap: _openChat)),
            const SizedBox(width: 8),
            Expanded(child: _actionBtn(
                label: 'WhatsApp',
                color: const Color(0xFF25d366),
                onTap: job.phone.isNotEmpty ? _whatsapp : null,
                customIcon: const Text('📲', style: TextStyle(fontSize: 16)))),
          ]),
        ]),
      ),
    );
  }

  // ── Actions ───────────────────────────────────────────────
  Future<void> _apply() async {
    setState(() => _applying = true);
    try {
      await JobsService.apply(job.id, msg: _appMsg);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Apply kar diya!'),
            backgroundColor: AppTheme.green));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _applying = false);
    }
  }

  Future<void> _call() async {
    final uri = Uri.parse('tel:${job.phone}');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _whatsapp() async {
    final msg = Uri.encodeComponent(
        'Namaste! Maine Work Mitra pe "${job.title}" job dekha. Interested hoon.');
    final uri =
        Uri.parse('https://wa.me/91${job.phone}?text=$msg');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _share() async {
    final text = '💼 ${job.title} at ${job.company}\n'
        '📍 ${job.city} | 💰 ${job.salary}\n'
        'Work Mitra pe apply karo!';
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('📋 Link clipboard mein copy ho gaya!')));
  }

  Future<void> _copyLink() async {
    await Clipboard.setData(
        ClipboardData(text: 'workmitra://jobs/${job.id}'));
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('🔗 Job link copy ho gaya!')));
  }

  Future<void> _openChat() async {
    if (job.employerId.isEmpty) return;
    final chatId = '${AuthService.uid ?? 'guest'}_${job.employerId}_${job.id}';
    // Create chat doc
    await FirebaseFirestore.instance.collection('chats').doc(chatId).set({
      'participants': [AuthService.uid, job.employerId],
      'jobId':        job.id,
      'lastMessage':  '',
      'lastMessageAt': FieldValue.serverTimestamp(),
      'createdAt':    FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    if (!mounted) return;
    Navigator.push(context, MaterialPageRoute(
        builder: (_) => ChatScreen(
            chatId:    chatId,
            otherName: job.company,
            otherUid:  job.employerId)));
  }

  Future<void> _showReportDialog() async {
    String reason = 'Fake job';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('🚩 Fake Job Report Karo'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Reason select karo:'),
          const SizedBox(height: 10),
          for (final r in ['Fake job', 'Wrong salary', 'Scam', 'Duplicate', 'Other'])
            RadioListTile<String>(
              title: Text(r, style: const TextStyle(fontSize: 13)),
              value: r, groupValue: reason,
              onChanged: (v) => reason = v!,
              activeColor: Colors.red, dense: true,
              contentPadding: EdgeInsets.zero,
            ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Report Bhejo',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await FirebaseFirestore.instance.collection('job_reports').add({
        'jobId':     job.id,
        'reason':    reason,
        'reportedBy': AuthService.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (mounted) setState(() => _reported = true);
    }
  }

  // ── Helpers ───────────────────────────────────────────────
  Widget _heading(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(t, style: const TextStyle(
        fontSize: 14, fontWeight: FontWeight.w800)));

  Widget _infoCol(String icon, String val, String label) => Expanded(
    child: Column(children: [
      Text(icon, style: const TextStyle(fontSize: 18)),
      const SizedBox(height: 4),
      Text(val, style: const TextStyle(
          fontWeight: FontWeight.w800, fontSize: 12),
          maxLines: 2, overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center),
      Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey)),
    ]));

  Widget _divider() => Container(
      width: 1, height: 40, color: const Color(0xFFe5e7eb));

  Widget _tag(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withOpacity(0.3))),
    child: Text(label, style: TextStyle(
        color: color, fontSize: 11, fontWeight: FontWeight.w700)));

  Widget _actionBtn({
    IconData? icon, required String label,
    required Color color, VoidCallback? onTap,
    Widget? customIcon,
  }) =>
      OutlinedButton.icon(
        onPressed: onTap,
        icon: customIcon ?? Icon(icon, size: 16, color: color),
        label: Text(label, style: TextStyle(
            color: color, fontWeight: FontWeight.w700, fontSize: 12)),
        style: OutlinedButton.styleFrom(
            side: BorderSide(color: color.withOpacity(0.5)),
            padding: const EdgeInsets.symmetric(vertical: 10),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10))),
      );
}
