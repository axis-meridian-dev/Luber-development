-- Create enum types for user roles and booking status
CREATE TYPE user_role AS ENUM ('customer', 'technician', 'admin');
CREATE TYPE booking_status AS ENUM ('pending', 'accepted', 'in_progress', 'completed', 'cancelled');
CREATE TYPE vehicle_type AS ENUM ('sedan', 'suv', 'truck', 'van', 'sports', 'other');

-- Profiles table (extends auth.users)
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL,
  full_name TEXT NOT NULL,
  phone TEXT,
  role user_role NOT NULL DEFAULT 'customer',
  avatar_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Customer profiles (additional customer-specific data)
CREATE TABLE IF NOT EXISTS public.customers (
  id UUID PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
  address TEXT,
  city TEXT,
  state TEXT,
  zip_code TEXT,
  preferred_payment_method TEXT
);

-- Technician profiles (additional technician-specific data)
CREATE TABLE IF NOT EXISTS public.technicians (
  id UUID PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
  license_number TEXT,
  years_experience INTEGER,
  rating DECIMAL(3,2) DEFAULT 0.00,
  total_jobs INTEGER DEFAULT 0,
  is_available BOOLEAN DEFAULT true,
  current_latitude DECIMAL(10,8),
  current_longitude DECIMAL(11,8),
  service_radius_miles INTEGER DEFAULT 10,
  bio TEXT,
  certifications TEXT[]
);

-- Vehicles table
CREATE TABLE IF NOT EXISTS public.vehicles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id UUID NOT NULL REFERENCES public.customers(id) ON DELETE CASCADE,
  make TEXT NOT NULL,
  model TEXT NOT NULL,
  year INTEGER NOT NULL,
  color TEXT,
  license_plate TEXT,
  vin TEXT,
  vehicle_type vehicle_type NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Bookings table
CREATE TABLE IF NOT EXISTS public.bookings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id UUID NOT NULL REFERENCES public.customers(id) ON DELETE CASCADE,
  technician_id UUID REFERENCES public.technicians(id) ON DELETE SET NULL,
  vehicle_id UUID NOT NULL REFERENCES public.vehicles(id) ON DELETE CASCADE,
  status booking_status NOT NULL DEFAULT 'pending',
  service_type TEXT NOT NULL,
  scheduled_date TIMESTAMPTZ NOT NULL,
  completed_date TIMESTAMPTZ,
  service_address TEXT NOT NULL,
  service_city TEXT NOT NULL,
  service_state TEXT NOT NULL,
  service_zip TEXT NOT NULL,
  service_latitude DECIMAL(10,8),
  service_longitude DECIMAL(11,8),
  estimated_price DECIMAL(10,2),
  final_price DECIMAL(10,2),
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Reviews table
CREATE TABLE IF NOT EXISTS public.reviews (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  booking_id UUID NOT NULL REFERENCES public.bookings(id) ON DELETE CASCADE,
  customer_id UUID NOT NULL REFERENCES public.customers(id) ON DELETE CASCADE,
  technician_id UUID NOT NULL REFERENCES public.technicians(id) ON DELETE CASCADE,
  rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
  comment TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable Row Level Security on all tables
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.technicians ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.vehicles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bookings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reviews ENABLE ROW LEVEL SECURITY;

-- RLS Policies for profiles
CREATE POLICY "Users can view their own profile" ON public.profiles
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update their own profile" ON public.profiles
  FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert their own profile" ON public.profiles
  FOR INSERT WITH CHECK (auth.uid() = id);

-- RLS Policies for customers
CREATE POLICY "Customers can view their own data" ON public.customers
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Customers can update their own data" ON public.customers
  FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Customers can insert their own data" ON public.customers
  FOR INSERT WITH CHECK (auth.uid() = id);

-- RLS Policies for technicians
CREATE POLICY "Technicians can view their own data" ON public.technicians
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Technicians can update their own data" ON public.technicians
  FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Technicians can insert their own data" ON public.technicians
  FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "Anyone can view available technicians" ON public.technicians
  FOR SELECT USING (is_available = true);

-- RLS Policies for vehicles
CREATE POLICY "Customers can view their own vehicles" ON public.vehicles
  FOR SELECT USING (auth.uid() = customer_id);

CREATE POLICY "Customers can insert their own vehicles" ON public.vehicles
  FOR INSERT WITH CHECK (auth.uid() = customer_id);

CREATE POLICY "Customers can update their own vehicles" ON public.vehicles
  FOR UPDATE USING (auth.uid() = customer_id);

CREATE POLICY "Customers can delete their own vehicles" ON public.vehicles
  FOR DELETE USING (auth.uid() = customer_id);

-- RLS Policies for bookings
CREATE POLICY "Customers can view their own bookings" ON public.bookings
  FOR SELECT USING (auth.uid() = customer_id);

CREATE POLICY "Technicians can view their assigned bookings" ON public.bookings
  FOR SELECT USING (auth.uid() = technician_id);

CREATE POLICY "Customers can create bookings" ON public.bookings
  FOR INSERT WITH CHECK (auth.uid() = customer_id);

CREATE POLICY "Customers can update their own bookings" ON public.bookings
  FOR UPDATE USING (auth.uid() = customer_id);

CREATE POLICY "Technicians can update their assigned bookings" ON public.bookings
  FOR UPDATE USING (auth.uid() = technician_id);

-- RLS Policies for reviews
CREATE POLICY "Anyone can view reviews" ON public.reviews
  FOR SELECT USING (true);

CREATE POLICY "Customers can create reviews for their bookings" ON public.reviews
  FOR INSERT WITH CHECK (auth.uid() = customer_id);

-- Create indexes for better performance
CREATE INDEX idx_bookings_customer ON public.bookings(customer_id);
CREATE INDEX idx_bookings_technician ON public.bookings(technician_id);
CREATE INDEX idx_bookings_status ON public.bookings(status);
CREATE INDEX idx_bookings_scheduled_date ON public.bookings(scheduled_date);
CREATE INDEX idx_vehicles_customer ON public.vehicles(customer_id);
CREATE INDEX idx_reviews_technician ON public.reviews(technician_id);
CREATE INDEX idx_reviews_booking ON public.reviews(booking_id);
