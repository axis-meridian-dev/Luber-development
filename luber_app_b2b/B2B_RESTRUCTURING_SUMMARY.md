# Luber B2B SaaS Restructuring Summary

## Overview

This document tracks the transformation of Luber from a consumer marketplace (connecting customers with individual technicians) to a B2B SaaS platform (licensed mechanics and auto shops running their mobile business).

**Date:** November 4, 2025
**Status:** Phase 1 - Database & Types Complete ✅

---

## What Has Been Completed ✅

### 1. Database Schema (DONE)

All foundational database tables and migrations have been created:

**Existing from Previous Work:**
- ✅ `shops` table - Shop information, subscription, branding
- ✅ `shop_technicians` table - Shop employees (junction table)
- ✅ `shop_service_packages` table - Custom pricing per shop
- ✅ `shop_subscription_history` table - Billing audit trail
- ✅ Updated `bookings` table with shop fields (shop_id, shop_technician_id, service_package_id, transaction_fee, shop_payout)
- ✅ RLS policies for shops, technicians, packages
- ✅ Triggers for auto-updating shop metrics

**New Migrations Created:**
- ✅ `007_update_user_roles_for_b2b.sql` - User role system
  - Added roles: `shop_owner`, `shop_mechanic`, `solo_mechanic`
  - Added `shop_id` column to profiles for shop mechanics
  - Added `role_metadata` JSONB column for role-specific data
  - Created helper functions: `user_can_access_shop()`, role consistency checks
  - Created views: `active_shop_owners`, `shop_mechanics_with_shop`
  - RLS policies for role-based access

- ✅ `008_update_reviews_for_shops.sql` - Shop-level reviews
  - Added `shop_id` to reviews table
  - Made `technician_id` nullable (reviews for shops OR solo mechanics)
  - Added detailed rating fields (service_quality, communication, value)
  - Added `would_recommend` boolean
  - Auto-generated `review_type` (shop vs solo_mechanic)
  - Created views: `shop_reviews_summary`, `solo_mechanic_reviews_summary`
  - Triggers to auto-update ratings when reviews are created

### 2. TypeScript Types (DONE)

All type definitions have been created/updated:

- ✅ `lib/types/user.ts` - User roles and profiles
  - `UserRole` type with all 6 roles
  - `Profile` interface with new fields
  - `Customer`, `Technician` interfaces
  - Role-specific metadata types
  - Type guard functions (isShopOwner, canManageShop, etc.)

- ✅ `lib/types/booking.ts` - Bookings and reviews
  - Updated `Booking` interface with shop fields
  - Updated `Review` interface with shop/solo mechanic support
  - Review summary types
  - Helper functions (isShopBooking, calculateShopPayout, etc.)

- ✅ `lib/types/shop.ts` - Shop entities (already existed)
  - `Shop`, `ShopTechnician`, `ShopServicePackage`

- ✅ `lib/types/index.ts` - Central export file

### 3. Stripe Configuration (DONE)

- ✅ `lib/stripe.ts` - Subscription plans defined
  - Solo Mechanic: $99/month + 8% transaction fee
  - Business: $299/month + $49/technician + 5% transaction fee
  - Plan features documented

### 4. Package Management (DONE)

- ✅ Resolved `package.json` merge conflict
- ✅ All dependencies properly configured

---

## What Exists But Needs Work 🚧

### 1. Shop Dashboard Pages (Partial)

These pages exist but may need enhancement:
- `/app/shop/dashboard/page.tsx` - Basic dashboard with stats ✅
- `/app/shop/bookings/` - Needs implementation
- `/app/shop/technicians/` - Needs implementation
- `/app/shop/dispatch/` - Needs implementation
- `/app/shop/packages/` - Needs implementation
- `/app/shop/settings/` - Needs implementation
- `/app/shop/subscription/` - Needs implementation

### 2. Onboarding Flow

- `/app/onboarding/` - Exists but needs to be updated for:
  - License verification
  - Insurance verification
  - Shop vs Solo mechanic selection
  - Subscription tier selection

---

## What Still Needs to Be Built 🔨

### Phase 2: Core Shop Features (Week 1-2)

#### 1. Stripe Connect Integration
**File:** `lib/stripe-connect.ts`
**Purpose:** Payment splitting for shops

**Tasks:**
- [ ] Set up Stripe Connect onboarding
- [ ] Create connected accounts for shops
- [ ] Implement payment splitting logic (95% to shop, 5% platform fee OR 92%, 8%)
- [ ] Handle failed payments and retries
- [ ] Implement subscription billing webhooks

**Priority:** HIGH - Required for shop payouts

#### 2. Custom Pricing Packages Management
**File:** `/app/shop/packages/page.tsx`

**Features needed:**
- [ ] List all service packages
- [ ] Create new package form
- [ ] Edit existing package
- [ ] Toggle package active/inactive
- [ ] Set pricing, duration, oil type, inclusions
- [ ] Validation (prevent duplicate package names)

**Priority:** HIGH - Shops need to set their pricing

#### 3. Shop Technicians Management
**File:** `/app/shop/technicians/page.tsx`

**Features needed:**
- [ ] List all shop employees
- [ ] Invite new technician (send email invite)
- [ ] View technician details (jobs, ratings, availability)
- [ ] Remove technician from shop
- [ ] Update technician license/certification info
- [ ] Technician performance metrics

**Priority:** MEDIUM - Business tier feature

#### 4. Dispatch System
**File:** `/app/shop/dispatch/page.tsx`

**Features needed:**
- [ ] Map view of available technicians
- [ ] List of pending bookings
- [ ] Drag-and-drop job assignment
- [ ] Auto-assign based on proximity/availability
- [ ] Real-time technician location tracking
- [ ] Job reassignment

**Priority:** MEDIUM - Business tier feature

### Phase 3: Onboarding & Verification (Week 2)

#### 5. Updated Onboarding Flow

**Files:**
- `/app/onboarding/step-1/page.tsx` - Role selection
- `/app/onboarding/step-2/page.tsx` - Business info
- `/app/onboarding/step-3/page.tsx` - License/insurance upload
- `/app/onboarding/step-4/page.tsx` - Subscription selection
- `/app/onboarding/step-5/page.tsx` - Payment setup

**Features needed:**
- [ ] Multi-step wizard with progress indicator
- [ ] Role selection: Solo Mechanic vs Business
- [ ] Business information form (name, license, insurance)
- [ ] Document upload (license, insurance certificate)
- [ ] Subscription tier selection with pricing comparison
- [ ] Stripe checkout integration
- [ ] Welcome email after completion

**Priority:** HIGH - Required for shop signups

#### 6. License/Insurance Verification

**File:** `/app/admin/verification/page.tsx`

**Features needed:**
- [ ] Admin dashboard to review submitted documents
- [ ] Approve/reject license verification
- [ ] Approve/reject insurance verification
- [ ] Send notification emails
- [ ] Set shop status to active/inactive based on verification

**Priority:** MEDIUM - Manual verification initially, can automate later

### Phase 4: Mobile Apps (Week 3)

#### 7. Customer App Updates (Flutter)

**Directory:** `flutter_customer_app/`

**Features needed:**
- [ ] Show shop branding when booking through a shop
- [ ] Display shop's custom pricing
- [ ] Show shop service packages
- [ ] Shop reviews (not individual tech reviews)
- [ ] Shop logo and colors in booking flow

**Priority:** MEDIUM - Enhances customer experience

#### 8. Technician App Updates (Flutter)

**Directory:** `flutter_technician_app/`

**Features needed:**
- [ ] Shop branding in app header (for shop mechanics)
- [ ] Distinguish assigned jobs vs self-accepted jobs
- [ ] View shop's procedures/pricing for each service
- [ ] Clock in/out tracking (for shops to track hours)
- [ ] Shop mechanic vs solo mechanic mode toggle

**Priority:** MEDIUM - Required for shop employees

### Phase 5: Analytics & Reporting (Week 3-4)

#### 9. Shop Analytics Dashboard

**File:** `/app/shop/analytics/page.tsx`

**Features needed:**
- [ ] Revenue charts (daily, weekly, monthly)
- [ ] Job completion rate
- [ ] Average job value
- [ ] Customer ratings over time
- [ ] Technician performance comparison
- [ ] Export to CSV/PDF

**Priority:** LOW - Business tier feature, nice-to-have

#### 10. Admin Platform Management

**File:** `/app/admin/shops/page.tsx`

**Features needed:**
- [ ] View all shops
- [ ] Shop search and filtering
- [ ] Manually activate/deactivate shops
- [ ] View subscription status
- [ ] Revenue reporting (platform fees collected)
- [ ] Dispute resolution tools

**Priority:** LOW - Admin tooling

---

## Migration Execution Plan

### Step 1: Run Existing Migrations (If Not Already Done)

```bash
# Connect to your Supabase project
# Navigate to SQL Editor in Supabase Dashboard

# Run in order:
1. scripts/001_create_tables.sql
2. scripts/002_create_triggers.sql
3. scripts/003_seed_data.sql (optional, for test data)
4. scripts/004_create_admin_user.sql
5. scripts/005_create_shops_and_subscriptions.sql
6. scripts/006_add_enterprise_and_tracking.sql
```

### Step 2: Run New Migrations

```bash
# In Supabase SQL Editor:
7. scripts/007_update_user_roles_for_b2b.sql
8. scripts/008_update_reviews_for_shops.sql
```

### Step 3: Verify Migrations

```sql
-- Check that new columns exist
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'profiles'
AND column_name IN ('shop_id', 'role_metadata');

-- Check that new enum values exist
SELECT enumlabel
FROM pg_enum
JOIN pg_type ON pg_enum.enumtypid = pg_type.oid
WHERE pg_type.typname = 'user_role';

-- Check that new views exist
SELECT viewname
FROM pg_views
WHERE schemaname = 'public'
AND viewname IN ('shop_reviews_summary', 'active_shop_owners');
```

### Step 4: Test with Sample Data

```sql
-- Create a test shop owner
INSERT INTO auth.users (id, email) VALUES ('test-uuid-1', 'testshop@example.com');

INSERT INTO profiles (id, email, full_name, role)
VALUES ('test-uuid-1', 'testshop@example.com', 'Test Shop Owner', 'shop_owner');

INSERT INTO shops (
  owner_id, shop_name, business_legal_name, business_license_number,
  insurance_policy_number, insurance_expiry_date, business_email,
  business_phone, business_address, business_city, business_state,
  business_zip, subscription_tier
) VALUES (
  'test-uuid-1', 'Test Auto Shop', 'Test Auto Shop LLC', 'LIC123456',
  'INS789012', '2026-12-31', 'shop@test.com',
  '555-0100', '123 Main St', 'San Francisco', 'CA',
  '94102', 'solo'
);

-- Verify shop was created
SELECT * FROM shops WHERE owner_id = 'test-uuid-1';
```

---

## Implementation Priority Order

Based on dependencies and business value:

1. **CRITICAL (Do First):**
   - ✅ Database migrations (DONE)
   - ✅ TypeScript types (DONE)
   - 🔨 Stripe Connect integration
   - 🔨 Updated onboarding flow
   - 🔨 Custom pricing packages UI

2. **HIGH (Do Second):**
   - 🔨 Shop technicians management
   - 🔨 Dispatch system
   - 🔨 License/insurance verification

3. **MEDIUM (Do Third):**
   - 🔨 Customer app shop branding
   - 🔨 Technician app updates
   - 🔨 Shop analytics

4. **LOW (Do Last):**
   - 🔨 Admin platform management
   - 🔨 Advanced reporting

---

## Testing Checklist

Before launch, verify:

- [ ] Solo mechanic can sign up and create account
- [ ] Shop owner can sign up and create shop
- [ ] Shop owner can add technicians to shop
- [ ] Shop owner can create custom pricing packages
- [ ] Customer can book service through shop
- [ ] Customer sees shop branding throughout flow
- [ ] Payment splits correctly (95% to shop, 5% platform)
- [ ] Shop subscription charges monthly
- [ ] Reviews are tied to shop, not individual tech
- [ ] Shop owner can view all shop bookings
- [ ] Shop owner can assign jobs to technicians
- [ ] Technician app shows assigned jobs
- [ ] Shop metrics auto-update (total_technicians, total_bookings, total_revenue)

---

## Environment Variables Required

Make sure these are set in `.env.local`:

```env
# Supabase
NEXT_PUBLIC_SUPABASE_LUBER_PUBLIC_SUPABASE_URL=your-project-url
NEXT_PUBLIC_SUPABASE_LUBER_PUBLIC_SUPABASE_ANON_KEY=your-anon-key
SUPABASE_URL=your-project-url
SUPABASE_ANON_KEY=your-anon-key

# Stripe
STRIPE_SECRET_KEY=sk_test_...
NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY=pk_test_...
STRIPE_WEBHOOK_SECRET=whsec_...

# Stripe Connect (new, required for payment splitting)
STRIPE_CONNECT_CLIENT_ID=ca_...
```

---

## Known Issues & Considerations

### 1. Legacy Technician Accounts

**Issue:** Old `technicians` table still exists alongside new `shop_technicians` table.

**Solution Options:**
- Option A: Keep both tables, use `user.role` to distinguish
- Option B: Migrate all existing technicians to `solo_mechanic` role
- Option C: Create migration wizard for existing techs to choose shop vs solo

**Recommendation:** Option A for now, clean up after migration stabilizes.

### 2. Can Users Be Both Solo & Shop Mechanic?

**Decision:** NO (per spec)
**Implementation:** Add constraint in app logic to prevent users from having both roles

### 3. Subscription Downgrades

**Issue:** What happens when Business shop downgrades to Solo?
**Solution needed:**
- Disable additional technicians
- Send notification
- Allow 30-day grace period to remove techs or upgrade

### 4. Shop Deletion

**Issue:** What happens to bookings/reviews when shop is deleted?
**Current:** Database uses `ON DELETE CASCADE` for shops
**Consideration:** May want to soft-delete shops instead, keep historical data

---

## Next Steps

**Immediate (This Week):**
1. Run new database migrations (007, 008)
2. Test migrations with sample data
3. Start implementing Stripe Connect

**Short-term (Next 2 Weeks):**
1. Build shop packages management UI
2. Update onboarding flow
3. Build technicians management UI
4. Build dispatch system

**Medium-term (Weeks 3-4):**
1. Update Flutter apps
2. Build analytics dashboard
3. End-to-end testing
4. Beta shop signups

**Long-term:**
- Automated license verification (integrate with state DMV APIs)
- White-label domain support (CNAME records)
- Mobile technician app iOS/Android native builds
- Advanced analytics (ML-powered demand forecasting)

---

## Questions for Stakeholders

1. **Pricing:** Are the subscription prices ($99 solo, $299 business) final?
2. **Transaction Fees:** Confirm 8% (solo) and 5% (business) are correct
3. **License Verification:** Manual review initially, or integrate with third-party service?
4. **Free Trial:** How many days trial period? (currently set to "trialing" status)
5. **Shop Limits:** Business tier limited to 10 technicians - is this enforced?
6. **Payment Splitting:** When do shops get paid? (immediately after job, weekly batch, etc.)

---

## Resources & References

- **Database Schema:** See `/scripts/*.sql` files
- **TypeScript Types:** See `/lib/types/` directory
- **Stripe Plans:** See `/lib/stripe.ts`
- **Original Spec:** See restructuring document at top of this conversation
- **Supabase Docs:** https://supabase.com/docs
- **Stripe Connect Docs:** https://stripe.com/docs/connect

---

**Last Updated:** November 4, 2025
**Next Review:** After Stripe Connect implementation
