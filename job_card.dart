// lib/widgets/job_card.dart
import 'package:flutter/material.dart';
import '../models/job_model.dart';
import '../utils/app_theme.dart';

class JobCard extends StatelessWidget {
  final Job job;
  final bool isSaved;
  final VoidCallback? onTap;
  final VoidCallback? onSave;

  const JobCard({
    super.key,
    required this.job,
    this.isSaved  = false,
    this.onTap,
    this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: job.featured
                  ? AppTheme.green.withOpacity(0.4)
                  : const Color(0xFFe5e7eb)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          // Featured badge
          if (job.featured)
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [
                      AppTheme.greenDark, AppTheme.green
                    ]),
                    borderRadius: BorderRadius.circular(99)),
                child: const Text('⭐ FEATURED',
                    style: TextStyle(color: Colors.white,
                        fontSize: 9, fontWeight: FontWeight.w800)),
              ),
            ),

          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Category emoji
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                  color: AppTheme.greenPale,
                  borderRadius: BorderRadius.circular(14)),
              child: Center(child: Text(job.categoryEmoji,
                  style: const TextStyle(fontSize: 24))),
            ),
            const SizedBox(width: 12),

            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(job.title, style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Row(children: [
                  Flexible(child: Text(job.company,
                      style: const TextStyle(
                          fontSize: 12, color: Colors.grey),
                      overflow: TextOverflow.ellipsis)),
                  if (job.verified) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.verified,
                        color: Colors.blue, size: 14),
                  ],
                ]),
              ],
            )),

            // Save button
            GestureDetector(
              onTap: onSave,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                    isSaved ? Icons.favorite : Icons.favorite_border,
                    color: isSaved ? Colors.red : Colors.grey,
                    size: 22),
              ),
            ),
          ]),

          const SizedBox(height: 10),

          // Chips row
          Wrap(spacing: 6, runSpacing: 6, children: [
            _chip('📍 ${job.city}', AppTheme.green),
            _chip(job.type, Colors.blue),
            if (job.urgent) _chip('🔴 Urgent', Colors.red),
          ]),

          const SizedBox(height: 10),

          Row(children: [
            Text(job.salary,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.green)),
            const Spacer(),
            ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.green,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Apply Now',
                  style: TextStyle(color: Colors.white,
                      fontSize: 12, fontWeight: FontWeight.w800)),
            ),
          ]),

          if (job.applicants > 0) ...[
            const SizedBox(height: 6),
            Text('👥 ${job.applicants} logon ne apply kiya',
                style: const TextStyle(
                    fontSize: 10, color: Colors.grey)),
          ],
        ]),
      ),
    );
  }

  Widget _chip(String label, Color color) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(99)),
        child: Text(label,
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: color)),
      );
}
