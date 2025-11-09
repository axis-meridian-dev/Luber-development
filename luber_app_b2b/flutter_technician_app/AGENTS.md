# Repository Guidelines

## Project Structure & Module Organization
The Flutter entry point lives in `lib/main.dart`, which configures GoRouter routes and top-level providers. Feature UI stays in `lib/screens`, grouped by flow (`auth`, `jobs`, `home`, `earnings`, `profile`). Put shared state in `lib/providers`, keeping each provider focused on one Supabase resource or workflow. Data abstractions (`lib/models`) and remote helpers (`lib/services`) should mirror the screen names so navigation, state, and API logic stay in lockstep. Add integration tests or experimentation code under `lib/experimental/` only when gated behind build flags.

## Build, Test, and Development Commands
Run `flutter pub get` after any dependency change. `flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...` launches the app on the attached device or emulator with the required config. `flutter analyze` enforces static checks and must be clean before merging. Use `flutter test` for unit/widget suites, and `flutter build apk --release` or `flutter build ios --release` for store-ready artifacts.

## Coding Style & Naming Conventions
Follow Dart’s default formatter (`dart format .`) and keep files at two-space indentation. Components, providers, and models use PascalCase; methods and variables stay camelCase, with async functions suffixed by `Async` when they reach out to Supabase. Keep widgets under 300 lines by extracting private helpers (`_JobCard`). Prefer `const` constructors and immutability, and document non-obvious business rules in triple-slash comments.

## Testing Guidelines
Place tests in `test/`, mirroring the `lib` path (`lib/screens/jobs/jobs_screen.dart` → `test/screens/jobs/jobs_screen_test.dart`). Use `flutter_test` for widget behaviour and stub Supabase calls with fake clients or dependency injection on the providers. Target critical flows: authentication, job acceptance, earnings tally, and availability toggles. Record manual QA steps in the PR description whenever a feature lacks automated coverage.

## Commit & Pull Request Guidelines
Write imperative commit subjects under 50 characters (`Add earnings provider`). Separate unrelated concerns across commits and mention schema or env variable changes explicitly. PRs need a concise summary, linked issue, screenshots or screen recordings for UI-facing work, and confirmation that `flutter analyze` and `flutter test` passed. Tag teammates who own impacted flows (e.g., Supabase, job routing) so reviews stay focused.

## Security & Configuration Tips
Never commit Supabase URLs or anon keys; pass them via `--dart-define` or local `.env` files ignored by git. Keep device-specific keys in secure storage, and rotate Supabase service roles if a device is lost. Run Flutter tooling only inside this directory to avoid polluting adjacent Next.js workspaces in the monorepo.
