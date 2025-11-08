-- Migration: Update user roles for B2B SaaS model
-- This migration updates the user_role enum to support the new B2B structure

-- Step 1: Add new role values to the enum
-- Note: PostgreSQL doesn't allow removing enum values easily, so we add new ones
ALTER TYPE user_role ADD VALUE IF NOT EXISTS 'shop_owner';
ALTER TYPE user_role ADD VALUE IF NOT EXISTS 'shop_mechanic';
ALTER TYPE user_role ADD VALUE IF NOT EXISTS 'solo_mechanic';

-- Step 2: Add metadata column to profiles for role-specific data
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS role_metadata JSONB DEFAULT '{}'::jsonb;

-- Step 3: Add shop_id reference to profiles for shop mechanics
-- This makes it easier to identify which shop a user belongs to
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS shop_id UUID REFERENCES public.shops(id) ON DELETE SET NULL;

-- Step 4: Create index for shop_id lookups
CREATE INDEX IF NOT EXISTS idx_profiles_shop_id ON public.profiles(shop_id);

-- Step 5: Create a view for active shop owners
CREATE OR REPLACE VIEW public.active_shop_owners AS
SELECT
  p.*,
  s.shop_name,
  s.subscription_tier,
  s.subscription_status
FROM public.profiles p
JOIN public.shops s ON s.owner_id = p.id
WHERE p.role = 'shop_owner'
  AND s.is_active = true
  AND s.subscription_status IN ('active', 'trialing');

-- Step 6: Create a view for shop mechanics with their shop info
CREATE OR REPLACE VIEW public.shop_mechanics_with_shop AS
SELECT
  p.*,
  st.shop_id,
  st.license_number,
  st.certifications,
  st.years_experience,
  st.is_available,
  st.rating,
  st.total_jobs,
  s.shop_name,
  s.subscription_tier
FROM public.profiles p
JOIN public.shop_technicians st ON st.profile_id = p.id
JOIN public.shops s ON s.id = st.shop_id
WHERE p.role = 'shop_mechanic';

-- Step 7: Update RLS policies for new roles

-- Shop owners can view their shop's mechanics
CREATE POLICY "Shop owners can view their mechanics profiles"
  ON public.profiles FOR SELECT
  USING (
    role = 'shop_mechanic'
    AND EXISTS (
      SELECT 1 FROM public.shops
      WHERE shops.owner_id = auth.uid()
      AND shops.id = profiles.shop_id
    )
  );

-- Shop mechanics can view other mechanics in their shop
CREATE POLICY "Shop mechanics can view their coworkers"
  ON public.profiles FOR SELECT
  USING (
    role = 'shop_mechanic'
    AND shop_id = (
      SELECT shop_id FROM public.profiles
      WHERE id = auth.uid()
    )
  );

-- Customers can view active solo mechanics
CREATE POLICY "Customers can view solo mechanics"
  ON public.profiles FOR SELECT
  USING (
    role = 'solo_mechanic'
    AND EXISTS (
      SELECT 1 FROM public.technicians
      WHERE technicians.id = profiles.id
      AND technicians.is_available = true
    )
  );

-- Step 8: Create helper function to check if user can access shop
CREATE OR REPLACE FUNCTION public.user_can_access_shop(shop_uuid UUID)
RETURNS BOOLEAN AS $$
BEGIN
  -- Shop owner can access their own shop
  IF EXISTS (
    SELECT 1 FROM public.shops
    WHERE id = shop_uuid
    AND owner_id = auth.uid()
  ) THEN
    RETURN TRUE;
  END IF;

  -- Shop mechanic can access their shop
  IF EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid()
    AND role = 'shop_mechanic'
    AND shop_id = shop_uuid
  ) THEN
    RETURN TRUE;
  END IF;

  -- Admin can access any shop
  IF EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid()
    AND role = 'admin'
  ) THEN
    RETURN TRUE;
  END IF;

  RETURN FALSE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 9: Create trigger to auto-populate shop_id for shop mechanics
CREATE OR REPLACE FUNCTION public.populate_shop_mechanic_shop_id()
RETURNS TRIGGER AS $$
BEGIN
  -- When a user's role is set to shop_mechanic, auto-populate shop_id from shop_technicians
  IF NEW.role = 'shop_mechanic' AND NEW.shop_id IS NULL THEN
    SELECT shop_id INTO NEW.shop_id
    FROM public.shop_technicians
    WHERE profile_id = NEW.id
    LIMIT 1;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER auto_populate_shop_mechanic_shop_id
  BEFORE INSERT OR UPDATE ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION populate_shop_mechanic_shop_id();

-- Step 10: Create function to ensure role consistency
CREATE OR REPLACE FUNCTION public.check_role_consistency()
RETURNS TRIGGER AS $$
BEGIN
  -- Shop owners must have a shop
  IF NEW.role = 'shop_owner' THEN
    IF NOT EXISTS (
      SELECT 1 FROM public.shops
      WHERE owner_id = NEW.id
    ) THEN
      RAISE EXCEPTION 'Shop owners must have an associated shop';
    END IF;
  END IF;

  -- Shop mechanics must be in shop_technicians table
  IF NEW.role = 'shop_mechanic' THEN
    IF NOT EXISTS (
      SELECT 1 FROM public.shop_technicians
      WHERE profile_id = NEW.id
    ) THEN
      RAISE EXCEPTION 'Shop mechanics must be registered in shop_technicians table';
    END IF;
  END IF;

  -- Solo mechanics must be in technicians table
  IF NEW.role = 'solo_mechanic' THEN
    IF NOT EXISTS (
      SELECT 1 FROM public.technicians
      WHERE id = NEW.id
    ) THEN
      RAISE EXCEPTION 'Solo mechanics must be registered in technicians table';
    END IF;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Note: Uncomment this trigger only after data migration is complete
-- CREATE TRIGGER enforce_role_consistency
--   BEFORE INSERT OR UPDATE ON public.profiles
--   FOR EACH ROW
--   EXECUTE FUNCTION check_role_consistency();

-- Step 11: Add comments for documentation
COMMENT ON COLUMN public.profiles.role IS 'User role: customer, shop_owner, shop_mechanic, solo_mechanic, admin, or legacy technician';
COMMENT ON COLUMN public.profiles.shop_id IS 'For shop_mechanic role: the shop they work for. NULL for other roles.';
COMMENT ON COLUMN public.profiles.role_metadata IS 'Additional role-specific metadata stored as JSON';
COMMENT ON FUNCTION public.user_can_access_shop IS 'Helper function to check if authenticated user can access a specific shop';
