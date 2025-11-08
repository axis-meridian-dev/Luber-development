# Repository Guidelines

## Project Structure & Module Organization
- `app/` hosts the App Router entry points; colocate layouts and providers per segment to keep scope tight.
- `components/` carries reusable client UI; move cross-cutting logic into `lib/`.
- `lib/` centralizes Supabase, Stripe, and helper utilities, with companion React hooks in `hooks/`.
- `styles/` and `public/` store Tailwind entry styles and static assets; Flutter directories remain isolated prototypes.

## Build, Test, and Development Commands
- `npm run dev` (or `pnpm dev`) spins up http://localhost:3000 with hot reload.
- `npm run build` compiles for production and performs type checks; merge only on a clean run.
- `npm run lint` runs ESLint’s Next.js preset; treat warnings as blockers.
- `npm run start` serves the compiled build for SSR smoke tests before releases.

## Coding Style & Naming Conventions
- Write TypeScript with 2-space indentation, preferring `const` and explicit return types in shared helpers.
- Use PascalCase for components and providers, camelCase `use`-prefixed hooks, and directory names that match route casing.
- Tailwind utilities favor readability over strict ordering; annotate unusual class clusters sparingly.
- Declare `use client` only where required and keep server logic in separate modules.

## Testing Guidelines
- No default harness exists; add Jest + React Testing Library suites under `__tests__/` or `*.test.tsx`.
- Stub Supabase and Stripe clients via the dependency injection points exported from `lib/`.
- Focus on behaviour assertions for forms, API handlers, and middleware, and record manual QA steps when tests are absent.

## Commit & Pull Request Guidelines
- Keep commit subjects under 50 characters, imperative (e.g., `Add Stripe billing hook`), with optional body details.
- Split unrelated work, note schema or environment changes explicitly, and ensure `npm run lint` passes before pushing.
- Pull requests need a summary, linked issue, UI screenshots when relevant, and confirmation of config updates; tag reviewers impacted by the change.

## Environment & Configuration Tips
- Store secrets in `.env.local` and never commit Supabase, Stripe, or analytics keys.
- Update `next.config.ts` or `middleware.ts` alongside backend rule changes so access rules stay aligned.
- Run Flutter tooling from the respective Flutter directories to keep the Next.js workspace clean.
