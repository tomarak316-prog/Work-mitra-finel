// lib/widgets/category_grid.dart
import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class CategoryGrid extends StatelessWidget {
  const CategoryGrid({super.key});

  static const _cats = [
    {'id':'delivery','icon':'🛵','label':'Delivery','color':0xFFf97316},
    {'id':'driver','icon':'🚗','label':'Driver','color':0xFF3b82f6},
    {'id':'electrician','icon':'⚡','label':'Electrician','color':0xFFeab308},
    {'id':'labour','icon':'🔨','label':'Labour','color':0xFF8b5cf6},
    {'id':'shop','icon':'🏪','label':'Shop','color':0xFFec4899},
    {'id':'office','icon':'💼','label':'Office','color':0xFF06b6d4},
    {'id':'teacher','icon':'📚','label':'Teacher','color':0xFF10b981},
    {'id':'mechanic','icon':'🔧','label':'Mechanic','color':0xFF84cc16},
    {'id':'beauty','icon':'💅','label':'Beauty','color':0xFFc084fc},
    {'id':'data','icon':'📊','label':'Data Entry','color':0xFF7c3aed},
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 104,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemCount: _cats.length,
        itemBuilder: (_, i) {
          final c = _cats[i];
          final col = Color(c['color'] as int);
          return Column(children: [
            Container(
              width: 54, height: 54,
              decoration: BoxDecoration(
                  color: col.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: col.withOpacity(0.25))),
              child: Center(child: Text(c['icon'] as String,
                  style: const TextStyle(fontSize: 24))),
            ),
            const SizedBox(height: 6),
            SizedBox(width: 60,
              child: Text(c['label'] as String,
                  textAlign: TextAlign.center, maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600))),
          ]);
        },
      ),
    );
  }
}
