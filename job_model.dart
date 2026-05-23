// lib/models/job_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Job {
  final String id;
  final String title;
  final String company;
  final String salary;
  final String category;
  final String city;
  final String type;
  final String description;
  final List<String> skills;
  final String phone;
  final double lat;
  final double lng;
  final bool urgent;
  final bool featured;
  final bool verified;
  final String status;
  final String employerId;
  final int applicants;
  final DateTime? createdAt;
  final DateTime? expiresAt;

  const Job({
    required this.id,
    required this.title,
    required this.company,
    required this.salary,
    required this.category,
    required this.city,
    required this.type,
    required this.description,
    required this.skills,
    this.phone      = '',
    this.lat        = 0,
    this.lng        = 0,
    this.urgent     = false,
    this.featured   = false,
    this.verified   = false,
    this.status     = 'active',
    this.employerId = '',
    this.applicants = 0,
    this.createdAt,
    this.expiresAt,
  });

  factory Job.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return Job(
      id:          doc.id,
      title:       (d['title']       as String?) ?? '',
      company:     (d['company']     as String?) ?? '',
      salary:      (d['salary']      as String?) ?? '',
      category:    (d['category']    as String?) ?? '',
      city:        (d['city']        as String?) ?? '',
      type:        (d['type']        as String?) ?? '',
      description: (d['description'] as String?) ?? '',
      skills:      List<String>.from(d['skills'] as List? ?? []),
      phone:       (d['phone']       as String?) ?? '',
      lat:         (d['lat']  as num?)?.toDouble() ?? 0.0,
      lng:         (d['lng']  as num?)?.toDouble() ?? 0.0,
      urgent:      (d['urgent']   as bool?) ?? false,
      featured:    (d['featured'] as bool?) ?? false,
      verified:    (d['verified'] as bool?) ?? false,
      status:      (d['status']   as String?) ?? 'active',
      employerId:  (d['employerId'] as String?) ?? '',
      applicants:  (d['applicants'] as num?)?.toInt() ?? 0,
      createdAt:   (d['createdAt'] as Timestamp?)?.toDate(),
      expiresAt:   (d['expiresAt'] as Timestamp?)?.toDate(),
    );
  }

  // also accept QueryDocumentSnapshot
  factory Job.fromQueryDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    return Job.fromFirestore(doc);
  }

  String get categoryEmoji => const {
    'delivery':     '🛵',
    'driver':       '🚗',
    'electrician':  '⚡',
    'labour':       '🔨',
    'shop':         '🏪',
    'office':       '💼',
    'teacher':      '📚',
    'tailor':       '🪡',
    'mechanic':     '🔧',
    'beauty':       '💅',
    'hotel':        '🍽️',
    'security':     '🛡️',
    'construction': '🏗️',
    'online':       '💻',
    'data':         '📊',
  }[category] ?? '💼';
}
