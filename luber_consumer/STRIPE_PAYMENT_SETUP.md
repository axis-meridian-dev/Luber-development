# Stripe Payment Method Integration - Implementation Guide

This document outlines the complete Stripe payment method integration for the Luber Consumer application.

## Overview

The payment method system allows customers to:
- Add credit/debit cards securely via Stripe Elements
- Set a default payment method
- Delete saved payment methods
- View all saved cards with expiration dates

## Files Created/Modified

### 1. Dependencies Added
**File**: `/home/axmh/Development/Luber-development/luber_consumer/package.json`

Added Stripe client-side libraries:
```json
"@stripe/stripe-js": "^4.9.0",
"@stripe/react-stripe-js": "^3.1.0"
```

After updating `package.json`, run:
```bash
cd /home/axmh/Development/Luber-development/luber_consumer
npm install --legacy-peer-deps
```

### 2. Database Migration
**File**: `/home/axmh/Development/Luber-development/luber_consumer/scripts/006_add_payment_method_fields.sql`

Adds required fields to support Stripe integration:
- `profiles.stripe_customer_id` - Links Supabase user to Stripe customer
- `payment_methods.exp_month` - Card expiration month
- `payment_methods.exp_year` - Card expiration year

**To apply the migration:**
1. Go to your Supabase project dashboard
2. Navigate to SQL Editor
3. Copy and paste the contents of `006_add_payment_method_fields.sql`
4. Execute the SQL

### 3. Stripe Elements Provider
**File**: `/home/axmh/Development/Luber-development/luber_consumer/lib/stripe-elements.tsx`

Wrapper component that initializes Stripe.js and provides the Elements context to child components. Features:
- Lazy-loads Stripe.js for performance
- Configures Stripe appearance to match app theme
- Shows loading state while Stripe initializes

### 4. API Routes

#### Add Payment Method
**File**: `/home/axmh/Development/Luber-development/luber_consumer/app/api/payment-methods/add/route.ts`

**Endpoint**: `POST /api/payment-methods/add`

**Request Body**:
```json
{
  "paymentMethodId": "pm_xxx", // Stripe payment method ID
  "setAsDefault": true // Optional, defaults to false
}
```

**Functionality**:
1. Verifies user authentication
2. Creates Stripe customer if doesn't exist
3. Attaches payment method to Stripe customer
4. Saves payment method details to database
5. Sets as default if requested or if it's the first card
6. Updates Stripe customer's default payment method

**Response**:
```json
{
  "paymentMethod": {
    "id": "uuid",
    "stripe_payment_method_id": "pm_xxx",
    "card_brand": "visa",
    "card_last4": "4242",
    "exp_month": 12,
    "exp_year": 2025,
    "is_default": true
  }
}
```

#### Set Default Payment Method
**File**: `/home/axmh/Development/Luber-development/luber_consumer/app/api/payment-methods/set-default/route.ts`

**Endpoint**: `POST /api/payment-methods/set-default`

**Request Body**:
```json
{
  "paymentMethodId": "uuid" // Database payment method ID
}
```

**Functionality**:
1. Verifies payment method belongs to authenticated user
2. Unsets all existing default flags
3. Sets selected payment method as default
4. Updates Stripe customer's default payment method

#### Delete Payment Method
**File**: `/home/axmh/Development/Luber-development/luber_consumer/app/api/payment-methods/delete/route.ts`

**Endpoint**: `DELETE /api/payment-methods/delete`

**Request Body**:
```json
{
  "paymentMethodId": "uuid" // Database payment method ID
}
```

**Functionality**:
1. Verifies payment method belongs to authenticated user
2. Detaches payment method from Stripe customer
3. Deletes from database
4. If deleted card was default, automatically sets another card as default

### 5. Frontend Pages

#### Add Payment Method Page
**File**: `/home/axmh/Development/Luber-development/luber_consumer/app/customer/payment-methods/new/page.tsx`

**Route**: `/customer/payment-methods/new`

**Features**:
- Stripe Payment Element for secure card input
- Cardholder name field
- "Set as default" checkbox
- Real-time validation via Stripe
- Loading states during submission
- Error handling with user-friendly messages
- Test card information displayed in development

**User Flow**:
1. User enters cardholder name
2. User enters card details via Stripe Payment Element
3. Optionally checks "Set as default"
4. Clicks "Add Payment Method"
5. Stripe creates payment method token
6. API saves to database and Stripe customer
7. User redirected to payment methods list

#### Payment Methods List Page
**File**: `/home/axmh/Development/Luber-development/luber_consumer/app/customer/payment-methods/page.tsx`

**Route**: `/customer/payment-methods`

**Features**:
- Lists all saved payment methods
- Shows card brand, last 4 digits, and expiration
- "Default" badge on default card
- "Set as Default" button for non-default cards
- "Delete" button with confirmation dialog
- Empty state with "Add Card" CTA
- Real-time updates after actions

## Environment Variables

Required in `.env.local`:

```bash
# Stripe Configuration
STRIPE_SECRET_KEY=sk_test_...                    # Server-side only
NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY=pk_test_...   # Client-side
```

### Getting Stripe Keys:

1. Go to [Stripe Dashboard](https://dashboard.stripe.com)
2. Navigate to Developers → API keys
3. For testing, use **Test mode** keys
4. Copy "Publishable key" to `NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY`
5. Click "Reveal test key" and copy "Secret key" to `STRIPE_SECRET_KEY`

## Testing

### Test Cards (Stripe Test Mode)

Use these cards for testing:

**Success:**
- Card: `4242 4242 4242 4242`
- Expiry: Any future date (e.g., 12/25)
- CVC: Any 3 digits (e.g., 123)
- ZIP: Any 5 digits (e.g., 12345)

**Card Declined:**
- Card: `4000 0000 0000 0002`

**Insufficient Funds:**
- Card: `4000 0000 0000 9995`

**More test cards**: https://stripe.com/docs/testing

### Testing Workflow:

1. Start the development server:
   ```bash
   npm run dev
   ```

2. Navigate to `/customer/payment-methods`

3. Click "Add Card"

4. Enter test card information

5. Submit and verify:
   - Payment method appears in list
   - Correct brand and last 4 digits shown
   - Expiration date displayed
   - Default badge appears if first card

6. Test "Set as Default":
   - Add another card
   - Click "Set as Default" on second card
   - Verify badge moves to new card

7. Test "Delete":
   - Click "Delete" on a card
   - Confirm deletion
   - Verify card removed from list

## Security Considerations

### What's Secure:

1. **No card data touches your server**: Stripe Elements handles all card input directly
2. **Tokenization**: Cards are converted to tokens before API calls
3. **PCI Compliance**: Using Stripe Elements keeps you PCI-compliant
4. **Server-side validation**: API routes verify user authentication
5. **RLS policies**: Supabase Row Level Security protects payment_methods table

### Important Notes:

- Never log or store full card numbers
- Always use `STRIPE_SECRET_KEY` only on server-side
- Never expose secret key in client-side code
- Payment method IDs (pm_xxx) are safe to store and log
- Customer IDs (cus_xxx) are safe to store and log

## Production Deployment

### Before Going Live:

1. **Switch to Live Mode Keys**:
   - Get live keys from Stripe Dashboard (Live mode)
   - Update `.env.local` with live keys
   - Never commit keys to git

2. **Update Stripe Customer Portal** (optional):
   - Configure customer portal in Stripe Dashboard
   - Add business information
   - Set branding/colors

3. **Test with Real Cards**:
   - Use small test amounts ($0.50)
   - Test with different card types (Visa, Mastercard, Amex)
   - Test declined cards
   - Test international cards if applicable

4. **Monitor Stripe Dashboard**:
   - Watch for failed payments
   - Set up email alerts
   - Review customer disputes

## Troubleshooting

### "Stripe has not loaded yet"
- Check `NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY` is set
- Check browser console for Stripe errors
- Verify internet connection

### "Payment method not found"
- Verify user is authenticated
- Check payment method belongs to current user
- Check database RLS policies allow access

### "Failed to attach payment method"
- Verify `STRIPE_SECRET_KEY` is correct
- Check Stripe Dashboard for errors
- Ensure test mode keys match (both test or both live)

### API Returns 401 Unauthorized
- User session expired, redirect to login
- Check Supabase auth is working

## Future Enhancements

Potential improvements:

1. **Payment Intent Creation**: Move from saving cards to creating payment intents for jobs
2. **Stripe Checkout**: Alternative checkout flow for one-time payments
3. **Multiple Payment Types**: Support for ACH, Apple Pay, Google Pay
4. **Billing History**: Show past charges
5. **Receipts**: Email receipts after job completion
6. **Refunds**: Admin interface for processing refunds

## Related Documentation

- [Stripe Elements Documentation](https://stripe.com/docs/stripe-js)
- [Stripe Payment Methods API](https://stripe.com/docs/api/payment_methods)
- [Stripe Test Cards](https://stripe.com/docs/testing)
- [Supabase Auth](https://supabase.com/docs/guides/auth)

## Support

For issues or questions:
1. Check Stripe Dashboard logs
2. Check browser console errors
3. Check server logs
4. Review Supabase auth logs
