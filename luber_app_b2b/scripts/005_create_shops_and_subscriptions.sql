-- Create shops table for B2B SaaS model
CREATE TABLE IF NOT EXISTS public.shops (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  
  -- Shop Information
  shop_name TEXT NOT NULL,
  business_legal_name TEXT NOT NULL,
  business_license_number TEXT NOT NULL,
  insurance_policy_number TEXT NOT NULL,
  insurance_expiry_date DATE NOT NULL,
  tax_id TEXT,
  
  -- Contact Information
  owner_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  business_email TEXT NOT NULL,
  business_phone TEXT NOT NULL,
  business_address TEXT NOT NULL,
  business_city TEXT NOT NULL,
  business_state TEXT NOT NULL,
  business_zip TEXT NOT NULL,
  
  -- Subscription Information
  subscription_tier TEXT NOT NULL CHECK (subscription_tier IN ('solo', 'business')),
  stripe_customer_id TEXT UNIQUE,
  stripe_subscription_id TEXT UNIQUE,
  subscription_status TEXT DEFAULT 'trialing' CHECK (subscription_status IN ('active', 'trialing', 'past_due', 'canceled', 'incomplete')),
  trial_ends_at TIMESTAMPTZ,
  current_period_end TIMESTAMPTZ,
  
  -- White-labeling & Branding
  logo_url TEXT,
  primary_color TEXT DEFAULT '#2563eb',
  secondary_color TEXT DEFAULT '#f97316',
  custom_domain TEXT,
  
  -- Business Settings
  service_radius_miles INTEGER DEFAULT 25,
  is_active BOOLEAN DEFAULT true,
  onboarding_completed BOOLEAN DEFAULT false,
  
  -- Metadata
  total_technicians INTEGER DEFAULT 0,
  total_bookings INTEGER DEFAULT 0,
  total_revenue DECIMAL(10, 2) DEFAULT 0
);

-- Create shop_technicians junction table (replaces standalone technicians)
CREATE TABLE IF NOT EXISTS public.shop_technicians (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  
  shop_id UUID REFERENCES public.shops(id) ON DELETE CASCADE,
  profile_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  
  -- Technician Details
  license_number TEXT NOT NULL,
  certifications TEXT[],
  years_experience INTEGER DEFAULT 0,
  bio TEXT,
  
  -- Status
  is_available BOOLEAN DEFAULT true,
  current_latitude DECIMAL(10, 8),
  current_longitude DECIMAL(11, 8),
  
  -- Performance Metrics
  rating DECIMAL(3, 2) DEFAULT 5.0,
  total_jobs INTEGER DEFAULT 0,
  
  UNIQUE(shop_id, profile_id)
);

-- Create shop_service_packages table (custom pricing per shop)
CREATE TABLE IF NOT EXISTS public.shop_service_packages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  
  shop_id UUID REFERENCES public.shops(id) ON DELETE CASCADE,
  
  -- Package Details
  package_name TEXT NOT NULL,
  description TEXT,
  price DECIMAL(10, 2) NOT NULL,
  estimated_duration_minutes INTEGER NOT NULL,
  
  -- Service Details
  oil_brand TEXT,
  oil_type TEXT, -- synthetic, semi-synthetic, conventional
  includes_filter BOOLEAN DEFAULT true,
  includes_inspection BOOLEAN DEFAULT false,
  
  -- Availability
  is_active BOOLEAN DEFAULT true,
  
  UNIQUE(shop_id, package_name)
);

-- Create shop_subscription_history table
CREATE TABLE IF NOT EXISTS public.shop_subscription_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at TIMESTAMPTZ DEFAULT now(),
  
  shop_id UUID REFERENCES public.shops(id) ON DELETE CASCADE,
  
  -- Event Details
  event_type TEXT NOT NULL, -- subscription_created, subscription_updated, payment_succeeded, payment_failed, etc.
  stripe_event_id TEXT,
  
  -- Subscription Details at Time of Event
  subscription_tier TEXT,
  amount_paid DECIMAL(10, 2),
  technician_count INTEGER,
  
  -- Metadata
  metadata JSONB
);

-- Update bookings table to reference shops
ALTER TABLE public.bookings 
  ADD COLUMN IF NOT EXISTS shop_id UUID REFERENCES public.shops(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS shop_technician_id UUID REFERENCES public.shop_technicians(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS service_package_id UUID REFERENCES public.shop_service_packages(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS transaction_fee DECIMAL(10, 2),
  ADD COLUMN IF NOT EXISTS shop_payout DECIMAL(10, 2);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_shops_owner_id ON public.shops(owner_id);
CREATE INDEX IF NOT EXISTS idx_shops_subscription_status ON public.shops(subscription_status);
CREATE INDEX IF NOT EXISTS idx_shops_stripe_customer_id ON public.shops(stripe_customer_id);
CREATE INDEX IF NOT EXISTS idx_shop_technicians_shop_id ON public.shop_technicians(shop_id);
CREATE INDEX IF NOT EXISTS idx_shop_technicians_profile_id ON public.shop_technicians(profile_id);
CREATE INDEX IF NOT EXISTS idx_shop_service_packages_shop_id ON public.shop_service_packages(shop_id);
CREATE INDEX IF NOT EXISTS idx_bookings_shop_id ON public.bookings(shop_id);

-- Enable Row Level Security
ALTER TABLE public.shops ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.shop_technicians ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.shop_service_packages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.shop_subscription_history ENABLE ROW LEVEL SECURITY;

-- RLS Policies for shops
CREATE POLICY "Shop owners can view their own shop"
  ON public.shops FOR SELECT
  USING (auth.uid() = owner_id);

CREATE POLICY "Shop owners can update their own shop"
  ON public.shops FOR UPDATE
  USING (auth.uid() = owner_id);

CREATE POLICY "Anyone can create a shop"
  ON public.shops FOR INSERT
  WITH CHECK (auth.uid() = owner_id);

CREATE POLICY "Customers can view active shops"
  ON public.shops FOR SELECT
  USING (is_active = true AND subscription_status = 'active');

-- RLS Policies for shop_technicians
CREATE POLICY "Shop owners can manage their technicians"
  ON public.shop_technicians FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.shops
      WHERE shops.id = shop_technicians.shop_id
      AND shops.owner_id = auth.uid()
    )
  );

CREATE POLICY "Technicians can view their own data"
  ON public.shop_technicians FOR SELECT
  USING (auth.uid() = profile_id);

CREATE POLICY "Technicians can update their own availability"
  ON public.shop_technicians FOR UPDATE
  USING (auth.uid() = profile_id);

CREATE POLICY "Customers can view available technicians"
  ON public.shop_technicians FOR SELECT
  USING (
    is_available = true 
    AND EXISTS (
      SELECT 1 FROM public.shops
      WHERE shops.id = shop_technicians.shop_id
      AND shops.is_active = true
      AND shops.subscription_status = 'active'
    )
  );

-- RLS Policies for shop_service_packages
CREATE POLICY "Shop owners can manage their packages"
  ON public.shop_service_packages FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.shops
      WHERE shops.id = shop_service_packages.shop_id
      AND shops.owner_id = auth.uid()
    )
  );

CREATE POLICY "Customers can view active packages"
  ON public.shop_service_packages FOR SELECT
  USING (
    is_active = true
    AND EXISTS (
      SELECT 1 FROM public.shops
      WHERE shops.id = shop_service_packages.shop_id
      AND shops.is_active = true
      AND shops.subscription_status = 'active'
    )
  );

-- RLS Policies for shop_subscription_history
CREATE POLICY "Shop owners can view their subscription history"
  ON public.shop_subscription_history FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.shops
      WHERE shops.id = shop_subscription_history.shop_id
      AND shops.owner_id = auth.uid()
    )
  );

-- Create triggers for updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_shops_updated_at
  BEFORE UPDATE ON public.shops
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_shop_technicians_updated_at
  BEFORE UPDATE ON public.shop_technicians
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_shop_service_packages_updated_at
  BEFORE UPDATE ON public.shop_service_packages
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Create function to update shop metrics
CREATE OR REPLACE FUNCTION update_shop_metrics()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' OR TG_OP = 'UPDATE' THEN
    UPDATE public.shops
    SET 
      total_technicians = (
        SELECT COUNT(*) FROM public.shop_technicians
        WHERE shop_id = NEW.shop_id
      ),
      total_bookings = (
        SELECT COUNT(*) FROM public.bookings
        WHERE shop_id = NEW.shop_id
      ),
      total_revenue = (
        SELECT COALESCE(SUM(shop_payout), 0) FROM public.bookings
        WHERE shop_id = NEW.shop_id AND status = 'completed'
      )
    WHERE id = NEW.shop_id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_shop_metrics_on_technician_change
  AFTER INSERT OR UPDATE OR DELETE ON public.shop_technicians
  FOR EACH ROW
  EXECUTE FUNCTION update_shop_metrics();

CREATE TRIGGER update_shop_metrics_on_booking_change
  AFTER INSERT OR UPDATE OR DELETE ON public.bookings
  FOR EACH ROW
  EXECUTE FUNCTION update_shop_metrics();
