// lib/providers/app_provider.dart
// Global state management for Work Mitra

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';

class AppProvider extends ChangeNotifier {
  // ── User profile cache ────────────────────────────────────────
  Map<String, dynamic> _profile = {};
  Map<String, dynamic> get profile => _profile;

  Set<String> get savedJobs   => Set<String>.from(_profile['savedJobs']   ?? []);
  Set<String> get appliedJobs => Set<String>.from(_profile['appliedJobs'] ?? []);
  String      get userRole    => (_profile['role'] as String?) ?? 'worker';
  String      get plan        => (_profile['subscription'] as String?) ?? 'free';
  bool        get isAdmin     => userRole == 'admin';
  bool        get isEmployer  => userRole == 'employer';

  // ── Unread notification count ─────────────────────────────────
  int _unread = 0;
  int get unread => _unread;

  // ── Init: listen to profile + notif count ────────────────────
  void init() {
    final uid = AuthService.uid;
    if (uid == null) return;

    // Profile stream
    UserService.stream().listen((snap) {
      _profile = snap.data() ?? {};
      notifyListeners();
    });

    // Unread notifications
    FirebaseFirestore.instance
        .collection('notifications')
        .doc(uid)
        .collection('items')
        .where('read', isEqualTo: false)
        .snapshots()
        .listen((snap) {
      _unread = snap.docs.length;
      notifyListeners();
    });
  }

  void reset() {
    _profile = {};
    _unread  = 0;
    notifyListeners();
  }

  bool isSaved(String jobId)   => savedJobs.contains(jobId);
  bool isApplied(String jobId) => appliedJobs.contains(jobId);
}
