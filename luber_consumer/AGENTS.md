# Repository Guidelines

## Project Structure & Module Organization
The Next.js consumer app lives in `app/`, where route groups (`app/(auth|admin|technician)`) and server components reside. Shared UI primitives stay in `components/`, domain helpers and Supabase clients in `lib/`, reusable hooks in `hooks/`, and Tailwind layers in `styles/`. Place static assets (logos, Lottie files) in `public/`. Database migrations and seed data live under `scripts/00x_*.sql`; run them sequentially through Supabase so both the web app and the Flutter companions (`flutter_customer_app/`, `flutter_technician_app/`) stay in sync.

## Build, Test, and Development Commands
Use Node 18.18+ (Next 16 requirement) and the committed npm lockfile. `npm run dev` starts the local server on `http://localhost:3000` and loads `.env.local`. `npm run build` creates the production bundle, and `npm run start` serves that bundle—use it for preview deployments and smoke tests. `npm run lint` runs ESLint with the Next preset; treat any warning as a blocker. In the Flutter directories run `flutter pub get` followed by `flutter run -d chrome` (or a device ID) for manual verification.

## Coding Style & Naming Conventions
TypeScript is set to `strict`, so favor explicit types and early returns (see `app/page.tsx`). Keep indentation at two spaces, stick to functional components, and import shared modules via the `@/` alias instead of long relative paths. Components/files use PascalCase, hooks use camelCase, and SQL tables as well as migration files stay snake_case. Tailwind utility stacks should align with the design tokens defined in `styles/` and `components.json`.

## Testing Guidelines
There is no committed automated test runner yet, so every change must at minimum pass `npm run lint` and a manual walk through the Customer, Admin, and Technician dashboards. When you add tests, colocate them as `feature-name.spec.tsx` beside the component and lean on React Testing Library + Vitest so the suite can later plug into CI. Flutter teams should place widget tests under each app’s `test/` folder and run `flutter test`. Always reseed your Supabase instance with `scripts/004_seed_data.sql` before exercising flows.

## Commit & Pull Request Guidelines
Git history shows short, imperative subjects (`Clarify hybrid approach terminology`, `Implement hybrid vehicle management system`). Keep subjects ≤60 characters, optionally prefix with a scope (`admin:`), and describe schema or migration changes in the body. Pull requests must link an issue, outline user-facing impact, list any SQL files touched (`scripts/00x_*`), and attach before/after screenshots for UI work. Tag both web and mobile reviewers whenever a change affects shared Supabase structures.

## Security & Configuration Tips
Copy `.env.example` to `.env.local` and populate Supabase anon/service keys, Stripe secrets, and any OAuth values—never commit secrets. Apply SQL migrations against staging before production and confirm that role redirects in `middleware.ts` still match the new data. Avoid logging tokens, scrub Supabase keys from issues, and rotate credentials immediately if accidental exposure occurs.
