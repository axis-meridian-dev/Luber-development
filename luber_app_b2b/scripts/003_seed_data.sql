-- This script adds sample data for testing
-- Note: In production, you would create real users through the signup flow

-- Sample service types and pricing (you can expand this)
CREATE TABLE IF NOT EXISTS public.service_types (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  description TEXT,
  base_price DECIMAL(10,2) NOT NULL,
  estimated_duration_minutes INTEGER NOT NULL
);

INSERT INTO public.service_types (name, description, base_price, estimated_duration_minutes) VALUES
  ('Standard Oil Change', 'Conventional oil change with filter replacement', 49.99, 30),
  ('Synthetic Oil Change', 'Full synthetic oil change with premium filter', 79.99, 30),
  ('High Mileage Oil Change', 'Specialized oil for vehicles over 75k miles', 69.99, 30),
  ('Diesel Oil Change', 'Oil change for diesel engines', 89.99, 45);

-- Enable RLS for service_types
ALTER TABLE public.service_types ENABLE ROW LEVEL SECURITY;

-- Allow anyone to view service types
CREATE POLICY "Anyone can view service types" ON public.service_types
  FOR SELECT USING (true);
