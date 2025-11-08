-- Enable RLS on all tables
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.technician_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.addresses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.vehicles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.jobs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.job_photos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.technician_locations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payment_methods ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- Profiles policies
CREATE POLICY "Users can view their own profile"
  ON public.profiles FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Users can update their own profile"
  ON public.profiles FOR UPDATE
  USING (auth.uid() = id);

CREATE POLICY "Anyone can view technician profiles"
  ON public.profiles FOR SELECT
  USING (role = 'technician');

-- Technician profiles policies
CREATE POLICY "Technicians can view their own profile"
  ON public.technician_profiles FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Technicians can update their own profile"
  ON public.technician_profiles FOR UPDATE
  USING (auth.uid() = id);

CREATE POLICY "Admins can view all technician profiles"
  ON public.technician_profiles FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

CREATE POLICY "Admins can update all technician profiles"
  ON public.technician_profiles FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Addresses policies
CREATE POLICY "Users can view their own addresses"
  ON public.addresses FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own addresses"
  ON public.addresses FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own addresses"
  ON public.addresses FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own addresses"
  ON public.addresses FOR DELETE
  USING (auth.uid() = user_id);

-- Vehicles policies
CREATE POLICY "Users can view their own vehicles"
  ON public.vehicles FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own vehicles"
  ON public.vehicles FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own vehicles"
  ON public.vehicles FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own vehicles"
  ON public.vehicles FOR DELETE
  USING (auth.uid() = user_id);

-- Jobs policies
CREATE POLICY "Customers can view their own jobs"
  ON public.jobs FOR SELECT
  USING (auth.uid() = customer_id);

CREATE POLICY "Technicians can view their assigned jobs"
  ON public.jobs FOR SELECT
  USING (auth.uid() = technician_id);

CREATE POLICY "Customers can create jobs"
  ON public.jobs FOR INSERT
  WITH CHECK (auth.uid() = customer_id);

CREATE POLICY "Customers can update their pending jobs"
  ON public.jobs FOR UPDATE
  USING (auth.uid() = customer_id AND status = 'pending');

CREATE POLICY "Technicians can update their assigned jobs"
  ON public.jobs FOR UPDATE
  USING (auth.uid() = technician_id);

CREATE POLICY "Admins can view all jobs"
  ON public.jobs FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

CREATE POLICY "Admins can update all jobs"
  ON public.jobs FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Job photos policies
CREATE POLICY "Users can view photos of their jobs"
  ON public.job_photos FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.jobs
      WHERE id = job_id AND (customer_id = auth.uid() OR technician_id = auth.uid())
    )
  );

CREATE POLICY "Technicians can upload photos to their jobs"
  ON public.job_photos FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.jobs
      WHERE id = job_id AND technician_id = auth.uid()
    )
  );

-- Reviews policies
CREATE POLICY "Anyone can view reviews"
  ON public.reviews FOR SELECT
  USING (true);

CREATE POLICY "Customers can create reviews for completed jobs"
  ON public.reviews FOR INSERT
  WITH CHECK (
    auth.uid() = customer_id AND
    EXISTS (
      SELECT 1 FROM public.jobs
      WHERE id = job_id AND status = 'completed' AND customer_id = auth.uid()
    )
  );

-- Technician locations policies
CREATE POLICY "Technicians can update their own location"
  ON public.technician_locations FOR INSERT
  WITH CHECK (auth.uid() = technician_id);

CREATE POLICY "Technicians can update their location"
  ON public.technician_locations FOR UPDATE
  USING (auth.uid() = technician_id);

CREATE POLICY "Customers can view their assigned technician's location"
  ON public.technician_locations FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.jobs
      WHERE technician_id = technician_locations.technician_id 
        AND customer_id = auth.uid() 
        AND status IN ('accepted', 'in_progress')
    )
  );

-- Payment methods policies
CREATE POLICY "Users can view their own payment methods"
  ON public.payment_methods FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own payment methods"
  ON public.payment_methods FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own payment methods"
  ON public.payment_methods FOR DELETE
  USING (auth.uid() = user_id);

-- Notifications policies
CREATE POLICY "Users can view their own notifications"
  ON public.notifications FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own notifications"
  ON public.notifications FOR UPDATE
  USING (auth.uid() = user_id);
