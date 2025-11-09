# Stripe Connect Implementation Summary

## Files Created

### 1. Database Migration
**Location**: `/home/axmh/Development/Luber-development/luber_app_b2b/scripts/010_add_stripe_connect_fields.sql`

Adds Stripe Connect fields to the `shops` table:
- `connect_account_id` (TEXT, UNIQUE) - Stripe Connect account ID
- `connect_onboarding_completed` (BOOLEAN) - Onboarding completion status
- `connect_charges_enabled` (BOOLEAN) - Can accept charges
- `connect_payouts_enabled` (BOOLEAN) - Can receive payouts
- `connect_details_submitted` (BOOLEAN) - All info submitted
- `connect_requirements_currently_due` (TEXT[]) - Immediate requirements
- `connect_requirements_eventually_due` (TEXT[]) - Future requirements

**Next Step**: Run this migration in Supabase SQL Editor before testing.

### 2. Stripe Connect Library
**Location**: `/home/axmh/Development/Luber-development/luber_app_b2b/lib/stripe-connect.ts`

Server-only utilities marked with `"server-only"` directive.

**Functions**:
- `createConnectAccount()` - Creates Express Connect account
- `createConnectAccountLink()` - Generates onboarding URL (expires in 5 min)
- `getConnectAccountStatus()` - Fetches account status from Stripe
- `calculatePaymentSplit()` - Calculates fees based on tier (5% or 8%)
- `createPaymentIntentWithTransfer()` - Main payment processing function
- `createTransfer()` - Manual transfers (refunds, bonuses)
- `disconnectAccount()` - Delete Connect account
- `updateConnectAccountCapabilities()` - Update account capabilities

**Business Logic**:
- Business tier: 95% to shop, 5% to platform
- Solo tier: 92% to shop, 8% to platform

### 3. Webhook Handler
**Location**: `/home/axmh/Development/Luber-development/luber_app_b2b/app/api/webhooks/stripe/route.ts`

API route that handles Stripe webhook events.

**Handles**:
- `customer.subscription.created` - Update shop subscription status to active
- `customer.subscription.updated` - Update subscription details
- `customer.subscription.deleted` - Mark subscription as canceled
- `invoice.payment_succeeded` - Confirm payment, set status to active
- `invoice.payment_failed` - Mark as past_due, log failure
- `account.updated` - Update Connect account onboarding status

**Security**: Verifies webhook signature using `STRIPE_WEBHOOK_SECRET`.

**Endpoint**: `https://yourdomain.com/api/webhooks/stripe`

### 4. Server Actions
**Location**: `/home/axmh/Development/Luber-development/luber_app_b2b/app/actions/stripe-connect.ts`

React Server Actions for UI integration.

**Actions**:
- `createConnectAccountAction()` - Create account for authenticated shop owner
- `getConnectAccountLinkAction()` - Get onboarding link
- `getConnectAccountStatusAction()` - Check account status
- `refreshConnectAccountLinkAction()` - Refresh expired link
- `isConnectAccountReadyAction()` - Check if ready to accept payments

**Authorization**: All actions verify user is shop owner via Supabase auth.

### 5. TypeScript Types
**Updated**: `/home/axmh/Development/Luber-development/luber_app_b2b/lib/types/shop.ts`

Added Connect fields to `Shop` interface for type safety.

### 6. Documentation
**Location**: `/home/axmh/Development/Luber-development/luber_app_b2b/STRIPE_CONNECT_IMPLEMENTATION.md`

Complete guide covering:
- Architecture overview
- Setup instructions
- Testing guide with scenarios
- Production deployment checklist
- Troubleshooting tips

## Required Environment Variables

Add these to `.env.local`:

```env
# Existing
STRIPE_SECRET_KEY=sk_test_xxx
NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY=pk_test_xxx

# New (required for Connect)
STRIPE_WEBHOOK_SECRET=whsec_xxx
STRIPE_CONNECT_CLIENT_ID=ca_xxx
```

## Implementation Checklist

### Database Setup
- [ ] Run migration `010_add_stripe_connect_fields.sql` in Supabase SQL Editor
- [ ] Verify new columns exist with query: `SELECT * FROM shops LIMIT 1`

### Stripe Dashboard Setup
- [ ] Enable Stripe Connect in Dashboard → Settings → Connect
- [ ] Copy Connect Client ID (`ca_xxx`) to `.env.local`
- [ ] Configure webhook endpoint: `/api/webhooks/stripe`
- [ ] Select events: `customer.subscription.*`, `invoice.*`, `account.updated`
- [ ] Copy webhook signing secret (`whsec_xxx`) to `.env.local`

### Local Testing
- [ ] Install Stripe CLI: `brew install stripe/stripe-cli/stripe`
- [ ] Forward webhooks: `stripe listen --forward-to localhost:3000/api/webhooks/stripe`
- [ ] Test Connect onboarding flow with test shop account
- [ ] Test payment splitting with test card `4242 4242 4242 4242`
- [ ] Verify webhook events in terminal logs

### Production Deployment
- [ ] Run migration in production Supabase
- [ ] Set production environment variables (live keys)
- [ ] Configure production webhook endpoint in Stripe Dashboard
- [ ] Test end-to-end payment flow
- [ ] Monitor webhook logs for errors

## Usage Examples

### Create Connect Account & Onboard Shop Owner

```typescript
'use client'
import {
  createConnectAccountAction,
  getConnectAccountLinkAction
} from '@/app/actions/stripe-connect'

async function setupPayments() {
  // 1. Create Connect account
  const { success, data } = await createConnectAccountAction()

  if (success && data) {
    // 2. Get onboarding link
    const linkResult = await getConnectAccountLinkAction(
      window.location.href, // Refresh URL
      '/shop/settings?onboarding=complete' // Return URL
    )

    if (linkResult.success && linkResult.data) {
      // 3. Redirect to Stripe onboarding
      window.location.href = linkResult.data.onboardingUrl
    }
  }
}
```

### Check Connect Account Status

```typescript
import { getConnectAccountStatusAction } from '@/app/actions/stripe-connect'

const { success, data } = await getConnectAccountStatusAction()

if (success && data) {
  console.log('Onboarding completed:', data.onboardingCompleted)
  console.log('Charges enabled:', data.chargesEnabled)
  console.log('Payouts enabled:', data.payoutsEnabled)
  console.log('Requirements:', data.requirementsCurrentlyDue)
}
```

### Process Payment with Split

```typescript
// Server-side code only (marked "server-only")
import { createPaymentIntentWithTransfer } from '@/lib/stripe-connect'

const paymentIntent = await createPaymentIntentWithTransfer(
  15000, // $150.00 in cents
  'acct_xxx', // Shop's Connect account ID
  'business', // Subscription tier (5% fee)
  'booking-uuid',
  'shop-uuid'
)

// Platform keeps: $7.50 (500 cents)
// Shop receives: $142.50 (14250 cents)
```

### Calculate Payment Split

```typescript
import { calculatePaymentSplit } from '@/lib/stripe-connect'

// Business tier
const { platformFee, shopPayout } = calculatePaymentSplit(10000, 'business')
// platformFee: 500 ($5.00)
// shopPayout: 9500 ($95.00)

// Solo tier
const { platformFee, shopPayout } = calculatePaymentSplit(10000, 'solo')
// platformFee: 800 ($8.00)
// shopPayout: 9200 ($92.00)
```

## Architecture Notes

### Payment Flow
1. Customer books service through platform
2. Platform creates PaymentIntent with `application_fee_amount` (platform fee)
3. Platform collects full payment from customer
4. Stripe automatically transfers shop's portion to their Connect account
5. Shop receives payout to their bank account (Stripe handles this)

### Webhook Flow
1. Stripe sends webhook POST to `/api/webhooks/stripe`
2. Webhook handler verifies signature
3. Handler processes event based on type
4. Database updated accordingly
5. Handler returns 200 (or 500 to trigger retry)

### Onboarding Flow
1. Shop owner creates account on platform
2. Platform calls `createConnectAccount()` → creates Stripe Express account
3. Platform calls `createConnectAccountLink()` → gets onboarding URL
4. Shop owner redirected to Stripe to complete onboarding (identity, bank details)
5. Stripe sends `account.updated` webhook when complete
6. Platform enables payments for shop

## Security Considerations

1. **Webhook Signature Verification**: Always verify before processing
2. **Server-Only Code**: Stripe secret key never exposed to client
3. **Row Level Security**: Shops can only access their own Connect data
4. **Audit Trail**: All events logged to `shop_subscription_history`
5. **Connect Account Isolation**: Each shop has separate Connect account

## Next Steps

To complete the integration, you need to:

1. **Build UI Components**:
   - Connect onboarding wizard (redirect to Stripe)
   - Payment status indicator in shop dashboard
   - Payout history display
   - Requirements notification banner

2. **Update Booking Flow**:
   - Use `createPaymentIntentWithTransfer()` when creating bookings
   - Show shop earnings breakdown (total - platform fee)
   - Display transaction fee on invoice

3. **Add Notifications**:
   - Email shop owner when Connect onboarding incomplete
   - Alert when payment fails
   - Notify when requirements due

4. **Build Analytics**:
   - Total platform fees collected
   - Shop payouts by time period
   - Failed payment tracking

## Testing Stripe CLI Commands

```bash
# Install Stripe CLI
brew install stripe/stripe-cli/stripe

# Login
stripe login

# Forward webhooks to local dev
stripe listen --forward-to localhost:3000/api/webhooks/stripe

# Trigger test events
stripe trigger customer.subscription.created
stripe trigger invoice.payment_succeeded
stripe trigger invoice.payment_failed
stripe trigger account.updated
```

## Troubleshooting

### Webhook signature verification fails
- Ensure `STRIPE_WEBHOOK_SECRET` matches endpoint's signing secret in Stripe Dashboard
- Check that you're using raw request body (Next.js route handlers do this automatically)

### Connect onboarding link expired
- Links expire after 5 minutes
- Use `refreshConnectAccountLinkAction()` to generate new link

### Shop not receiving payouts
- Check `connect_payouts_enabled` in database
- Verify onboarding completed: `connect_onboarding_completed = true`
- Check `connect_requirements_currently_due` for missing info

### Transfer fails
- Ensure Connect account exists and is valid
- Verify `connect_charges_enabled = true`
- Check Stripe Dashboard logs for detailed error

## Resources

- [Stripe Connect Docs](https://stripe.com/docs/connect)
- [Stripe Webhooks](https://stripe.com/docs/webhooks)
- [Stripe Testing](https://stripe.com/docs/testing)
- [Next.js API Routes](https://nextjs.org/docs/app/building-your-application/routing/route-handlers)
