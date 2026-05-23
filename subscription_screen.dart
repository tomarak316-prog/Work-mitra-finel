// lib/screens/subscription/subscription_screen.dart
import 'package:flutter/material.dart';
import '../../services/firebase_service.dart';
import '../../utils/app_theme.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});
  @override State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  String _currentPlan = 'free';
  bool   _loading     = false;

  final _plans = [
    {
      'id':       'free',
      'name':     'Free',
      'price':    '₹0',
      'period':   'Hamesha',
      'color':    0xFF6b7280,
      'icon':     '🆓',
      'features': [
        '3 applications per day',
        'Basic job search',
        'Job alerts (limited)',
        'Ad supported',
      ],
      'disabled': [],
    },
    {
      'id':       'basic',
      'name':     'Basic',
      'price':    '₹99',
      'period':   'per month',
      'color':    0xFF3b82f6,
      'icon':     '⭐',
      'features': [
        '20 applications per day',
        'No advertisements',
        'Priority job alerts',
        'Resume highlight',
        'WhatsApp support',
      ],
      'disabled': [],
    },
    {
      'id':       'premium',
      'name':     'Premium',
      'price':    '₹299',
      'period':   'per month',
      'color':    0xFF16a34a,
      'icon':     '💎',
      'features': [
        'Unlimited applications',
        'No advertisements',
        'Featured profile badge',
        'AI job matching',
        'Priority employer view',
        'Dedicated support',
        'Early access to jobs',
      ],
      'disabled': [],
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadPlan();
  }

  Future<void> _loadPlan() async {
    final p = await UserService.profile();
    if (mounted) {
      setState(() => _currentPlan = (p?['subscription'] as String?) ?? 'free');
    }
  }

  Future<void> _upgrade(String planId, String price) async {
    if (planId == _currentPlan) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Text('$price plan upgrade karo?'),
        content: Text(
            'Razorpay se payment karein.\n\n'
            'Demo mode mein directly activate ho jayega.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.green),
            child: const Text('Upgrade Karo',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() => _loading = true);
    try {
      // In production: integrate Razorpay here, then call activate()
      // For demo: activate directly
      await UserService.update({
        'subscription': planId,
        'subscriptionExpiry': DateTime.now()
            .add(const Duration(days: 30))
            .toIso8601String(),
      });
      setState(() { _currentPlan = planId; _loading = false; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('🎉 ${planId.toUpperCase()} plan activate ho gaya!'),
          backgroundColor: AppTheme.green,
        ));
      }
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('❌ Error: $e'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf0fdf4),
      appBar: AppBar(
        title: const Text('Premium Plans 💎'),
        backgroundColor: AppTheme.green,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.green))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [
                      Color(0xFF15803d), Color(0xFF22c55e)
                    ]),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(children: [
                    const Text('🚀', style: TextStyle(fontSize: 36)),
                    const SizedBox(height: 8),
                    const Text('Apna plan upgrade karo',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text('Current: ${_currentPlan.toUpperCase()}',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 13)),
                  ]),
                ),

                // Plan cards
                ..._plans.map((plan) {
                  final id      = plan['id'] as String;
                  final color   = Color(plan['color'] as int);
                  final isCurr  = id == _currentPlan;
                  final feats   = plan['features'] as List;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: isCurr ? color : const Color(0xFFe5e7eb),
                          width: isCurr ? 2.5 : 1),
                      boxShadow: isCurr
                          ? [BoxShadow(
                              color: color.withOpacity(0.15),
                              blurRadius: 16,
                              offset: const Offset(0, 4))]
                          : [],
                    ),
                    child: Column(children: [
                      // Plan header
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.08),
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(19)),
                        ),
                        child: Row(children: [
                          Text(plan['icon'] as String,
                              style: const TextStyle(fontSize: 28)),
                          const SizedBox(width: 12),
                          Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(plan['name'] as String,
                                  style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 18, color: color)),
                              Text(plan['period'] as String,
                                  style: const TextStyle(
                                      color: Colors.grey, fontSize: 12)),
                            ],
                          )),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(plan['price'] as String,
                                  style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 22, color: color)),
                              if (isCurr)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                      color: color,
                                      borderRadius: BorderRadius.circular(99)),
                                  child: const Text('Active',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700)),
                                ),
                            ],
                          ),
                        ]),
                      ),

                      // Features
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(children: [
                          ...feats.map((f) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(children: [
                              Icon(Icons.check_circle,
                                  color: color, size: 18),
                              const SizedBox(width: 10),
                              Text(f.toString(),
                                  style: const TextStyle(fontSize: 13)),
                            ]),
                          )),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity, height: 48,
                            child: ElevatedButton(
                              onPressed: isCurr
                                  ? null
                                  : () => _upgrade(
                                      id, plan['price'] as String),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    isCurr ? Colors.grey.shade300 : color,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                              ),
                              child: Text(
                                isCurr
                                    ? '✅ Current Plan'
                                    : 'Upgrade to ${plan['name']}',
                                style: TextStyle(
                                    color: isCurr
                                        ? Colors.grey
                                        : Colors.white,
                                    fontWeight: FontWeight.w800),
                              ),
                            ),
                          ),
                        ]),
                      ),
                    ]),
                  );
                }),

                const SizedBox(height: 8),
                const Text(
                    '🔒 Secure payment via Razorpay\n'
                    'Cancel anytime • Auto-renew monthly',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 20),
              ]),
            ),
    );
  }
}
