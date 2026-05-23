// lib/firebase_options.dart
// Auto-configured from google-services.json
// ⚠️ Add to .gitignore — contains API keys

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError('Configure iOS via: flutterfire configure');
      default:
        throw UnsupportedError('Platform not supported');
    }
  }

  // ── com.workmitra.india ───────────────────────────────────────
  static const FirebaseOptions android = FirebaseOptions(
    apiKey:            'AIzaSyAZ1We0UvucKvPZzp3eoT8aq5jYcBTvOuQ',
    appId:             '1:855576854630:android:06b030e7e30b04f3602da7',
    messagingSenderId: '855576854630',
    projectId:         'work-mitra',
    storageBucket:     'work-mitra.firebasestorage.app',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey:            'AIzaSyAZ1We0UvucKvPZzp3eoT8aq5jYcBTvOuQ',
    appId:             '1:855576854630:android:06b030e7e30b04f3602da7',
    messagingSenderId: '855576854630',
    projectId:         'work-mitra',
    storageBucket:     'work-mitra.firebasestorage.app',
    authDomain:        'work-mitra.firebaseapp.com',
  );
}
