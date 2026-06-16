# Solaina

A household app for a four-person home: shared expenses with balances, a
shared grocery list, and chore assignments — without needing a group chat.

Built with Flutter, using Firebase (Auth + Firestore) so everyone's phone
stays in sync.

## Features

- **Accounts & households** — sign up, then create a household or join one
  with an invite code so all four people share the same data.
- **Expenses** — log who paid for what, split among chosen housemates, see
  net balances on the dashboard, mark expenses settled.
- **Groceries** — a shared running list; check items off as they're bought.
- **Chores** — assign recurring (daily/weekly/monthly) or one-off chores to
  housemates, track completion.
- **Dashboard** — at-a-glance balance, pending groceries, and pending chores.

## Project status

The app code is complete and passes `flutter analyze` and `flutter test`.
It is **not yet wired to a real Firebase project** — `lib/firebase_options.dart`
currently has placeholder values. You need to plug in your own free Firebase
project before the app can actually sync data between phones.

## One-time setup (you only need to do this once)

1. Create a free project at https://console.firebase.google.com.
2. Enable **Authentication → Email/Password** sign-in method.
3. Create a **Firestore Database** (start in production mode).
4. Deploy the security rules in `firestore.rules` (Firebase console →
   Firestore → Rules → paste the contents of this file → Publish).
5. Generate real config for the app. Easiest way:
   ```
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```
   This overwrites `lib/firebase_options.dart` with your project's real
   values and registers the Android (and iOS) app for you.

## Building the APK

This sandbox's network policy blocks `dl.google.com` / `maven.google.com`,
which the Android Gradle Plugin and Firebase Android SDK need to download —
so the APK can't be compiled inside this environment. Instead, a GitHub
Actions workflow (`.github/workflows/build-apk.yml`) builds it for you:

- Push to `main`, or run the workflow manually from the **Actions** tab
  (`Build Android APK` → **Run workflow**).
- When it finishes, download `solaina-release-apk` from the run's
  **Artifacts** section — that's `app-release.apk`, ready to install.

If you want to build locally instead (on a machine with normal internet
access and the Android SDK installed):

```
flutter pub get
flutter build apk --release
```

The output APK will be at `build/app/outputs/flutter-apk/app-release.apk`.

## Local development

```
flutter pub get
flutter analyze
flutter test
flutter run
```
