-- Insert admin user (update with your actual admin user ID after first signup)
-- This is a placeholder - you'll need to sign up as admin first, then update this

-- Seed some test data for development
-- Insert test vehicles data for reference
INSERT INTO public.vehicles (user_id, make, model, year, vehicle_type, oil_capacity, recommended_oil_type, license_plate)
VALUES 
  -- These will need actual user IDs from your auth.users table
  -- ('USER_ID_HERE', 'Toyota', 'Camry', 2020, 'sedan', 4.5, 'synthetic_blend', 'ABC123'),
  -- ('USER_ID_HERE', 'Ford', 'F-150', 2021, 'truck', 6.0, 'full_synthetic', 'XYZ789')
ON CONFLICT DO NOTHING;

-- Note: Additional seed data should be added after users are created through the auth flow
