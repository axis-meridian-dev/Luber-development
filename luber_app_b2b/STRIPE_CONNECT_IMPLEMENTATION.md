# Stripe Connect Implementation Guide

This document explains the Stripe Connect integration for the Luber B2B platform, including setup, testing, and deployment instructions.

## Overview

The Luber B2B platform uses **Stripe Connect** with the **collect-then-transfer** pattern to split payments between shops and the platform:

- **Business Tier**: Shop receives 95%, platform keeps 5%
- **Solo Tier**: Shop receives 92%, platform keeps 8%

## Architecture

### Payment Flow

1. **Customer** books a service through the platform
2. **Platform** collects full payment via Stripe
3. **Platform** automatically transfers shop's portion (minus fee) to their Connect account
4. **Shop** receives payout directly from Stripe to their bank account

### Components

#### 1. Database Migration
**File**: `/scripts/010_add_stripe_connect_fields.sql`

Adds Stripe Connect fields to the `shops` table:
- `connect_account_id` - Stripe Connect account ID (acct_xxx)
- `connect_onboarding_completed` - Whether onboarding is complete
- `connect_charges_enabled` - Whether account can accept charges
- `connect_payouts_enabled` - Whether account can receive payouts
- `connect_details_submitted` - Whether all required info submitted
- `connect_requirements_currently_due` - Array of immediate requirements
- `connect_requirements_eventually_due` - Array of future requirements

**To Run:**
```sql
-- Execute in Supabase SQL Editor
-- Copy contents of 010_add_stripe_connect_fields.sql
```

#### 2. Stripe Connect Library
**File**: `/lib/stripe-connect.ts`

Server-only utility functions for Stripe Connect operations:

**Key Functions:**
- `createConnectAccount()` - Create Express Connect account for shop
- `createConnectAccountLink()` - Generate onboarding URL
- `getConnectAccountStatus()` - Check account status
- `calculatePaymentSplit()` - Calculate platform fee and shop payout
- `createPaymentIntentWithTransfer()` - Process payment with automatic transfer
- `createTransfer()` - Manual transfer (refunds, bonuses, etc.)
- `disconnectAccount()` - Delete Connect account

**Example Usage:**
```typescript
import { createPaymentIntentWithTransfer } from '@/lib/stripe-connect'

// Process a $100 booking for a Business tier shop
const paymentIntent = await createPaymentIntentWithTransfer(
  10000, // $100.00 in cents
  'acct_xxx', // Shop's Connect account ID
  'business', // Subscription tier
  'booking-uuid',
  'shop-uuid'
)
// Platform keeps $5, shop receives $95
```

#### 3. Webhook Handler
**File**: `/app/api/webhooks/stripe/route.ts`

Handles Stripe webhook events to keep database synchronized:

**Subscription Events:**
- `customer.subscription.created` - New subscription created
- `customer.subscription.updated` - Subscription status changed
- `customer.subscription.deleted` - Subscription canceled

**Payment Events:**
- `invoice.payment_succeeded` - Payment successful, activate subscription
- `invoice.payment_failed` - Payment failed, mark as past_due

**Connect Events:**
- `account.updated` - Connect account status changed (onboarding progress)

**Webhook URL:** `https://yourdomain.com/api/webhooks/stripe`

#### 4. Server Actions
**File**: `/app/actions/stripe-connect.ts`

React Server Actions for Connect operations in UI:

**Actions:**
- `createConnectAccountAction()` - Create Connect account for current shop
- `getConnectAccountLinkAction()` - Get onboarding link
- `getConnectAccountStatusAction()` - Get current status
- `refreshConnectAccountLinkAction()` - Refresh expired onboarding link
- `isConnectAccountReadyAction()` - Check if ready for payments

**Example Usage:**
```typescript
'use client'
import { createConnectAccountAction, getConnectAccountLinkAction } from '@/app/actions/stripe-connect'

async function setupPayments() {
  // Step 1: Create Connect account
  const { success, data } = await createConnectAccountAction()

  if (success && data) {
    // Step 2: Get onboarding link
    const linkResult = await getConnectAccountLinkAction(
      window.location.href, // refresh URL
      '/shop/settings?onboarding=complete' // return URL
    )

    if (linkResult.success && linkResult.data) {
      // Step 3: Redirect to Stripe onboarding
      window.location.href = linkResult.data.onboardingUrl
    }
  }
}
```

#### 5. TypeScript Types
**File**: `/lib/types/shop.ts`

Updated `Shop` interface includes Connect fields for type safety.

## Setup Instructions

### 1. Environment Variables

Add to `.env.local`:

```env
# Existing Stripe keys
STRIPE_SECRET_KEY=sk_test_xxx
NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY=pk_test_xxx

# Add these for webhooks and Connect
STRIPE_WEBHOOK_SECRET=whsec_xxx
STRIPE_CONNECT_CLIENT_ID=ca_xxx
```

**How to get these:**

1. **STRIPE_WEBHOOK_SECRET:**
   - Go to [Stripe Dashboard → Developers → Webhooks](https://dashboard.stripe.com/test/webhooks)
   - Click "Add endpoint"
   - Endpoint URL: `https://yourdomain.com/api/webhooks/stripe` (or ngrok for local testing)
   - Events to send: Select all or these specific events:
     - `customer.subscription.*`
     - `invoice.payment_succeeded`
     - `invoice.payment_failed`
     - `account.updated`
   - Copy the "Signing secret" (starts with `whsec_`)

2. **STRIPE_CONNECT_CLIENT_ID:**
   - Go to [Stripe Dashboard → Settings → Connect](https://dashboard.stripe.com/settings/connect)
   - Enable Connect if not already enabled
   - Copy the "Client ID" under "Integration" section (starts with `ca_`)

### 2. Run Database Migration

```bash
# Option 1: Via Supabase SQL Editor
# 1. Open Supabase Dashboard → SQL Editor
# 2. Copy contents of scripts/010_add_stripe_connect_fields.sql
# 3. Execute

# Option 2: Via Supabase CLI
supabase db push
```

**Verify migration:**
```sql
-- Check new columns exist
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'shops'
AND column_name LIKE 'connect_%';
```

### 3. Configure Stripe Connect Settings

In the [Stripe Dashboard → Connect Settings](https://dashboard.stripe.com/settings/connect):

1. **Account Type:** Express accounts (recommended for B2B platforms)
2. **Branding:** Upload Luber logo, set brand colors
3. **Redirect URLs:** Add your production and development URLs
4. **Webhook Endpoints:** Ensure webhook endpoint is configured (step 1 above)

## Testing Guide

### Local Testing with Stripe CLI

1. **Install Stripe CLI:**
   ```bash
   # macOS
   brew install stripe/stripe-cli/stripe

   # Linux
   curl -s https://packages.stripe.com/api/v1/gpg.key | sudo apt-key add -
   echo "deb https://packages.stripe.com/stripe-cli-debian-local stable main" | sudo tee /etc/apt/sources.list.d/stripe.list
   sudo apt update
   sudo apt install stripe
   ```

2. **Authenticate:**
   ```bash
   stripe login
   ```

3. **Forward webhooks to local dev server:**
   ```bash
   stripe listen --forward-to localhost:3000/api/webhooks/stripe

   # Copy the webhook signing secret (whsec_xxx) to .env.local
   ```

### Test Scenarios

#### Scenario 1: Create Connect Account & Complete Onboarding

```typescript
// In a test component or page
'use client'
import {
  createConnectAccountAction,
  getConnectAccountLinkAction,
  getConnectAccountStatusAction
} from '@/app/actions/stripe-connect'

export function ConnectOnboardingTest() {
  async function handleSetup() {
    // 1. Create account
    const result = await createConnectAccountAction()
    console.log('Account created:', result)

    // 2. Get onboarding link
    const linkResult = await getConnectAccountLinkAction(
      window.location.href,
      window.location.href + '?onboarding=complete'
    )
    console.log('Onboarding link:', linkResult)

    // 3. Redirect to Stripe (shop owner completes onboarding)
    if (linkResult.success && linkResult.data) {
      window.location.href = linkResult.data.onboardingUrl
    }
  }

  async function checkStatus() {
    const status = await getConnectAccountStatusAction()
    console.log('Account status:', status)
  }

  return (
    <div>
      <button onClick={handleSetup}>Setup Connect Account</button>
      <button onClick={checkStatus}>Check Status</button>
    </div>
  )
}
```

#### Scenario 2: Process Payment with Split

```typescript
import { createPaymentIntentWithTransfer } from '@/lib/stripe-connect'

// Business tier shop booking $150 oil change
const paymentIntent = await createPaymentIntentWithTransfer(
  15000, // $150.00
  'acct_test123', // Shop's Connect account
  'business', // 5% fee
  'booking-123',
  'shop-456'
)

console.log('Platform fee:', paymentIntent.application_fee_amount) // $7.50 (500 cents)
console.log('Shop receives:', 15000 - 750) // $142.50 (14250 cents)
```

#### Scenario 3: Test Webhook Events

```bash
# With Stripe CLI listening, trigger test events:

# Test subscription created
stripe trigger customer.subscription.created

# Test payment succeeded
stripe trigger invoice.payment_succeeded

# Test payment failed
stripe trigger invoice.payment_failed

# Test Connect account updated
stripe trigger account.updated
```

Check your terminal logs and database to verify events are processed correctly.

### Test Cards

Use [Stripe test cards](https://stripe.com/docs/testing):

- **Success:** `4242 4242 4242 4242`
- **Decline:** `4000 0000 0000 0002`
- **Requires authentication:** `4000 0025 0000 3155`

## Production Deployment Checklist

- [ ] Run database migration in production Supabase
- [ ] Set production environment variables (use live keys, not test keys)
- [ ] Configure production webhook endpoint in Stripe Dashboard
- [ ] Verify webhook signing secret matches production
- [ ] Test Connect onboarding with real shop owner account
- [ ] Test payment flow end-to-end
- [ ] Configure Stripe Connect branding (logo, colors, support email)
- [ ] Set up monitoring for webhook failures
- [ ] Implement email notifications for payment failures
- [ ] Add error tracking (Sentry, LogRocket, etc.)

## Monitoring & Troubleshooting

### Check Webhook Logs

1. Go to [Stripe Dashboard → Developers → Webhooks](https://dashboard.stripe.com/webhooks)
2. Click on your endpoint
3. View "Attempts" tab to see all webhook deliveries and responses

### Common Issues

**Issue:** Webhook signature verification fails
- **Solution:** Ensure `STRIPE_WEBHOOK_SECRET` matches the endpoint's signing secret
- Check that you're using the raw request body (no parsing)

**Issue:** Connect account onboarding link expired
- **Solution:** Links expire after 5 minutes. Use `refreshConnectAccountLinkAction()` to generate a new link

**Issue:** Shop not receiving payouts
- **Solution:** Check `connect_payouts_enabled` field. If false, shop hasn't completed onboarding or Stripe detected an issue. Check `connect_requirements_currently_due` for details.

**Issue:** Transfer fails with "No such destination"
- **Solution:** Ensure Connect account ID is valid and saved correctly. Run `getConnectAccountStatusAction()` to verify.

### Database Queries for Debugging

```sql
-- Check all shops with Connect accounts
SELECT
  id,
  shop_name,
  connect_account_id,
  connect_onboarding_completed,
  connect_charges_enabled,
  connect_payouts_enabled
FROM shops
WHERE connect_account_id IS NOT NULL;

-- Check subscription history for payment issues
SELECT
  shop_id,
  event_type,
  amount_paid,
  created_at,
  metadata
FROM shop_subscription_history
WHERE event_type IN ('payment_failed', 'payment_succeeded')
ORDER BY created_at DESC
LIMIT 20;

-- Check shops with incomplete onboarding
SELECT
  id,
  shop_name,
  business_email,
  connect_requirements_currently_due
FROM shops
WHERE connect_account_id IS NOT NULL
  AND connect_onboarding_completed = false;
```

## Security Considerations

1. **Webhook Signature Verification:** Always verify webhook signatures to prevent spoofing
2. **Server-Only Code:** Stripe secret key must never be exposed to client
3. **RLS Policies:** Ensure shops can only access their own Connect account data
4. **Connect Account Isolation:** Each shop has separate Connect account (no shared accounts)
5. **Audit Trail:** All payment events logged to `shop_subscription_history`

## Business Logic Reference

### Payment Split Calculation

```typescript
// Business Tier (5% platform fee)
const totalAmount = 10000 // $100.00
const platformFee = Math.round(10000 * 0.05) // $5.00 (500 cents)
const shopPayout = 10000 - 500 // $95.00 (9500 cents)

// Solo Tier (8% platform fee)
const totalAmount = 10000 // $100.00
const platformFee = Math.round(10000 * 0.08) // $8.00 (800 cents)
const shopPayout = 10000 - 800 // $92.00 (9200 cents)
```

### Subscription Status Flow

```
trialing → active (on successful payment)
active → past_due (on payment failure)
past_due → active (on successful retry)
past_due → canceled (after max retries)
active → canceled (on manual cancellation)
```

## Next Steps

After implementing Stripe Connect, you should:

1. **Build UI Components:**
   - Connect onboarding wizard in `/app/shop/onboarding`
   - Payment status indicator in shop dashboard
   - Payout history display

2. **Implement Payment Flow:**
   - Update booking creation to use `createPaymentIntentWithTransfer()`
   - Add payment confirmation screen
   - Show shop earnings in booking details

3. **Add Notifications:**
   - Email shop owner when payment fails
   - Notify when Connect onboarding is incomplete
   - Alert when requirements are due

4. **Analytics Dashboard:**
   - Total revenue processed
   - Platform fees collected
   - Shop payouts by time period
   - Failed payment tracking

## Resources

- [Stripe Connect Documentation](https://stripe.com/docs/connect)
- [Stripe Express Accounts](https://stripe.com/docs/connect/express-accounts)
- [Stripe Webhooks Guide](https://stripe.com/docs/webhooks)
- [Stripe Testing](https://stripe.com/docs/testing)
- [Stripe Connect Platform Controls](https://stripe.com/docs/connect/platform-controls-for-standard-accounts)
