# Quick Start: Stripe Payment Methods

## TL;DR - Get Running in 5 Minutes

### Step 1: Install Dependencies
```bash
cd /home/axmh/Development/Luber-development/luber_consumer
npm install --legacy-peer-deps
```

### Step 2: Run Database Migration
```sql
-- In Supabase SQL Editor, run:
/home/axmh/Development/Luber-development/luber_consumer/scripts/006_add_payment_method_fields.sql
```

### Step 3: Add Stripe Keys to .env.local
```bash
# Get keys from: https://dashboard.stripe.com/test/apikeys
STRIPE_SECRET_KEY=sk_test_51...
NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY=pk_test_51...
```

### Step 4: Start Server
```bash
npm run dev
```

### Step 5: Test It
1. Go to http://localhost:3000/customer/payment-methods
2. Click "Add Card"
3. Enter test card: `4242 4242 4242 4242`
4. Expiry: `12/25`, CVC: `123`, ZIP: `12345`
5. Click "Add Payment Method"

Done! You should see the card in your list.

## What You Can Do Now

- **Add Cards**: `/customer/payment-methods/new`
- **View Cards**: `/customer/payment-methods`
- **Set Default**: Click "Set as Default" on any card
- **Delete Cards**: Click "Delete" and confirm

## Test Cards

| Card              | Result            |
|-------------------|-------------------|
| 4242 4242 4242 4242 | Success          |
| 4000 0000 0000 0002 | Card Declined    |
| 4000 0000 0000 9995 | Insufficient Funds |

## Troubleshooting

**Error: "Stripe has not loaded yet"**
- Check your `NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY` is set

**Error: "Unauthorized"**
- Make sure you're logged in
- Check Supabase auth is working

**Card won't save**
- Verify `STRIPE_SECRET_KEY` is set
- Check it starts with `sk_test_`
- Make sure both keys are from test mode

## Need More Help?

- Full guide: `STRIPE_PAYMENT_SETUP.md`
- Implementation details: `IMPLEMENTATION_SUMMARY.md`
