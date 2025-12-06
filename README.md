# Eatzy Vendor App — Standalone (EN/HI/GU)

## Setup
1. Ensure Flutter SDK >= 3.0 is installed.
2. Clone this repo.
3. Run:
   flutter pub get

4. Generate localizations:
   flutter gen-l10n

5. Start mock API:
   npm install -g json-server
   json-server --watch sample_fixtures/vendors.json --port 3000

6. Run app:
   flutter run -t lib/main_vendor.dart --dart-define=EATZY_API_BASE_URL=http://localhost:3000

## Notes
- For STT tests, use a real device (emulators often have limited mic support).
- Add Firebase `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) for FCM.
- Use `--dart-define` for secrets and replace constants in `lib/core/constants.dart`.
