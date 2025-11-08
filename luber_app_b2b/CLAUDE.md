# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Luber B2B** is a B2B SaaS platform for mobile oil change businesses - "The Operating System for Mobile Oil Change Businesses." This is a white-label platform (like Shopify for mechanics) that enables licensed auto shops and mechanics to run their mobile service business with custom pricing, branding, multi-technician dispatch, and payment processing.

**Powered by:** Axis Meridian Holdings

**Tech Stack:**
- Next.js 16 web application (React 19) with App Router
- Flutter mobile apps (separate customer and technician apps)
- Supabase for authentication and PostgreSQL database
- Stripe for subscription billing and payment processing
- shadcn/ui components (New York style) with Tailwind CSS v4

**Working Directory:** `/home/axmh/Development/Luber-development/luber_app_b2b/`

## Development Commands

### Next.js Web Application

```bash
# Start development server (uses Turbopack)
npm run dev

# Build for production
npm run build

# Start production server
npm start

# Run linter
npm run lint
```

**Note:** This project uses `npm` (not pnpm). The package-lock.json is the source of truth for dependencies.

### Flutter Mobile Apps

Two separate Flutter applications in the project:

**Customer App:** `flutter_customer_app/`
**Technician App:** `flutter_technician_app/`

```bash
# Navigate to the appropriate Flutter app directory first
cd flutter_customer_app/  # or flutter_technician_app/

# Get dependencies
flutter pub get

# Run on connected device/emulator
flutter run

# Build for Android
flutter build apk

# Build for iOS (macOS only)
flutter build ios
```

### Database Migrations

Database schema is managed via SQL migration files in `scripts/`:

```bash
# Migrations must be run in order via Supabase SQL Editor:
# 001_create_tables.sql          - Base schema (profiles, customers, technicians, bookings, reviews)
# 002_create_triggers.sql        - Auto-update triggers
# 003_seed_data.sql              - Test data (optional)
# 004_create_admin_user.sql      - Admin account creation
# 005_create_shops_and_subscriptions.sql - Shop tables and B2B infrastructure
# 006_add_enterprise_and_tracking.sql    - Enterprise tier and metrics
# 007_update_user_roles_for_b2b.sql      - B2B role system (shop_owner, shop_mechanic, solo_mechanic)
# 008_update_reviews_for_shops.sql       - Shop-level reviews and ratings
```

To verify migrations ran successfully:
```sql
-- Check new user roles exist
SELECT enumlabel FROM pg_enum
JOIN pg_type ON pg_enum.enumtypid = pg_type.oid
WHERE pg_type.typname = 'user_role';

-- Check shop tables exist
SELECT table_name FROM information_schema.tables
WHERE table_schema = 'public' AND table_name LIKE 'shop%';
```

## Architecture & Business Model

### B2B SaaS Subscription Tiers

Defined in `lib/stripe.ts`:

1. **Solo Mechanic** - $99/month + 8% transaction fee
   - Single technician account
   - Basic features (bookings, payments, mobile app, analytics)

2. **Business** - $299/month + $49/technician/month + 5% transaction fee
   - Up to 10 technicians
   - Multi-technician dispatch
   - Custom pricing packages
   - White-label branding
   - Advanced analytics

### User Roles & Permissions

Six distinct user roles (defined in `lib/types/user.ts`):

- `customer` - End users booking services
- `technician` - Legacy solo technicians (pre-B2B)
- `admin` - Platform administrators
- **`shop_owner`** - Owns a shop, manages subscription, settings, technicians
- **`shop_mechanic`** - Employee of a shop, performs services
- **`solo_mechanic`** - Independent licensed mechanic (Solo tier subscriber)

**Important:** Users cannot be both `solo_mechanic` and `shop_mechanic` simultaneously.

### Authentication & Authorization

**Supabase** handles all authentication via three client types:

- `lib/supabase/client.ts` - Browser client for client components
- `lib/supabase/server.ts` - Server client for server components/actions
- `lib/supabase/middleware.ts` - Middleware client for route protection

**Route Protection:**
- Admin routes (`/admin/*`) are protected by `middleware.ts`
- Unauthenticated users are redirected to `/admin/login`
- Session refresh happens on every request via middleware

### Database Schema Overview

**Core Tables:**
- `profiles` - User base table (extends auth.users)
- `customers` - Customer-specific data
- `technicians` - Legacy technician data
- `shops` - Shop entities (B2B)
- `shop_technicians` - Junction table (shop employees)
- `shop_service_packages` - Custom pricing per shop
- `shop_subscription_history` - Billing audit trail
- `bookings` - Service appointments (supports both shop and solo bookings)
- `reviews` - Customer reviews (shop-level or technician-level)

**Key Fields:**
- `profiles.shop_id` - Links shop mechanics to their shop
- `profiles.role_metadata` - JSONB field for role-specific data
- `bookings.shop_id` - Associates booking with shop (null for solo mechanics)
- `bookings.shop_technician_id` - Assigned shop employee
- `bookings.service_package_id` - Shop's custom service package
- `bookings.transaction_fee` - Platform fee (5% or 8%)
- `bookings.shop_payout` - Amount paid to shop after fee

**Auto-computed Fields:**
- Shop metrics (`total_technicians`, `total_bookings`, `total_revenue`) update via triggers
- Review ratings auto-aggregate to shops via views and triggers

## Directory Structure

```
luber_app_b2b/
├── app/                          # Next.js App Router
│   ├── admin/                    # Admin dashboard (bookings, customers, dashboard, technicians, login)
│   ├── auth/                     # Authentication pages (login, signup)
│   ├── shop/                     # Shop owner dashboard (bookings, dashboard, dispatch, packages, settings, subscription, technicians)
│   ├── onboarding/               # Shop onboarding wizard
│   ├── actions/                  # Server actions (dispatch.ts, stripe-subscription.ts)
│   └── [public pages]/           # Public pages (about, contact, pricing, service-areas, how-it-works)
├── components/
│   ├── ui/                       # shadcn/ui components (New York style)
│   ├── admin/                    # Admin-specific components
│   ├── shop/                     # Shop-related components
│   ├── onboarding/               # Onboarding wizard components
│   └── subscription/             # Subscription management components
├── lib/
│   ├── supabase/                 # Supabase clients (client.ts, server.ts, middleware.ts)
│   ├── types/                    # TypeScript type definitions (user.ts, shop.ts, booking.ts, index.ts)
│   ├── stripe.ts                 # Stripe configuration and subscription plans (marked "server-only")
│   └── utils.ts                  # Utility functions (cn() for classnames)
├── flutter_customer_app/         # Flutter mobile app for customers
├── flutter_technician_app/       # Flutter mobile app for technicians
├── scripts/                      # Database migration SQL files (001-008)
├── hooks/                        # React hooks
├── styles/                       # Global styles
├── public/                       # Static assets
└── middleware.ts                 # Next.js middleware for auth
```

## Key Implementation Details

### Path Aliases (tsconfig.json)

```typescript
@/*            // Root of project
@/components   // components/
@/lib          // lib/
@/hooks        // hooks/
```

**Always use `@/` imports** instead of relative paths like `../../`.

### Environment Variables

Create `.env.local` with:

```env
# Supabase (note the dual naming convention)
SUPABASE_URL=your-project-url
SUPABASE_ANON_KEY=your-anon-key
NEXT_PUBLIC_SUPABASE_LUBER_PUBLIC_SUPABASE_URL=your-project-url
NEXT_PUBLIC_SUPABASE_LUBER_PUBLIC_SUPABASE_ANON_KEY=your-anon-key

# Stripe
STRIPE_SECRET_KEY=sk_test_...
NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY=pk_test_...
STRIPE_WEBHOOK_SECRET=whsec_...

# Stripe Connect (required for payment splitting)
STRIPE_CONNECT_CLIENT_ID=ca_...
```

**Important:** The codebase uses different Supabase variable naming conventions:
- Server middleware: `SUPABASE_URL`, `SUPABASE_ANON_KEY`
- Browser client: `NEXT_PUBLIC_SUPABASE_LUBER_PUBLIC_SUPABASE_URL`, `NEXT_PUBLIC_SUPABASE_LUBER_PUBLIC_SUPABASE_ANON_KEY`

### Server Actions

Located in `app/actions/`:

- `dispatch.ts` - Job assignment logic for multi-technician dispatch
- `stripe-subscription.ts` - Subscription management and billing

### Type System

Centralized type definitions in `lib/types/`:

- `user.ts` - User roles, profiles, role metadata, type guards (isShopOwner, canManageShop, etc.)
- `shop.ts` - Shop, ShopTechnician, ShopServicePackage
- `booking.ts` - Booking, Review, status types, helper functions (isShopBooking, calculateShopPayout, etc.)
- `index.ts` - Central export file

**Type Guards Available:**
```typescript
import { isShopOwner, canManageShop, isShopBooking, calculateShopPayout } from '@/lib/types'
```

### UI Components

- **Framework:** shadcn/ui (New York style variant)
- **CSS:** Tailwind CSS v4 with `@tailwindcss/postcss`
- **Icons:** Lucide React
- **Primitives:** Radix UI for accessibility
- **Config:** `components.json` (currently has merge conflicts that need resolution)

## Code Style & Patterns

- **TypeScript:** Strict mode enabled
- **React:** Server Components by default (use `"use client"` only when necessary)
- **Mutations:** Server actions for all data mutations
- **Validation:** Zod for schema validation
- **Forms:** React Hook Form
- **Routing:** Next.js 16 App Router conventions

## Common Gotchas & Known Issues

1. **Merge Conflicts:** `components.json` has unresolved git merge conflicts - resolve before adding new shadcn components
2. **Build Errors Ignored:** `next.config.mjs` has `typescript.ignoreBuildErrors: true` - TypeScript errors won't block builds
3. **Server-Only Imports:** `lib/stripe.ts` is marked `"server-only"` - cannot import in client components
4. **Supabase Client Selection:** Always use the correct client (server vs browser vs middleware)
5. **Environment Variables:** Dual naming convention for Supabase vars can cause confusion
6. **Package Manager:** Project uses `npm` with package-lock.json (not pnpm despite some documentation references)

## Development Workflow

### Adding New Features

1. **Database Changes:**
   - Create new migration in `scripts/00X_description.sql`
   - Run via Supabase SQL Editor
   - Update TypeScript types in `lib/types/`

2. **New Pages:**
   - Create in appropriate `app/` subdirectory
   - Use Server Components by default
   - Add client components in `components/`

3. **Server Actions:**
   - Add to `app/actions/` directory
   - Import Supabase server client
   - Handle errors and return typed responses

4. **UI Components:**
   - Use existing shadcn components from `components/ui/`
   - Add custom components to domain-specific folders (`components/shop/`, etc.)

### Testing & Quality

**Current State:** No test suite configured.

**Recommendations:**
- Vitest for unit/integration tests
- Playwright or Cypress for E2E tests
- Test server actions with mock Supabase clients
- Test RLS policies in Supabase

## Project Status & Roadmap

See `B2B_RESTRUCTURING_SUMMARY.md` for detailed status.

**Phase 1 (Complete):**
- ✅ Database schema and migrations
- ✅ TypeScript types
- ✅ Stripe subscription plans

**Phase 2 (In Progress):**
- 🚧 Stripe Connect integration (payment splitting)
- 🚧 Shop packages management UI
- 🚧 Shop technicians management UI
- 🚧 Dispatch system

**Phase 3 (Planned):**
- 📋 Updated onboarding flow with license verification
- 📋 Admin verification dashboard

**Phase 4 (Future):**
- 📋 Flutter app updates for B2B features
- 📋 Analytics dashboard
- 📋 White-label domain support

## Multi-Tenancy Architecture

Each shop operates as an isolated tenant:

- **Custom Pricing:** Shop-specific service packages in `shop_service_packages`
- **Branding:** Logo, colors, business name per shop
- **Service Areas:** Geographic boundaries per shop
- **Payment Splitting:** 95% to shop (Business tier) or 92% to shop (Solo tier), platform keeps 5% or 8%
- **Reviews:** Tied to shop entity, not individual technicians (for Business tier)
- **Dispatch:** Business tier can assign jobs to specific shop technicians

## Security Considerations

- **RLS Policies:** Row-level security on all tables (verify before modifying)
- **Auth Middleware:** `middleware.ts` protects admin and shop routes
- **Server Actions:** All mutations go through server actions (no direct client DB access)
- **Stripe Webhooks:** Verify webhook signatures
- **Environment Variables:** Never commit .env files

## Related Documentation

- **B2B Restructuring Summary:** `B2B_RESTRUCTURING_SUMMARY.md` - Complete migration status and roadmap
- **Agent Guidelines:** `AGENTS.md` - Repository guidelines for automated agents
- **Scripts:** `scripts/` - All database migrations with inline documentation
- **Supabase Docs:** https://supabase.com/docs
- **Stripe Connect:** https://stripe.com/docs/connect
- **Next.js 16 App Router:** https://nextjs.org/docs
