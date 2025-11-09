# Repository Guidelines

## Project Structure & Module Organization
- `lib/main.dart` bootstraps the Flutter app and should stay lean—delegate feature wiring to `providers/` and `screens/`.
- `lib/config/constants.dart` stores Supabase, Stripe, and API endpoints; keep only non-secret defaults in git and inject sensitive keys per environment.
- Domain code lives in `lib/models/` (DTOs with inline serializers) and `lib/providers/` (`provider` state scoped to matching screens).
- UI flows live under `lib/screens/` (auth, booking, job, profile); mirror navigation structure when adding new flows.

## Build, Test & Development Commands
- `flutter pub get` — resolve Dart/Flutter dependencies after editing `pubspec.yaml`.
- `flutter run -d chrome` (or an emulator id) — run the app locally on your preferred target while iterating.
- `flutter build apk --release` / `flutter build ios --release` — generate store-ready binaries once configs are locked.
- `flutter analyze` — static analysis from `flutter_lints`; keep the tree warning-free.
- `flutter test --coverage` — run the suite and emit `coverage/lcov.info` for CI gating.

## Coding Style & Naming Conventions
- Use Dart’s default 2-space indentation and let `dart format lib test` fix layout.
- Keep file names snake_case (`job_provider.dart`), classes/widgets in PascalCase (`JobProvider`), members in lowerCamelCase.
- Extract reusable UI into `lib/screens/common/` to keep feature folders focused.
- Run `flutter analyze` and `dart format` before committing to respect the enforced `flutter_lints` rule set.

## Testing Guidelines
- Co-locate widget, provider, and model tests under `test/` with suffixes like `_test.dart` (`booking_flow_test.dart`).
- Mock Supabase, Stripe, and HTTP layers so tests stay hermetic; rely on `package:mockito` or lightweight fakes.
- Prioritize coverage for booking logic, payments, and location handling before shipping large changes.
- Treat coverage from `flutter test --coverage` as a gate; flag PRs that push it down.

## Commit & Pull Request Guidelines
- Use the existing history style: short, imperative subjects (`Add booking flow validations`), present tense, <72 characters.
- Keep commits atomic; avoid mixing formatting-only changes with feature work.
- PRs should call out user impact, list testing evidence (`flutter test`, screenshots), and link the tracking ticket.
- Highlight configuration changes (new env keys, API toggles) and update `README.md` when they affect setup.

## Security & Configuration Tips
- Never commit real Supabase, Stripe, or API secrets—store them in CI secrets managers and feed them into `lib/config/constants.dart` at build time.
- Configure Google Maps, FCM, and other platform keys inside `android/` and `ios/` and scope them to Luber environments only.
