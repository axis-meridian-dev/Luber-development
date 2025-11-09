-- Add Stripe Connect fields to shops table
-- This migration adds support for Stripe Connect accounts for payment splitting

-- Add Connect account fields
ALTER TABLE public.shops
  ADD COLUMN IF NOT EXISTS connect_account_id TEXT UNIQUE,
  ADD COLUMN IF NOT EXISTS connect_onboarding_completed BOOLEAN DEFAULT false,
  ADD COLUMN IF NOT EXISTS connect_charges_enabled BOOLEAN DEFAULT false,
  ADD COLUMN IF NOT EXISTS connect_payouts_enabled BOOLEAN DEFAULT false,
  ADD COLUMN IF NOT EXISTS connect_details_submitted BOOLEAN DEFAULT false,
  ADD COLUMN IF NOT EXISTS connect_requirements_currently_due TEXT[] DEFAULT '{}',
  ADD COLUMN IF NOT EXISTS connect_requirements_eventually_due TEXT[] DEFAULT '{}';

-- Create index for faster Connect account lookups
CREATE INDEX IF NOT EXISTS idx_shops_connect_account_id
  ON public.shops(connect_account_id)
  WHERE connect_account_id IS NOT NULL;

-- Add comment for documentation
COMMENT ON COLUMN public.shops.connect_account_id IS 'Stripe Connect account ID for payment splitting (acct_xxx)';
COMMENT ON COLUMN public.shops.connect_onboarding_completed IS 'Whether the shop has completed Stripe Connect onboarding';
COMMENT ON COLUMN public.shops.connect_charges_enabled IS 'Whether the Connect account can accept charges';
COMMENT ON COLUMN public.shops.connect_payouts_enabled IS 'Whether the Connect account can receive payouts';
COMMENT ON COLUMN public.shops.connect_details_submitted IS 'Whether all required information has been submitted';
COMMENT ON COLUMN public.shops.connect_requirements_currently_due IS 'Array of requirements that need to be completed immediately';
COMMENT ON COLUMN public.shops.connect_requirements_eventually_due IS 'Array of requirements that will need to be completed eventually';
