// lib/services/firebase_service.dart
// Work Mitra — Firebase Service (NO Storage)
// Project: work-mitra | Package: com.workmitra.india

import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:geolocator/geolocator.dart';

// ── Constants ─────────────────────────────────────────────────────
const kProjectId     = 'work-mitra';
const kProjectNumber = '855576854630';
const kAppId         = '1:855576854630:android:06b030e7e30b04f3602da7';
const kApiKey        = 'AIzaSyAZ1We0UvucKvPZzp3eoT8aq5jYcBTvOuQ';
const kPackage       = 'com.workmitra.india';
const kAdminEmail    = 'akashtomar7132@gmail.com';

// ── Instances ─────────────────────────────────────────────────────
final _auth   = FirebaseAuth.instance;
final _db     = FirebaseFirestore.instance;
final _fcm    = FirebaseMessaging.instance;
final _google = GoogleSignIn(scopes: ['email', 'profile']);

// ══════════════════════════════════════════════════════════════════
//  AUTH SERVICE
// ══════════════════════════════════════════════════════════════════
class AuthService {
  static User?         get user    => _auth.currentUser;
  static String?       get uid     => _auth.currentUser?.uid;
  static Stream<User?> get stream  => _auth.authStateChanges();

  // ── Phone OTP ─────────────────────────────────────────────────
  static Future<void> sendOTP({
    required String phone,
    required void Function(String vid, int? token) onSent,
    required void Function(String err) onError,
    int? resendToken,
  }) async {
    final number = phone.startsWith('+') ? phone : '+91$phone';
    await _auth.verifyPhoneNumber(
      phoneNumber: number,
      timeout: const Duration(seconds: 60),
      forceResendingToken: resendToken,
      verificationCompleted: (cred) async {
        await _auth.signInWithCredential(cred);
      },
      verificationFailed: (e) => onError(e.message ?? 'OTP failed'),
      codeSent: onSent,
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  static Future<UserCredential> verifyOTP(String vid, String code) async {
    final cred = PhoneAuthProvider.credential(
        verificationId: vid, smsCode: code);
    final result = await _auth.signInWithCredential(cred);
    await _syncProfile(result.user!);
    return result;
  }

  // ── Email/Password ────────────────────────────────────────────
  static Future<UserCredential> loginEmail(
      String email, String password) async {
    return _auth.signInWithEmailAndPassword(
        email: email.trim(), password: password);
  }

  static Future<UserCredential> registerEmail({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) async {
    final r = await _auth.createUserWithEmailAndPassword(
        email: email.trim(), password: password);
    await r.user!.updateDisplayName(name);
    await _syncProfile(r.user!, name: name, phone: phone);
    return r;
  }

  static Future<void> resetPassword(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());

  // ── Google ────────────────────────────────────────────────────
  static Future<UserCredential?> loginGoogle() async {
    final g = await _google.signIn();
    if (g == null) return null;
    final auth = await g.authentication;
    final cred = GoogleAuthProvider.credential(
        accessToken: auth.accessToken, idToken: auth.idToken);
    final r = await _auth.signInWithCredential(cred);
    await _syncProfile(r.user!);
    return r;
  }

  // ── Sign Out ──────────────────────────────────────────────────
  static Future<void> signOut() async {
    await _google.signOut();
    await _auth.signOut();
  }

  // ── Admin check ───────────────────────────────────────────────
  static Future<bool> isAdmin() async {
    if (uid == null) return false;
    final d = await _db.collection('users').doc(uid).get();
    return d.data()?['role'] == 'admin';
  }

  // ── Upsert Firestore profile ──────────────────────────────────
  static Future<void> _syncProfile(User u,
      {String? name, String? phone}) async {
    final token = await _fcm.getToken();
    final ref   = _db.collection('users').doc(u.uid);
    final snap  = await ref.get();
    if (!snap.exists) {
      await ref.set({
        'uid':          u.uid,
        'name':         name ?? u.displayName ?? 'User',
        'email':        u.email ?? '',
        'phone':        phone ?? u.phoneNumber ?? '',
        'photoUrl':     u.photoURL ?? '',
        'role':         u.email == kAdminEmail ? 'admin' : 'worker',
        'verified':     false,
        'subscription': 'free',
        'savedJobs':    <String>[],
        'appliedJobs':  <String>[],
        'fcmToken':     token ?? '',
        'city':         '',
        'lat':          0.0,
        'lng':          0.0,
        'createdAt':    FieldValue.serverTimestamp(),
        'lastSeen':     FieldValue.serverTimestamp(),
      });
    } else {
      await ref.update({
        'fcmToken': token ?? '',
        'lastSeen': FieldValue.serverTimestamp(),
      });
    }
  }

  static Future<void> refreshToken() async {
    if (uid == null) return;
    final t = await _fcm.getToken();
    if (t != null) {
      await _db.collection('users').doc(uid).update({'fcmToken': t});
    }
  }
}

// ══════════════════════════════════════════════════════════════════
//  JOBS SERVICE
// ══════════════════════════════════════════════════════════════════
class JobsService {

  // ── Realtime stream ───────────────────────────────────────────
  static Stream<QuerySnapshot<Map<String, dynamic>>> stream({
    String? category,
    String? city,
    String? type,
    bool urgent = false,
    int  limit  = 30,
  }) {
    Query<Map<String, dynamic>> q = _db
        .collection('jobs')
        .where('status', isEqualTo: 'active')
        .orderBy('featured', descending: true)
        .orderBy('createdAt', descending: true);

    if (category != null) q = q.where('category', isEqualTo: category);
    if (city     != null) q = q.where('city',     isEqualTo: city);
    if (type     != null) q = q.where('type',     isEqualTo: type);
    if (urgent)           q = q.where('urgent',   isEqualTo: true);

    return q.limit(limit).snapshots();
  }

  // ── Nearby (bounding box) ─────────────────────────────────────
  static Future<List<Map<String, dynamic>>> nearby({
    required double lat,
    required double lng,
    double km = 10,
    String? category,
  }) async {
    final dLat = km / 111.0;
    final dLng = km / (111.0 * cos(lat * pi / 180));

    Query<Map<String, dynamic>> q = _db
        .collection('jobs')
        .where('status', isEqualTo: 'active')
        .where('lat', isGreaterThanOrEqualTo: lat - dLat)
        .where('lat', isLessThanOrEqualTo:    lat + dLat)
        .orderBy('lat');

    if (category != null) q = q.where('category', isEqualTo: category);

    final snap = await q.get();
    return snap.docs
        .map((d) => {'id': d.id, ...d.data()})
        .where((j) {
          final jLng = (j['lng'] as num).toDouble();
          return jLng >= lng - dLng && jLng <= lng + dLng;
        })
        .toList();
  }

  // ── Post job ──────────────────────────────────────────────────
  static Future<String> post({
    required String title,
    required String company,
    required String salary,
    required String category,
    required String city,
    required String type,
    required String description,
    required List<String> skills,
    required double lat,
    required double lng,
    String?  phone,
    bool     urgent   = false,
    bool     featured = false,
  }) async {
    final id = AuthService.uid;
    if (id == null) throw Exception('Login required');

    final ref = await _db.collection('jobs').add({
      'title':       title,
      'company':     company,
      'salary':      salary,
      'category':    category,
      'city':        city,
      'type':        type,
      'description': description,
      'skills':      skills,
      'phone':       phone ?? '',
      'lat':         lat,
      'lng':         lng,
      'location':    GeoPoint(lat, lng),
      'urgent':      urgent,
      'featured':    featured,
      'verified':    false,
      'status':      'pending',
      'employerId':  id,
      'applicants':  0,
      'createdAt':   FieldValue.serverTimestamp(),
      'expiresAt':   Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 30))),
    });
    return ref.id;
  }

  // ── Apply ─────────────────────────────────────────────────────
  static Future<void> apply(String jobId, {String msg = ''}) async {
    final id = AuthService.uid;
    if (id == null) throw Exception('Login required');

    final dup = await _db
        .collection('applications')
        .where('jobId',  isEqualTo: jobId)
        .where('userId', isEqualTo: id)
        .limit(1)
        .get();
    if (dup.docs.isNotEmpty) throw Exception('Already applied');

    final batch = _db.batch();
    final aRef  = _db.collection('applications').doc();
    batch.set(aRef, {
      'jobId':     jobId,
      'userId':    id,
      'status':    'pending',
      'message':   msg,
      'appliedAt': FieldValue.serverTimestamp(),
    });
    batch.update(_db.collection('jobs').doc(jobId),
        {'applicants': FieldValue.increment(1)});
    batch.update(_db.collection('users').doc(id),
        {'appliedJobs': FieldValue.arrayUnion([jobId])});
    await batch.commit();
  }

  // ── Save/unsave ───────────────────────────────────────────────
  static Future<void> toggleSave(String jobId, {required bool saved}) async {
    final id = AuthService.uid;
    if (id == null) return;
    await _db.collection('users').doc(id).update({
      'savedJobs': saved
          ? FieldValue.arrayRemove([jobId])
          : FieldValue.arrayUnion([jobId]),
    });
  }

  // ── Search ────────────────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> search(String q) async {
    if (q.trim().isEmpty) return [];
    final lower = q.trim().toLowerCase();
    final snap  = await _db
        .collection('jobs')
        .where('status', isEqualTo: 'active')
        .orderBy('createdAt', descending: true)
        .limit(200)
        .get();
    return snap.docs
        .map((d) => {'id': d.id, ...d.data()})
        .where((j) =>
            '${j['title']} ${j['company']} ${j['category']} ${j['city']}'
                .toLowerCase()
                .contains(lower))
        .toList();
  }

  // ── My applications ───────────────────────────────────────────
  static Stream<QuerySnapshot<Map<String, dynamic>>> myApplications() {
    final id = AuthService.uid ?? '';
    return _db
        .collection('applications')
        .where('userId', isEqualTo: id)
        .orderBy('appliedAt', descending: true)
        .snapshots();
  }
}

// ══════════════════════════════════════════════════════════════════
//  NOTIFICATION SERVICE
// ══════════════════════════════════════════════════════════════════
class NotifService {

  static Future<void> init() async {
    final s = await _fcm.requestPermission(
        alert: true, badge: true, sound: true);
    if (s.authorizationStatus == AuthorizationStatus.denied) return;
    _fcm.onTokenRefresh.listen((_) => AuthService.refreshToken());
    await AuthService.refreshToken();
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> stream() {
    final id = AuthService.uid ?? '';
    return _db
        .collection('notifications')
        .doc(id)
        .collection('items')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots();
  }

  static Future<void> markRead(String notifId) async {
    final id = AuthService.uid;
    if (id == null) return;
    await _db
        .collection('notifications')
        .doc(id)
        .collection('items')
        .doc(notifId)
        .update({'read': true});
  }
}

// ══════════════════════════════════════════════════════════════════
//  USER SERVICE
// ══════════════════════════════════════════════════════════════════
class UserService {

  static Future<Map<String, dynamic>?> profile([String? id]) async {
    final uid = id ?? AuthService.uid;
    if (uid == null) return null;
    final d = await _db.collection('users').doc(uid).get();
    return d.exists ? {'id': d.id, ...d.data()!} : null;
  }

  static Stream<DocumentSnapshot<Map<String, dynamic>>> stream() {
    final uid = AuthService.uid ?? '';
    return _db.collection('users').doc(uid).snapshots();
  }

  static Future<void> update(Map<String, dynamic> data) async {
    final id = AuthService.uid;
    if (id == null) return;
    await _db.collection('users').doc(id).update(data);
  }

  static Future<Position> location() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw Exception('GPS disabled. Settings mein location on karo.');
    }
    var p = await Geolocator.checkPermission();
    if (p == LocationPermission.denied) {
      p = await Geolocator.requestPermission();
    }
    if (p == LocationPermission.deniedForever) {
      throw Exception('Location permission permanently denied.');
    }
    final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    await update({
      'lat': pos.latitude,
      'lng': pos.longitude,
      'location': GeoPoint(pos.latitude, pos.longitude),
    });
    return pos;
  }
}

// ══════════════════════════════════════════════════════════════════
//  ADMIN SERVICE
// ══════════════════════════════════════════════════════════════════
class AdminService {

  static Future<void> setJobStatus(String jobId, String status) async {
    await _db.collection('jobs').doc(jobId).update({
      'status':     status,
      'reviewedAt': FieldValue.serverTimestamp(),
      'reviewedBy': AuthService.uid,
    });
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> pendingJobs() =>
      _db
          .collection('jobs')
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .snapshots();

  static Stream<QuerySnapshot<Map<String, dynamic>>> allUsers() =>
      _db
          .collection('users')
          .orderBy('createdAt', descending: true)
          .snapshots();

  static Future<void> setRole(String uid, String role) =>
      _db.collection('users').doc(uid).update({'role': role});

  static Future<Map<String, int>> stats() async {
    final r = await Future.wait([
      _db.collection('users').count().get(),
      _db.collection('jobs')
          .where('status', isEqualTo: 'active')
          .count()
          .get(),
      _db.collection('applications').count().get(),
      _db.collection('jobs')
          .where('status', isEqualTo: 'pending')
          .count()
          .get(),
    ]);
    return {
      'users':   r[0].count ?? 0,
      'jobs':    r[1].count ?? 0,
      'apps':    r[2].count ?? 0,
      'pending': r[3].count ?? 0,
    };
  }
}
