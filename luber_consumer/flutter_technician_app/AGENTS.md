# Repository Guidelines

## Project Structure & Module Organization
This Flutter app lives entirely under `lib/`. `lib/main.dart` configures the root `MaterialApp` and hooks up providers. Keep environment defaults inside `lib/config/constants.dart`. Data classes such as `TechnicianModel` and `JobModel` belong in `lib/models`, while business logic and Supabase/API calls sit in `lib/providers` (auth, jobs, location). UI flows are nested under `lib/screens/{auth,home,jobs,profile}`; add subfolders per screen to keep files short.

## Build, Test & Development Commands
- `flutter pub get` — install dependencies after editing `pubspec.yaml`.
- `flutter run` — start the debug build on the active device or simulator.
- `flutter analyze` — static analysis; must be clean before committing.
- `dart format lib test` — canonical formatting pass.
- `flutter build apk --release` / `flutter build ios --release` — production artifacts shared with QA.

## Coding Style & Naming Conventions
Follow Dart analyzer defaults (null safety, avoid `var` when type inference is unclear, prefer `const`). Types, widgets, and providers use UpperCamelCase; files, directories, and test names use snake_case (`job_provider.dart`). Break widgets that exceed ~150 lines into smaller private widgets for readability. Async methods that perform side effects should end with `Async`. Run `dart format` and `flutter analyze` before pushing.

## Testing Guidelines
Mirror the `lib/` hierarchy under a `test/` directory (e.g., `test/providers/job_provider_test.dart`). Use `flutter_test` for widgets and `mocktail` for Supabase or HTTP clients. Each provider should include success, failure, and edge-case coverage; aim for at least one golden or widget smoke test per screen. Execute `flutter test --coverage` locally before PR submission.

## Commit & Pull Request Guidelines
Commits follow the short imperative pattern seen in history (`Clarify hybrid approach terminology`). Keep subjects ≤72 chars and include detail in the body when touching multiple layers. Rebase onto `main` and ensure CI is green. PRs must include an overview, screenshots/GIFs for UI updates, a test plan with command output, and links to Jira/GitHub issues. Highlight breaking API or schema changes and request reviewers from mobile and backend when integration points shift.

## Security & Configuration Tips
Never commit Supabase keys or API tokens; store them in local `.env` files injected via your build tooling and keep `constants.dart` limited to placeholders. Review permission prompts (location, camera) on device each release. Centralize new endpoints inside providers so auditing network behavior stays straightforward and secrets do not leak into UI layers.
