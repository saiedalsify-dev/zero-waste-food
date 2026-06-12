# ZeroWaste Food

ZeroWaste Food is a Flutter graduation-project app that connects donors with charity organizations to reduce food waste. It uses Firebase-ready services, Riverpod state management, and a pure Dart rule-based matching algorithm.

## What Is Included

- Email/password authentication for donors, charities, and admins.
- Donation creation, listing, details, status updates, and admin overview.
- Rule-based matching by expiry urgency and quantity, with explainable scores from 0 to 100.
- Rule-based FAQ chatbot with keyword intents only.
- Firebase Cloud Messaging integration points for new donation and status notifications.
- Demo mode that runs without Firebase credentials, so the Android project stays buildable during review.
- Map feature intentionally disabled. Locations are city text with optional coordinates for later Google Maps support.

## Project Structure

```text
lib/
  core/
    config/        App constants, routes, Firebase options
    errors/        App-level exceptions
    providers/     Riverpod dependency providers
    routing/       Material route generation
    services/      Firebase bootstrap
    theme/         Material theme
    utils/         Validators, dates, Firebase value helpers
    widgets/       Reusable UI widgets
  features/
    admin/
    auth/
    chatbot/
    donations/
    home/
    notifications/
    profile/
  models/          AppUser, Donation, Notification, ChatMessage
  services/        Auth, donation, matching, chatbot, notification services
test/
  services_test.dart
  widget_test.dart
```

## Installed Versions

This project was generated with the installed stable Flutter SDK on this machine:

- Flutter 3.35.5
- Dart 3.9.2
- Android Gradle Plugin 8.9.1
- Kotlin 2.1.0
- Gradle 8.12

Do not manually downgrade Gradle, AGP, Kotlin, or Firebase packages unless you have a specific compatibility reason.

## What You Need To Prepare

For local demo/build testing:

1. Flutter SDK installed and available in PATH.
2. Android Studio installed with Android SDK and an emulator or physical Android device.
3. JDK available through Android Studio or your system.

For real Firebase backend:

1. Create a Firebase project.
2. Add an Android app with package name `com.zerowastefood.zero_waste_food`.
3. Enable Authentication, then enable Email/Password sign-in.
4. Create a Cloud Firestore database.
5. Enable Cloud Messaging.
6. Run `dart pub global activate flutterfire_cli` once if FlutterFire CLI is not installed.
7. Run `flutterfire configure --project YOUR_FIREBASE_PROJECT_ID --platforms android`.
8. Replace `lib/core/config/firebase_options.dart` with the generated real options if the CLI does not update it automatically.
9. Put the generated `google-services.json` in `android/app/` if the Firebase console or FlutterFire CLI gives you one.
10. Deploy rules with `firebase deploy --only firestore`.

The app intentionally falls back to demo services while `firebase_options.dart` still contains placeholder values.

## Demo Accounts

When Firebase is not configured, use these demo accounts:

```text
donor@zerowaste.test    password123
charity@zerowaste.test  password123
admin@zerowaste.test    password123
```

## Run The Project

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

Build Android debug APK:

```bash
flutter build apk --debug
```

## Firebase Collections

```text
users
  id, name, email, role, city, phone, fcmToken, createdAt

donations
  donorId, donorName, title, description, quantity, unit, expiryDate,
  city, latitude, longitude, status, acceptedByCharityId,
  acceptedByCharityName, notes, createdAt, updatedAt

notifications
  userId, title, body, type, relatedDonationId, read, createdAt
```

## Matching Algorithm

The matching engine is in `lib/services/matching_service.dart`.

- Expiry urgency weight: 60%.
- Quantity weight: 40%.
- Expired donations score 0 and are excluded from available matching.
- Results are sorted from highest to lowest score.

No machine learning, AI APIs, or external NLP libraries are used.

## Development Phases

1. Firebase Auth and login/register.
2. Donation CRUD and Firestore integration.
3. Matching algorithm.
4. Notifications through Firebase Cloud Messaging.
5. Rule-based chatbot.
6. Google Maps later as a separate phase.
