# Work Mitra — APK Build Guide
# Package: com.workmitra.india | Firebase: work-mitra

## ── Prerequisites ────────────────────────────────────────────────
- Flutter SDK 3.16+ installed
- Android Studio / VS Code
- Java JDK 17
- Firebase project: work-mitra (already configured)

## ── Step 1: Clone & Setup ─────────────────────────────────────────
```bash
cd your_project_folder
flutter pub get
```

## ── Step 2: Place google-services.json ───────────────────────────
Copy google-services.json → android/app/google-services.json
(File already configured for com.workmitra.india)

## ── Step 3: Create asset folders ────────────────────────────────
```bash
mkdir -p assets/images assets/icons
# Place your logo at: assets/images/logo.png
```

## ── Step 4: Firebase Console — Enable These ──────────────────────
1. Authentication → Phone OTP + Email/Password + Google
2. Firestore Database → Create → asia-south1 → Test mode
3. Cloud Messaging → Already enabled
4. Add SHA-1 key for Google Sign-In:
   cd android && ./gradlew signingReport
   Copy SHA1 → Firebase Console → Project Settings → Your Apps

## ── Step 5: Deploy Firestore Rules & Indexes ─────────────────────
```bash
# Install Firebase CLI
npm install -g firebase-tools
firebase login
firebase use work-mitra

# Deploy rules and indexes
firebase deploy --only firestore:rules
firebase deploy --only firestore:indexes
```

## ── Step 6: Run Debug APK ────────────────────────────────────────
```bash
flutter run                          # Run on connected device
flutter build apk --debug            # Debug APK
```

## ── Step 7: Build Release APK ────────────────────────────────────
```bash
# Create keystore (one time only)
keytool -genkey -v -keystore work-mitra-key.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias work-mitra

# Add to android/app/build.gradle signingConfigs
# Then build:
flutter build apk --release
flutter build appbundle --release    # For Play Store

# Output: build/app/outputs/flutter-apk/app-release.apk
```

## ── Admin Setup ───────────────────────────────────────────────────
1. Login with akashtomar7132@gmail.com
2. Firebase Console → Firestore → users → find your uid
3. Add field: role = "admin"
4. Admin tab appears automatically in the app

## ── Firestore Composite Index Error Fix ─────────────────────────
If you see "index required" error in logs:
- Click the link in the error → Firebase auto-creates the index
- OR run: firebase deploy --only firestore:indexes

## ── Package: com.workmitra.india ────────────────────────────────
## ── Firebase App ID: 1:855576854630:android:06b030e7e30b04f3602da7
