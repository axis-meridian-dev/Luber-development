-- Function to automatically create profile on user signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (id, email, full_name, role)
  VALUES (
    new.id,
    new.email,
    COALESCE(new.raw_user_meta_data->>'full_name', 'User'),
    COALESCE((new.raw_user_meta_data->>'role')::user_role, 'customer')
  );
  
  -- Create customer or technician record based on role
  IF COALESCE(new.raw_user_meta_data->>'role', 'customer') = 'customer' THEN
    INSERT INTO public.customers (id) VALUES (new.id);
  ELSIF COALESCE(new.raw_user_meta_data->>'role', 'customer') = 'technician' THEN
    INSERT INTO public.technicians (id) VALUES (new.id);
  END IF;
  
  RETURN new;
END;
$$;

-- Trigger to call the function on user creation
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

-- Triggers for updated_at
CREATE TRIGGER set_updated_at_profiles
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER set_updated_at_bookings
  BEFORE UPDATE ON public.bookings
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_updated_at();

-- Function to update technician rating after review
CREATE OR REPLACE FUNCTION public.update_technician_rating()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  UPDATE public.technicians
  SET rating = (
    SELECT AVG(rating)::DECIMAL(3,2)
    FROM public.reviews
    WHERE technician_id = NEW.technician_id
  )
  WHERE id = NEW.technician_id;
  
  RETURN NEW;
END;
$$;

-- Trigger to update rating after review
CREATE TRIGGER update_rating_after_review
  AFTER INSERT ON public.reviews
  FOR EACH ROW
  EXECUTE FUNCTION public.update_technician_rating();
