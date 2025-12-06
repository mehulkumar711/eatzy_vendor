# Eatzy Vendor App

This repository contains the production-grade Flutter + Native Android voice-first vendor app for the Eatzy hyperlocal platform.

## Tech Stack
- Flutter (Vendor App UI)
- Kotlin (Foreground Voice Service)
- Room DB + WorkManager (Native queue)
- Dio Uploads + TUS support
- Firebase (Messaging)
- GitHub Actions (CI/CD)
- Integration tests (Drive + Emulator)
- Android Instrumentation tests

## Setup
1. Ensure Flutter SDK >= 3.0 is installed.
2. Clone this repo.
3. Run:
   ```bash
   flutter pub get
   ```

4. Generate localizations:
   ```bash
   flutter gen-l10n
   ```

5. Start mock API (for local testing):
   ```bash
   cd server
   npm install
   node upload_server.js
   ```

6. Run app:
   ```bash
   flutter run -t lib/main_vendor.dart --dart-define=EATZY_API_BASE_URL=http://localhost:3000
   ```

## Testing
- **Unit Tests:** `flutter test`
- **Integration Tests:** (See `.github/workflows/ci.yml`)
- **Android Tests:** `./gradlew connectedAndroidTest`

## Notes
- For STT tests, use a real device (emulators often have limited mic support).
- Add Firebase `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) for FCM.
- Use `--dart-define` for secrets and replace constants in `lib/core/constants.dart`.
