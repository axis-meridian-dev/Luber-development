-- Add Stripe customer ID to profiles table
ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS stripe_customer_id TEXT;

-- Add expiration date fields to payment_methods table
ALTER TABLE public.payment_methods
ADD COLUMN IF NOT EXISTS exp_month INTEGER,
ADD COLUMN IF NOT EXISTS exp_year INTEGER;

-- Add index for faster lookups of default payment methods
CREATE INDEX IF NOT EXISTS idx_payment_methods_user_default ON public.payment_methods(user_id, is_default);

-- Add index for Stripe customer ID lookups
CREATE INDEX IF NOT EXISTS idx_profiles_stripe_customer_id ON public.profiles(stripe_customer_id);
