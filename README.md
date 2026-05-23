# 💼 Work Mitra — India ka Local Jobs App

**Package:** com.workmitra.india  
**Firebase Project:** work-mitra  
**Version:** 1.0.0

## 🚀 Quick Start

```bash
# 1. Dependencies install karo
flutter pub get

# 2. google-services.json rakho
# android/app/google-services.json  ← aapka file yahan

# 3. Run karo (phone connected hona chahiye)
flutter run

# 4. APK build karo
flutter build apk --release
```

## 📁 Project Structure

```
workmitra/
├── lib/
│   ├── main.dart                    # App entry point
│   ├── firebase_options.dart        # Firebase config
│   ├── models/                      # Data models
│   ├── services/                    # Firebase services
│   ├── providers/                   # State management
│   ├── screens/                     # UI screens
│   │   ├── auth/                   # Login, OTP, Register
│   │   ├── home/                   # Home screen
│   │   ├── jobs/                   # Job detail, post, search, nearby
│   │   ├── chat/                   # Chat list, chat screen
│   │   ├── notifications/          # Notifications
│   │   ├── profile/                # Profile, edit profile
│   │   ├── admin/                  # Admin panel
│   │   ├── employer/               # Employer dashboard
│   │   ├── subscription/           # Plans
│   │   ├── saved/                  # Saved jobs
│   │   ├── applications/           # My applications
│   │   └── onboarding/             # First time flow
│   ├── widgets/                     # Reusable widgets
│   └── utils/                       # Theme, notif helper
├── android/                         # Android config
├── ios/                             # iOS config
├── assets/                          # Images, icons
└── pubspec.yaml                     # Dependencies

## 🔐 Admin Login
Email: akashtomar7132@gmail.com
Password: AKASHTOMAR (+ set role=admin in Firestore)

## 📦 Firebase Setup
1. Firebase Console → Enable Auth (Phone, Email, Google)
2. Create Firestore DB (asia-south1)
3. Enable Cloud Messaging
4. Deploy: firebase deploy --only firestore
```
