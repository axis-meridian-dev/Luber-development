# Repository Guidelines

## Project Structure & Module Organization
- Root hosts Next.js apps `luber_app_b2b` (operator dashboard) and `luber_consumer` (customer booking); both follow the App Router pattern with `app/`, `components/`, `lib/`, `public/`, `styles/`, and `scripts/`.
- `components/ui` stores design primitives, feature folders such as `components/shop` hold domain widgets, and shared types live under `lib/types`.
- Flutter prototypes (`flutter_customer_app`, `flutter_technician_app`) mirror the web feature-set; keep assets and copy in sync whenever a feature ships.

## Build, Test, and Development Commands
- `cd <app> && pnpm install` (or `npm install`) bootstraps dependencies; prefer `pnpm` because its lockfile are maintained.
- `pnpm dev` runs the dev server on `http://localhost:3000`, `pnpm build` compiles production assets, `pnpm start` serves the compiled app, and `pnpm lint` executes ESLint via `next/core-web-vitals`.
- Use `.env.local` per app for Supabase, Stripe, and Vercel secrets before running commands that touch remote services.

## Coding Style & Naming Conventions
- TypeScript is required; avoid `any`, keep env-aware helpers in `lib/`, and colocate component-specific types beside the file.
- Components are PascalCase, hooks follow `useThing.ts`, and routing folders stay kebab-case under `app/`.
- Tailwind utilities should read layout → spacing → color; reuse class bundles through `cn()` helpers and run `pnpm lint -- --fix` to enforce formatting (two-space indentation).

## Testing Guidelines
- No automated test runner ships yet, so lint + manual smoke tests in both apps are mandatory before every PR.
- Document the manual journey you covered (e.g., “create package”, “book technician”) in the PR body; treat that write-up as the coverage record.
- When introducing automated tests, favor React Testing Library with Vitest/Jest, store specs as `ComponentName.spec.tsx`, and keep them next to the code they cover.

## Commit & Pull Request Guidelines
- Git history favors concise, sentence-case subjects (e.g., `Clarify "hybrid approach" terminology`); keep them under ~72 characters and describe the change, not the task.
- Reference related issues, enumerate notable changes, and call out migrations such as `scripts/010_add_stripe_connect_fields.sql`.
- Include screenshots for UI changes or CLI logs for backend work, and note which surfaces (B2B web, consumer web, Flutter) you manually tested before requesting review.
