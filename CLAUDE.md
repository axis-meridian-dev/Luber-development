# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

The Luber-development workspace contains **two distinct applications** for mobile oil change services:

1. **luber_consumer/** - Consumer marketplace (direct customer-to-technician platform)
2. **luber_app_b2b/** - B2B SaaS platform (licensed shops running mobile businesses)

**CRITICAL:** These are **separate applications** with different business models. Always verify which application you're working in before making changes.

---

## Application 1: luber_consumer/ - Consumer Marketplace

**Path:** `/home/axmh/Development/Luber-development/luber_consumer/`
**Business Model:** Direct marketplace connecting customers with individual technicians (similar to Uber)

### Architecture

**Next.js Web Application + Two Flutter Mobile Apps**

```
luber_consumer/
├── app/                          # Next.js 16 App Router
│   ├── customer/                 # Customer portal (book, account, vehicles, addresses)
│   ├── admin/                    # Admin dashboard
│   ├── auth/                     # Authentication
│   └── api/                      # API routes (jobs, reviews, location, photos)
├── components/
│   ├── ui/                       # shadcn/ui components
│   ├── customer/                 # Customer-specific components (booking-flow, forms)
│   └── admin/                    # Admin components
├── lib/
│   ├── supabase/                 # Supabase clients (client.ts, server.ts)
│   ├── types/                    # TypeScript types (database.ts)
│   ├── job-matching.ts           # Haversine distance matching algorithm
│   └── pricing.ts                # Dynamic pricing logic
├── flutter_customer_app/         # Flutter customer mobile app
├── flutter_technician_app/       # Flutter technician mobile app
├── hooks/                        # React hooks
└── middleware.ts                 # Supabase session refresh
```

### Common Commands

```bash
cd /home/axmh/Development/Luber-development/luber_consumer

# Next.js Web Application
npm run dev          # Start dev server
npm run build        # Production build
npm run start        # Start production server
npm run lint         # ESLint

# Flutter Customer App
cd flutter_customer_app/
flutter pub get      # Install dependencies
flutter run          # Run on device/emulator
flutter build apk    # Build Android APK
flutter build ios    # Build iOS

# Flutter Technician App
cd flutter_technician_app/
flutter pub get
flutter run
flutter build apk
flutter build ios
```

### Key Concepts

**Pricing Model:**
- Fixed base prices by oil type (conventional $39.99, synthetic $79.99, etc.)
- Vehicle type multipliers (sedan 1.0x, truck 1.3x, sports car 1.4x)
- **Platform takes 20% fee**, remaining 80% goes to technician
- Pricing logic in `lib/pricing.ts`

**Job Matching:**
- Uses Haversine formula to calculate distance between customer and technicians
- Max 25-mile radius for matching
- Sorts by rating (0.5+ difference) then distance
- Real-time technician location tracking via `technician_locations` table
- Logic in `lib/job-matching.ts`

**User Roles:**
- `customer` - Books services
- `technician` - Independent contractors accepting jobs
- `admin` - Platform administrators

**Job Flow:**
1. Customer selects vehicle, address, oil type, schedule time
2. System finds available technicians within 25 miles
3. Technician accepts job
4. Technician completes job, uploads photos
5. Customer reviews technician
6. Payment processed via Stripe, 80/20 split

### Tech Stack
- **Frontend:** Next.js 16, React 19, TypeScript, Tailwind CSS 4
- **Mobile:** Flutter with Supabase Flutter SDK, Provider for state management
- **Database:** Supabase (PostgreSQL)
- **Payments:** Stripe
- **UI:** shadcn/ui (Radix UI + Tailwind)
- **Maps:** Google Maps API for location

### Environment Variables

Required in `.env.local`:
```env
SUPABASE_URL=your-supabase-url
SUPABASE_ANON_KEY=your-supabase-anon-key
```

Flutter apps: Update `lib/config/constants.dart` in each Flutter app with Supabase credentials.

---

## Application 2: luber_app_b2b/ - B2B SaaS Platform

**Path:** `/home/axmh/Development/Luber-development/luber_app_b2b/`
**Business Model:** White-label SaaS for licensed auto shops to run mobile businesses (similar to Shopify for mechanics)

### Architecture

**Next.js Web Application + Two Flutter Mobile Apps**

```
luber_app_b2b/
├── app/
│   ├── admin/                    # Admin dashboard (bookings, customers, technicians)
│   ├── auth/                     # Authentication
│   ├── onboarding/               # Multi-step shop onboarding wizard
│   ├── actions/                  # Server actions (dispatch.ts, stripe-subscription.ts)
│   └── [public pages]            # about, contact, pricing, shop, service-areas
├── components/
│   ├── ui/                       # shadcn/ui components (New York style)
│   ├── admin/                    # Admin components
│   ├── onboarding/               # Onboarding wizard components
│   ├── subscription/             # Subscription management
│   └── shop/                     # Shop-related components
├── lib/
│   ├── supabase/                 # Supabase clients (client.ts, server.ts, middleware.ts)
│   ├── types/                    # TypeScript types (shop.ts, user.ts, booking.ts)
│   ├── stripe.ts                 # Stripe subscription plans (server-only)
│   └── utils.ts
├── flutter_customer_app/         # Flutter customer app (shop-branded)
├── flutter_technician_app/       # Flutter shop employee app
├── scripts/                      # Database migrations
└── middleware.ts                 # Auth + session refresh
```

### Common Commands

```bash
cd /home/axmh/Development/Luber-development/luber_app_b2b

# Next.js Web Application
pnpm dev             # Start dev server
pnpm build           # Production build
pnpm start           # Start production server
pnpm lint            # ESLint

# Flutter Apps - same as consumer app
cd flutter_customer_app/
flutter pub get
flutter run
```

### Key Concepts

**Business Model - Two Subscription Tiers:**

1. **Solo Mechanic** - $99/month + 8% transaction fee
   - Single technician
   - Basic features

2. **Business** - $299/month + $49/technician/month + 5% transaction fee
   - Up to 10 technicians
   - Multi-technician dispatch
   - White-label branding
   - Advanced analytics

Plans defined in `lib/stripe.ts` with `SUBSCRIPTION_PLANS` constant.

**User Roles:**
- `shop_owner` - Owns/manages shop
- `shop_mechanic` - Employee of a shop
- `solo_mechanic` - Independent mechanic using platform
- `customer` - Books services
- `technician` - Legacy role (marketplace technician)
- `admin` - Platform administrator

**Shop Features:**
- Custom pricing per shop (shops set their own service packages)
- Custom branding (logo, colors)
- Multi-technician dispatch system
- Service area configuration
- License/insurance verification
- Stripe Connect for payment splitting (95% to shop, 5% platform OR 92%/8%)

**Database Schema Highlights:**
- `shops` table - Shop info, subscription, branding
- `shop_technicians` table - Shop employees (junction)
- `shop_service_packages` table - Custom pricing per shop
- `shop_subscription_history` table - Billing audit trail
- Enhanced `bookings` table with shop fields (shop_id, shop_technician_id, transaction_fee, shop_payout)
- Enhanced `reviews` table - Reviews for shops OR solo mechanics

**Payment Flow:**
- Shop sets custom pricing for each service package
- Customer books through shop (sees shop branding)
- Payment collected via Stripe
- Platform fee (5% or 8%) deducted
- Remainder paid to shop via Stripe Connect

### Tech Stack
- **Frontend:** Next.js 16, React 19, TypeScript, Tailwind CSS 4
- **Mobile:** Flutter (same as consumer)
- **Database:** Supabase (PostgreSQL)
- **Payments:** Stripe + Stripe Connect
- **UI:** shadcn/ui (New York style)
- **Forms:** React Hook Form + Zod validation

### Environment Variables

Required in `.env.local`:
```env
# Supabase (note the naming inconsistency)
SUPABASE_URL=your-supabase-url
SUPABASE_ANON_KEY=your-supabase-anon-key
NEXT_PUBLIC_SUPABASE_LUBER_PUBLIC_SUPABASE_URL=your-supabase-url
NEXT_PUBLIC_SUPABASE_LUBER_PUBLIC_SUPABASE_ANON_KEY=your-supabase-anon-key

# Stripe
STRIPE_SECRET_KEY=sk_...
NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY=pk_...
STRIPE_WEBHOOK_SECRET=whsec_...
STRIPE_CONNECT_CLIENT_ID=ca_...
```

**Note:** The B2B app has inconsistent Supabase env var naming - server middleware uses `SUPABASE_URL`, browser client uses the `NEXT_PUBLIC_SUPABASE_LUBER_PUBLIC_*` versions.

### Database Migrations

Located in `scripts/` directory:
- `007_update_user_roles_for_b2b.sql` - User role system
- `008_update_reviews_for_shops.sql` - Shop-level reviews

Run migrations in Supabase SQL Editor in order.

### Implementation Status (as of Nov 4, 2025)

**Completed ✅:**
- Database schema and migrations
- TypeScript type definitions
- Stripe subscription plan configuration
- Basic shop dashboard pages

**Needs Work 🚧:**
- Shop packages management UI
- Technician management UI
- Dispatch system
- Updated onboarding flow with license/insurance verification
- Stripe Connect integration
- Mobile app shop branding

See `B2B_RESTRUCTURING_SUMMARY.md` for full implementation plan.

---

## Shared Patterns Between Applications

Both applications share similar technology stacks and patterns:

### Supabase Client Usage

**Server Components/Actions:**
```typescript
import { createClient } from "@/lib/supabase/server"
const supabase = await createClient()
```

**Client Components:**
```typescript
import { createClient } from "@/lib/supabase/client"
const supabase = createClient()
```

**Middleware:**
```typescript
import { createServerClient } from "@supabase/ssr"
// Used in middleware.ts for session refresh
```

### Code Style

- TypeScript with strict mode
- React Server Components by default (use `"use client"` only when needed)
- Server actions for mutations (in `app/actions/` for B2B)
- Path aliases: `@/*` points to root of respective app
- 2-space indentation (per B2B `AGENTS.md`)
- Tailwind CSS for styling
- shadcn/ui components

### Flutter Architecture

Both apps use identical Flutter patterns:
- Provider for state management
- Supabase Flutter SDK for backend
- Google Maps for location
- Separate providers: `auth_provider.dart`, `job_provider.dart`, `location_provider.dart`
- Configuration in `lib/config/constants.dart`

---

## Working in This Workspace

### Before Making Changes

1. **Identify which application** you're working in (consumer vs B2B)
2. **Verify the working directory** - use full absolute paths
3. **Check business model** - pricing, fees, and features differ significantly

### Consumer vs B2B Key Differences

| Feature | Consumer (`luber_consumer/`) | B2B (`luber_app_b2b/`) |
|---------|------------------------------|------------------------|
| **Business Model** | Marketplace (customer ↔ technician) | SaaS (shops run mobile businesses) |
| **Pricing** | Fixed platform pricing (20% fee) | Shops set custom pricing (5-8% fee) |
| **Technicians** | Independent contractors | Shop employees OR solo mechanics |
| **Branding** | Luber branding | White-label shop branding |
| **Subscriptions** | No subscriptions | Monthly shop subscriptions |
| **Payment Split** | 80/20 (tech/platform) | 95/5 or 92/8 (shop/platform) |
| **User Roles** | customer, technician, admin | 6 roles including shop_owner, shop_mechanic |
| **Package Manager** | npm | pnpm |

### Testing Strategy

Currently **neither application has test suites configured**.

When adding tests:
- Use Vitest for unit/integration tests
- Use Playwright or Cypress for E2E tests
- Mock Supabase clients via dependency injection
- Test server actions independently

Flutter apps:
- Use `flutter test` for widget and unit tests
- Mock API responses in tests

### Common Gotchas

1. **Wrong Directory** - Always use absolute paths starting with `/home/axmh/Development/Luber-development/`
2. **Supabase Client Confusion** - Use correct client (server vs browser vs middleware)
3. **Environment Variables** - B2B has inconsistent Supabase env var naming
4. **Server-Only Imports** - B2B `lib/stripe.ts` uses `"server-only"` directive
5. **Package Managers** - Consumer uses npm, B2B uses pnpm
6. **Business Logic** - Pricing, fees, and flows differ significantly between apps

### Middleware Behavior

Both apps use Next.js middleware for:
- Supabase session refresh on every request
- B2B also protects `/admin/*` routes (redirects unauthenticated users to `/admin/login`)

### Database Schema

Both apps use Supabase with PostgreSQL, but:
- **Consumer** has simpler schema (users, jobs, reviews, technicians)
- **B2B** has extended schema (shops, shop_technicians, shop_service_packages, etc.)

They may share the same Supabase project or use separate projects - check env vars.

---

## Additional Documentation

- **B2B Restructuring Plan:** `/home/axmh/Development/Luber-development/luber_app_b2b/B2B_RESTRUCTURING_SUMMARY.md`
- **B2B Claude Guidelines:** `/home/axmh/Development/Luber-development/luber_app_b2b/CLAUDE.md` (detailed B2B-specific guide)
- **B2B Agent Guidelines:** `/home/axmh/Development/Luber-development/luber_app_b2b/AGENTS.md` (coding style and conventions)
- **Flutter READMEs:** See respective Flutter app directories in each application

---

## Quick Reference

### Consumer App Commands
```bash
cd /home/axmh/Development/Luber-development/luber_consumer
npm run dev
```

### B2B App Commands
```bash
cd /home/axmh/Development/Luber-development/luber_app_b2b
pnpm dev
```

### Flutter Apps (Both Applications)
```bash
cd <app_directory>/flutter_customer_app  # or flutter_technician_app
flutter pub get
flutter run
```
