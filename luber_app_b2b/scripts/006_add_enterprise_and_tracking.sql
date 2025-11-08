-- Add Enterprise tier and additional tracking features

-- Add enterprise tier to subscription_tier check
ALTER TABLE public.shops 
  DROP CONSTRAINT IF EXISTS shops_subscription_tier_check;

ALTER TABLE public.shops 
  ADD CONSTRAINT shops_subscription_tier_check 
  CHECK (subscription_tier IN ('solo', 'business', 'enterprise'));

-- Add API access fields for enterprise tier
ALTER TABLE public.shops
  ADD COLUMN IF NOT EXISTS api_key TEXT UNIQUE,
  ADD COLUMN IF NOT EXISTS api_enabled BOOLEAN DEFAULT false,
  ADD COLUMN IF NOT EXISTS webhook_url TEXT,
  ADD COLUMN IF NOT EXISTS custom_integrations JSONB DEFAULT '[]'::jsonb;

-- Create clock in/out tracking table for shop mechanics
CREATE TABLE IF NOT EXISTS public.technician_time_tracking (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at TIMESTAMPTZ DEFAULT now(),
  
  shop_technician_id UUID REFERENCES public.shop_technicians(id) ON DELETE CASCADE,
  shop_id UUID REFERENCES public.shops(id) ON DELETE CASCADE,
  
  -- Time tracking
  clock_in_time TIMESTAMPTZ NOT NULL,
  clock_out_time TIMESTAMPTZ,
  total_hours DECIMAL(5, 2),
  
  -- Location tracking
  clock_in_latitude DECIMAL(10, 8),
  clock_in_longitude DECIMAL(11, 8),
  clock_out_latitude DECIMAL(10, 8),
  clock_out_longitude DECIMAL(11, 8),
  
  -- Status
  status TEXT DEFAULT 'clocked_in' CHECK (status IN ('clocked_in', 'clocked_out', 'break')),
  notes TEXT
);

-- Create job assignments table for dispatch tracking
CREATE TABLE IF NOT EXISTS public.job_assignments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at TIMESTAMPTZ DEFAULT now(),
  
  booking_id UUID REFERENCES public.bookings(id) ON DELETE CASCADE,
  shop_id UUID REFERENCES public.shops(id) ON DELETE CASCADE,
  
  -- Assignment details
  assigned_to UUID REFERENCES public.shop_technicians(id) ON DELETE SET NULL,
  assigned_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL, -- shop owner or system
  assignment_type TEXT DEFAULT 'manual' CHECK (assignment_type IN ('manual', 'auto', 'self_accepted')),
  
  -- Status tracking
  status TEXT DEFAULT 'assigned' CHECK (status IN ('assigned', 'accepted', 'declined', 'reassigned', 'completed')),
  accepted_at TIMESTAMPTZ,
  declined_at TIMESTAMPTZ,
  decline_reason TEXT,
  completed_at TIMESTAMPTZ,
  
  -- Metadata
  estimated_arrival_time TIMESTAMPTZ,
  actual_arrival_time TIMESTAMPTZ
);

-- Create shop analytics summary table (for faster dashboard queries)
CREATE TABLE IF NOT EXISTS public.shop_analytics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  
  shop_id UUID REFERENCES public.shops(id) ON DELETE CASCADE,
  date DATE NOT NULL,
  
  -- Daily metrics
  total_bookings INTEGER DEFAULT 0,
  completed_bookings INTEGER DEFAULT 0,
  canceled_bookings INTEGER DEFAULT 0,
  total_revenue DECIMAL(10, 2) DEFAULT 0,
  platform_fees DECIMAL(10, 2) DEFAULT 0,
  net_revenue DECIMAL(10, 2) DEFAULT 0,
  
  -- Performance metrics
  average_rating DECIMAL(3, 2),
  average_completion_time_minutes INTEGER,
  active_technicians INTEGER DEFAULT 0,
  total_labor_hours DECIMAL(10, 2) DEFAULT 0,
  
  -- Customer metrics
  new_customers INTEGER DEFAULT 0,
  returning_customers INTEGER DEFAULT 0,
  
  UNIQUE(shop_id, date)
);

-- Update profiles table to add user_type
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS user_type TEXT DEFAULT 'customer' 
    CHECK (user_type IN ('customer', 'solo_mechanic', 'shop_owner', 'shop_mechanic')),
  ADD COLUMN IF NOT EXISTS shop_id UUID REFERENCES public.shops(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS stripe_connect_id TEXT;

-- Create marketplace visibility table (for shops that want to appear in Luber marketplace)
CREATE TABLE IF NOT EXISTS public.shop_marketplace_settings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  
  shop_id UUID REFERENCES public.shops(id) ON DELETE CASCADE UNIQUE,
  
  -- Marketplace visibility
  is_visible_in_marketplace BOOLEAN DEFAULT true,
  accepts_new_customers BOOLEAN DEFAULT true,
  
  -- Marketing
  featured_image_url TEXT,
  description TEXT,
  specialties TEXT[],
  
  -- Availability
  service_areas TEXT[], -- array of zip codes or city names
  minimum_booking_notice_hours INTEGER DEFAULT 2,
  maximum_advance_booking_days INTEGER DEFAULT 30
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_technician_time_tracking_shop_technician ON public.technician_time_tracking(shop_technician_id);
CREATE INDEX IF NOT EXISTS idx_technician_time_tracking_shop ON public.technician_time_tracking(shop_id);
CREATE INDEX IF NOT EXISTS idx_technician_time_tracking_date ON public.technician_time_tracking(clock_in_time);
CREATE INDEX IF NOT EXISTS idx_job_assignments_booking ON public.job_assignments(booking_id);
CREATE INDEX IF NOT EXISTS idx_job_assignments_shop ON public.job_assignments(shop_id);
CREATE INDEX IF NOT EXISTS idx_job_assignments_technician ON public.job_assignments(assigned_to);
CREATE INDEX IF NOT EXISTS idx_shop_analytics_shop_date ON public.shop_analytics(shop_id, date);
CREATE INDEX IF NOT EXISTS idx_profiles_user_type ON public.profiles(user_type);
CREATE INDEX IF NOT EXISTS idx_profiles_shop_id ON public.profiles(shop_id);

-- Enable RLS
ALTER TABLE public.technician_time_tracking ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.job_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.shop_analytics ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.shop_marketplace_settings ENABLE ROW LEVEL SECURITY;

-- RLS Policies for technician_time_tracking
CREATE POLICY "Shop owners can view their technicians' time"
  ON public.technician_time_tracking FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.shops
      WHERE shops.id = technician_time_tracking.shop_id
      AND shops.owner_id = auth.uid()
    )
  );

CREATE POLICY "Technicians can manage their own time"
  ON public.technician_time_tracking FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.shop_technicians
      WHERE shop_technicians.id = technician_time_tracking.shop_technician_id
      AND shop_technicians.profile_id = auth.uid()
    )
  );

-- RLS Policies for job_assignments
CREATE POLICY "Shop owners can manage job assignments"
  ON public.job_assignments FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.shops
      WHERE shops.id = job_assignments.shop_id
      AND shops.owner_id = auth.uid()
    )
  );

CREATE POLICY "Technicians can view their assignments"
  ON public.job_assignments FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.shop_technicians
      WHERE shop_technicians.id = job_assignments.assigned_to
      AND shop_technicians.profile_id = auth.uid()
    )
  );

CREATE POLICY "Technicians can update assignment status"
  ON public.job_assignments FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM public.shop_technicians
      WHERE shop_technicians.id = job_assignments.assigned_to
      AND shop_technicians.profile_id = auth.uid()
    )
  );

-- RLS Policies for shop_analytics
CREATE POLICY "Shop owners can view their analytics"
  ON public.shop_analytics FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.shops
      WHERE shops.id = shop_analytics.shop_id
      AND shops.owner_id = auth.uid()
    )
  );

-- RLS Policies for shop_marketplace_settings
CREATE POLICY "Shop owners can manage marketplace settings"
  ON public.shop_marketplace_settings FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.shops
      WHERE shops.id = shop_marketplace_settings.shop_id
      AND shops.owner_id = auth.uid()
    )
  );

CREATE POLICY "Customers can view marketplace shops"
  ON public.shop_marketplace_settings FOR SELECT
  USING (is_visible_in_marketplace = true AND accepts_new_customers = true);

-- Create function to calculate total hours on clock out
CREATE OR REPLACE FUNCTION calculate_time_tracking_hours()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.clock_out_time IS NOT NULL AND NEW.clock_in_time IS NOT NULL THEN
    NEW.total_hours = EXTRACT(EPOCH FROM (NEW.clock_out_time - NEW.clock_in_time)) / 3600;
    NEW.status = 'clocked_out';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER calculate_hours_on_clock_out
  BEFORE UPDATE ON public.technician_time_tracking
  FOR EACH ROW
  WHEN (NEW.clock_out_time IS NOT NULL AND OLD.clock_out_time IS NULL)
  EXECUTE FUNCTION calculate_time_tracking_hours();

-- Create function to update daily analytics
CREATE OR REPLACE FUNCTION update_daily_shop_analytics()
RETURNS TRIGGER AS $$
DECLARE
  booking_date DATE;
  shop_uuid UUID;
BEGIN
  -- Get the booking date and shop_id
  IF TG_OP = 'INSERT' OR TG_OP = 'UPDATE' THEN
    booking_date = DATE(NEW.created_at);
    shop_uuid = NEW.shop_id;
  ELSE
    booking_date = DATE(OLD.created_at);
    shop_uuid = OLD.shop_id;
  END IF;

  -- Only process if shop_id exists
  IF shop_uuid IS NOT NULL THEN
    -- Insert or update analytics record
    INSERT INTO public.shop_analytics (shop_id, date, total_bookings, completed_bookings, canceled_bookings, total_revenue, net_revenue)
    VALUES (
      shop_uuid,
      booking_date,
      (SELECT COUNT(*) FROM public.bookings WHERE shop_id = shop_uuid AND DATE(created_at) = booking_date),
      (SELECT COUNT(*) FROM public.bookings WHERE shop_id = shop_uuid AND DATE(created_at) = booking_date AND status = 'completed'),
      (SELECT COUNT(*) FROM public.bookings WHERE shop_id = shop_uuid AND DATE(created_at) = booking_date AND status = 'canceled'),
      (SELECT COALESCE(SUM(total_price), 0) FROM public.bookings WHERE shop_id = shop_uuid AND DATE(created_at) = booking_date AND status = 'completed'),
      (SELECT COALESCE(SUM(shop_payout), 0) FROM public.bookings WHERE shop_id = shop_uuid AND DATE(created_at) = booking_date AND status = 'completed')
    )
    ON CONFLICT (shop_id, date) 
    DO UPDATE SET
      total_bookings = EXCLUDED.total_bookings,
      completed_bookings = EXCLUDED.completed_bookings,
      canceled_bookings = EXCLUDED.canceled_bookings,
      total_revenue = EXCLUDED.total_revenue,
      net_revenue = EXCLUDED.net_revenue,
      updated_at = now();
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_analytics_on_booking_change
  AFTER INSERT OR UPDATE OR DELETE ON public.bookings
  FOR EACH ROW
  EXECUTE FUNCTION update_daily_shop_analytics();

-- Create function to handle solo mechanic to shop upgrade
CREATE OR REPLACE FUNCTION upgrade_solo_to_shop(
  solo_shop_id UUID,
  new_business_name TEXT,
  new_subscription_tier TEXT
)
RETURNS JSONB AS $$
DECLARE
  result JSONB;
BEGIN
  -- Update the shop record
  UPDATE public.shops
  SET 
    subscription_tier = new_subscription_tier,
    shop_name = new_business_name,
    business_legal_name = new_business_name,
    updated_at = now()
  WHERE id = solo_shop_id
  AND subscription_tier = 'solo';

  -- Return success
  result = jsonb_build_object(
    'success', true,
    'message', 'Successfully upgraded from solo to shop tier',
    'shop_id', solo_shop_id
  );

  RETURN result;
EXCEPTION
  WHEN OTHERS THEN
    result = jsonb_build_object(
      'success', false,
      'message', SQLERRM
    );
    RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
