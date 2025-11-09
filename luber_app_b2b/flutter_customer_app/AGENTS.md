# Repository Guidelines

This document keeps Flutter contributors aligned on layout, tooling, and delivery expectations for the Luber Customer App.

## Project Structure & Module Organization
- `lib/main.dart` boots the app, configures routing, and wires global providers. Keep entry logic dumb and push side effects into services.
- `lib/screens/` holds page-level widgets; colocate view-specific components under each screen to avoid a bloated `components/` pattern.
- `lib/providers/` manages state with Riverpod/Provider; keep async calls in services and expose typed models from `lib/models/`.
- `lib/services/` centralizes Supabase calls, schedule logic, and platform helpers; prefer dependency injection for easier testing.
- Assets live under `assets/` (images, fonts) and are registered in `pubspec.yaml`. Add new directories there so `flutter pub get` picks them up.

## Build, Test, and Development Commands
- `flutter pub get` installs Dart/Flutter dependencies; run it after every `pubspec.yaml` change.
- `flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...` launches the app locally with required secrets.
- `flutter analyze` enforces static analysis; treat warnings as blockers.
- `flutter test` runs unit/widget suites. Use `-t <tag>` to focus specific groups.
- `flutter build apk --release` / `flutter build ios --release` produce store-ready binaries; verify they pass manual smoke tests before tagging.

## Coding Style & Naming Conventions
- Use Dartfmt’s default 2-space indentation (`dart format .`); never hand-edit formatting.
- Favor `const` constructors/widgets, prefer immutable models, and expose async methods with explicit `Future<T>` return types.
- Name screens with `*Screen`, providers with `*Provider`, and services with a verb-first class (e.g., `BookingService`). File names stay snake_case.
- Keep widget trees readable by extracting helpers once they exceed ~40 lines; document non-obvious layouts with short comments.

## Testing Guidelines
- Place tests under `test/`, mirroring the `lib/` structure (e.g., `test/services/booking_service_test.dart`).
- Rely on Flutter’s `testWidgets` for UI flows and stub Supabase calls via injected service interfaces.
- Ensure new logic includes regression coverage or document manual QA steps in the PR description when automation is impractical.

## Commit & Pull Request Guidelines
- Write imperative commit subjects under 50 chars (e.g., `Add booking form validation`) and include a short body when context matters.
- Open PRs with: summary bullets, linked issue/Task, screenshots for UI changes, environment/config updates, and confirmation that `flutter analyze` + `flutter test` are green.
- Split unrelated work across separate PRs and call out schema or API contract changes so downstream apps can react.

## Security & Configuration Tips
- Secrets live in `.env`/tool-specific files and must be injected via `--dart-define`; never commit real Supabase keys.
- Update `lib/services/` and any platform channel code together when backend rules change so both iOS and Android clients stay in sync.
