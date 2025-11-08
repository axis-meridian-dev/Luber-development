# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Luber Consumer is an on-demand oil change service platform with three components:
1. **Next.js Web App** - Customer and admin web interface
2. **Flutter Customer App** - Mobile app for customers to book services
3. **Flutter Technician App** - Mobile app for technicians to accept/complete jobs

**Path**: `/home/axmh/Development/Luber-development/luber_consumer/`

## Common Commands

### Web Application (Next.js)

```bash
# Development
npm install           # Install dependencies
npm run dev           # Start dev server (http://localhost:3000)
npm run build         # Production build
npm start             # Start production server
npm run lint          # Run ESLint

# Note: package.json uses npm, not pnpm
```

### Flutter Customer App

```bash
cd flutter_customer_app

# Development
flutter pub get       # Install dependencies
flutter run           # Run on connected device/emulator

# Building
flutter build apk --release    # Android release build
flutter build ios --release    # iOS release build
```

### Flutter Technician App

```bash
cd flutter_technician_app

# Development
flutter pub get       # Install dependencies
flutter run           # Run on connected device/emulator

# Building
flutter build apk --release    # Android release build
flutter build ios --release    # iOS release build
```

## Architecture

### Technology Stack

**Web (Next.js 16)**:
- React 19 with TypeScript
- Next.js App Router
- Supabase for auth and database (@supabase/ssr)
- Stripe for payments
- Radix UI components + shadcn/ui (New York style)
- Tailwind CSS 4
- React Hook Form + Zod validation

**Mobile (Flutter)**:
- Supabase Flutter SDK for auth/database
- Provider for state management
- Google Maps integration
- Stripe Flutter SDK (customer app)
- Geolocator for location tracking

### Application Structure

```
luber_consumer/
├── app/                    # Next.js App Router
│   ├── auth/              # Authentication pages (login, signup)
│   ├── customer/          # Customer portal
│   │   ├── book/         # Booking flow
│   │   ├── jobs/[id]/    # Job tracking
│   │   ├── vehicles/     # Vehicle management
│   │   ├── addresses/    # Address management
│   │   ├── payment-methods/
│   │   ├── history/      # Service history
│   │   └── account/      # Profile settings
│   ├── admin/            # Admin dashboard
│   │   ├── jobs/        # Job management
│   │   └── technicians/ # Technician applications/management
│   └── api/             # API routes
│       ├── jobs/        # Job CRUD operations
│       ├── technician/  # Technician availability
│       ├── location/    # Location tracking
│       ├── reviews/     # Review creation
│       ├── photos/      # Photo uploads
│       └── admin/       # Admin operations
│
├── components/
│   ├── ui/             # Shadcn UI components (accordion, button, card, etc.)
│   ├── auth/           # Auth-specific components
│   ├── customer/       # Customer-facing components
│   └── admin/          # Admin panel components
│
├── lib/
│   ├── supabase/
│   │   ├── server.ts   # Server-side Supabase client
│   │   ├── client.ts   # Client-side Supabase client
│   │   └── middleware.ts # Middleware utilities
│   ├── types/
│   │   └── database.ts # TypeScript type definitions
│   ├── job-matching.ts # Technician matching algorithm
│   ├── pricing.ts      # Job pricing calculations
│   ├── stripe.ts       # Stripe client
│   └── utils.ts        # Utility functions
│
├── flutter_customer_app/      # Flutter mobile app for customers
└── flutter_technician_app/    # Flutter mobile app for technicians
```

### Key Architectural Patterns

#### Supabase Client Pattern

The app uses separate Supabase clients for server and client components:

- **Server Components/API Routes**: Use `lib/supabase/server.ts` → `createClient()`
- **Client Components**: Use `lib/supabase/client.ts` → `createClient()`
- **Middleware**: Uses `lib/supabase/middleware.ts` for auth refresh

Always import the correct client based on context:
```typescript
// Server Component or API Route
import { createClient } from '@/lib/supabase/server'

// Client Component
import { createClient } from '@/lib/supabase/client'
```

#### Job Matching System

Location-based technician matching in `lib/job-matching.ts`:
- Uses Haversine formula to calculate distances
- Maximum search radius: 25 miles
- Sorts by rating first (0.5 threshold), then distance
- Filters for available + approved technicians only

#### Pricing Model

Defined in `lib/pricing.ts`:
- Base prices by oil type (conventional, synthetic blend, full synthetic, high mileage)
- Vehicle type multipliers (sedan: 1.0x, SUV: 1.2x, truck: 1.3x, sports car: 1.4x)
- Platform takes 20% fee, remainder goes to technician
- All prices stored in cents

#### User Roles and Routes

Three distinct user types with separate portals:
- **Customer**: `/customer/*` - Book services, track jobs, manage vehicles/addresses/payments
- **Technician**: Mobile app only - Accept jobs, track earnings, update location
- **Admin**: `/admin/*` - Approve technicians, manage jobs

Role-based access enforced via middleware and database RLS policies.

### Database Types

TypeScript types in `lib/types/database.ts` define:
- User roles: `customer | technician | admin`
- Job statuses: `pending | accepted | in_progress | completed | cancelled`
- Vehicle types: `sedan | suv | truck | sports_car | hybrid | electric`
- Oil types: `conventional | synthetic_blend | full_synthetic | high_mileage`
- Application statuses: `pending | approved | rejected`

### Environment Variables

Required for Next.js web app:

```env
# Supabase
SUPABASE_URL=
SUPABASE_ANON_KEY=
NEXT_PUBLIC_SUPABASE_URL=
NEXT_PUBLIC_SUPABASE_ANON_KEY=

# Stripe
STRIPE_SECRET_KEY=
NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY=
```

Flutter apps require updating `lib/config/constants.dart` with:
- Supabase URL and anon key
- Stripe publishable key (customer app only)
- API base URL (pointing to Next.js deployment)

### Important Configuration Notes

**next.config.mjs**:
- TypeScript build errors ignored (`ignoreBuildErrors: true`)
- Image optimization disabled (`unoptimized: true`)

**tsconfig.json**:
- Path alias: `@/*` maps to root directory
- Target: ES6

**shadcn/ui**:
- Style: "new-york"
- Base color: neutral
- Icon library: lucide-react
- CSS variables enabled

### API Route Patterns

All API routes follow Next.js App Router conventions:
- Located in `app/api/*/route.ts`
- Export `POST`, `GET`, `PATCH`, `DELETE` handlers
- Use `createClient()` from `lib/supabase/server.ts`
- Return `NextResponse` objects

Example structure:
```typescript
import { createClient } from '@/lib/supabase/server'
import { NextResponse } from 'next/server'

export async function POST(request: Request) {
  const supabase = await createClient()
  // ... logic
  return NextResponse.json({ data })
}
```

### Flutter App Configuration

Both Flutter apps:
1. Require Flutter SDK 3.0.0+
2. Use Provider for state management
3. Connect to Next.js API backend
4. Store config in `lib/config/constants.dart` (not committed to git)

**Customer App** structure:
```
lib/
├── main.dart
├── config/constants.dart
├── models/          # user_model, vehicle_model, job_model
├── providers/       # auth_provider, job_provider
└── screens/         # splash, auth, home, booking, job, profile
```

**Technician App** structure:
```
lib/
├── main.dart
├── config/constants.dart
├── models/          # technician_model, job_model
├── providers/       # auth_provider, job_provider, location_provider
└── screens/         # splash, auth, home, jobs, profile
```

### Mobile App Notes

- **Customer app**: Handles booking flow, job tracking, payment management
- **Technician app**: Requires admin approval before accepting jobs
- Both apps require location permissions for job matching
- Technician app requires camera permissions for photo uploads
- Real-time location tracking needed during active jobs
- Google Maps integration requires platform-specific API key setup

### Development Workflow

1. **Backend changes**: Modify API routes in `app/api/`
2. **Database schema changes**: Update Supabase schema + regenerate types in `lib/types/database.ts`
3. **UI changes**: Edit components in `components/` or create new pages in `app/`
4. **Mobile changes**: Update Flutter apps and redeploy via respective build commands
5. **Type safety**: Always update TypeScript types when database schema changes

### Deployment

**Web App**:
- Typically deployed to Vercel (Next.js platform)
- Environment variables must be configured in deployment platform
- Automatic deployments on git push

**Flutter Apps**:
- Build release APK/IPA files
- Update `lib/config/constants.dart` with production URLs before building
- Distribute via Google Play Store / Apple App Store
