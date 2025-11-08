-- Migration: Update reviews table for B2B shop-level reviews
-- Reviews can now be for shops (if booked through a shop) or individual mechanics (if solo)

-- Step 1: Add shop_id to reviews table
ALTER TABLE public.reviews
  ADD COLUMN IF NOT EXISTS shop_id UUID REFERENCES public.shops(id) ON DELETE CASCADE;

-- Step 2: Make technician_id nullable (since reviews can be for shops, not individual techs)
ALTER TABLE public.reviews
  ALTER COLUMN technician_id DROP NOT NULL;

-- Step 3: Add constraint to ensure either shop_id or technician_id is set
ALTER TABLE public.reviews
  ADD CONSTRAINT reviews_shop_or_technician_required
  CHECK (
    (shop_id IS NOT NULL AND technician_id IS NULL) OR
    (shop_id IS NULL AND technician_id IS NOT NULL)
  );

-- Step 4: Add review type column for clarity
ALTER TABLE public.reviews
  ADD COLUMN IF NOT EXISTS review_type TEXT GENERATED ALWAYS AS (
    CASE
      WHEN shop_id IS NOT NULL THEN 'shop'
      WHEN technician_id IS NOT NULL THEN 'solo_mechanic'
      ELSE 'unknown'
    END
  ) STORED;

-- Step 5: Add helpful columns for shop reviews
ALTER TABLE public.reviews
  ADD COLUMN IF NOT EXISTS shop_technician_id UUID REFERENCES public.shop_technicians(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS service_quality_rating INTEGER CHECK (service_quality_rating >= 1 AND service_quality_rating <= 5),
  ADD COLUMN IF NOT EXISTS communication_rating INTEGER CHECK (communication_rating >= 1 AND communication_rating <= 5),
  ADD COLUMN IF NOT EXISTS value_rating INTEGER CHECK (value_rating >= 1 AND value_rating <= 5),
  ADD COLUMN IF NOT EXISTS would_recommend BOOLEAN DEFAULT true;

-- Step 6: Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_reviews_shop_id ON public.reviews(shop_id);
CREATE INDEX IF NOT EXISTS idx_reviews_shop_technician_id ON public.reviews(shop_technician_id);
CREATE INDEX IF NOT EXISTS idx_reviews_review_type ON public.reviews(review_type);

-- Step 7: Create view for shop reviews with aggregated ratings
CREATE OR REPLACE VIEW public.shop_reviews_summary AS
SELECT
  s.id AS shop_id,
  s.shop_name,
  COUNT(r.id) AS total_reviews,
  ROUND(AVG(r.rating), 2) AS avg_overall_rating,
  ROUND(AVG(r.service_quality_rating), 2) AS avg_service_quality,
  ROUND(AVG(r.communication_rating), 2) AS avg_communication,
  ROUND(AVG(r.value_rating), 2) AS avg_value,
  COUNT(CASE WHEN r.would_recommend = true THEN 1 END) AS recommend_count,
  ROUND(
    COUNT(CASE WHEN r.would_recommend = true THEN 1 END)::NUMERIC /
    NULLIF(COUNT(r.id), 0) * 100,
    1
  ) AS recommend_percentage
FROM public.shops s
LEFT JOIN public.reviews r ON r.shop_id = s.id
GROUP BY s.id, s.shop_name;

-- Step 8: Create view for solo mechanic reviews
CREATE OR REPLACE VIEW public.solo_mechanic_reviews_summary AS
SELECT
  t.id AS technician_id,
  p.full_name AS technician_name,
  COUNT(r.id) AS total_reviews,
  ROUND(AVG(r.rating), 2) AS avg_overall_rating,
  ROUND(AVG(r.service_quality_rating), 2) AS avg_service_quality,
  ROUND(AVG(r.communication_rating), 2) AS avg_communication,
  ROUND(AVG(r.value_rating), 2) AS avg_value,
  COUNT(CASE WHEN r.would_recommend = true THEN 1 END) AS recommend_count,
  ROUND(
    COUNT(CASE WHEN r.would_recommend = true THEN 1 END)::NUMERIC /
    NULLIF(COUNT(r.id), 0) * 100,
    1
  ) AS recommend_percentage
FROM public.technicians t
JOIN public.profiles p ON p.id = t.id
LEFT JOIN public.reviews r ON r.technician_id = t.id AND r.shop_id IS NULL
WHERE p.role = 'solo_mechanic'
GROUP BY t.id, p.full_name;

-- Step 9: Update RLS policies for reviews

-- Drop old policies
DROP POLICY IF EXISTS "Anyone can view reviews" ON public.reviews;
DROP POLICY IF EXISTS "Customers can create reviews for their bookings" ON public.reviews;

-- Customers can view all reviews (for shops and solo mechanics)
CREATE POLICY "Anyone can view reviews"
  ON public.reviews FOR SELECT
  USING (true);

-- Customers can create reviews for their completed bookings
CREATE POLICY "Customers can create reviews for their bookings"
  ON public.reviews FOR INSERT
  WITH CHECK (
    auth.uid() = customer_id
    AND EXISTS (
      SELECT 1 FROM public.bookings
      WHERE bookings.id = reviews.booking_id
      AND bookings.customer_id = auth.uid()
      AND bookings.status = 'completed'
    )
  );

-- Shop owners can view reviews for their shop
CREATE POLICY "Shop owners can view their shop reviews"
  ON public.reviews FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.shops
      WHERE shops.id = reviews.shop_id
      AND shops.owner_id = auth.uid()
    )
  );

-- Shop mechanics can view reviews for their shop
CREATE POLICY "Shop mechanics can view their shop reviews"
  ON public.reviews FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles p
      JOIN public.shop_technicians st ON st.profile_id = p.id
      WHERE p.id = auth.uid()
      AND p.role = 'shop_mechanic'
      AND st.shop_id = reviews.shop_id
    )
  );

-- Step 10: Create trigger to auto-populate review fields from booking
CREATE OR REPLACE FUNCTION public.populate_review_from_booking()
RETURNS TRIGGER AS $$
DECLARE
  v_booking RECORD;
BEGIN
  -- Get booking details
  SELECT * INTO v_booking
  FROM public.bookings
  WHERE id = NEW.booking_id;

  -- Auto-populate shop_id or technician_id based on booking
  IF v_booking.shop_id IS NOT NULL THEN
    -- This was a shop booking
    NEW.shop_id := v_booking.shop_id;
    NEW.shop_technician_id := v_booking.shop_technician_id;
    NEW.technician_id := NULL;
  ELSIF v_booking.technician_id IS NOT NULL THEN
    -- This was a solo mechanic booking
    NEW.technician_id := v_booking.technician_id;
    NEW.shop_id := NULL;
    NEW.shop_technician_id := NULL;
  END IF;

  -- Ensure customer_id matches
  NEW.customer_id := v_booking.customer_id;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER auto_populate_review_from_booking
  BEFORE INSERT ON public.reviews
  FOR EACH ROW
  EXECUTE FUNCTION populate_review_from_booking();

-- Step 11: Create trigger to update shop/technician ratings when reviews are added
CREATE OR REPLACE FUNCTION public.update_ratings_on_review()
RETURNS TRIGGER AS $$
BEGIN
  -- Update shop rating if this is a shop review
  IF NEW.shop_id IS NOT NULL THEN
    UPDATE public.shops
    SET updated_at = now()
    WHERE id = NEW.shop_id;

    -- Also update the specific technician's rating within the shop
    IF NEW.shop_technician_id IS NOT NULL THEN
      UPDATE public.shop_technicians
      SET
        rating = (
          SELECT ROUND(AVG(rating)::NUMERIC, 2)
          FROM public.reviews
          WHERE shop_technician_id = NEW.shop_technician_id
        ),
        updated_at = now()
      WHERE id = NEW.shop_technician_id;
    END IF;
  END IF;

  -- Update solo technician rating if this is a solo mechanic review
  IF NEW.technician_id IS NOT NULL THEN
    UPDATE public.technicians
    SET rating = (
      SELECT ROUND(AVG(rating)::NUMERIC, 2)
      FROM public.reviews
      WHERE technician_id = NEW.technician_id
      AND shop_id IS NULL
    )
    WHERE id = NEW.technician_id;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_ratings_on_review_insert
  AFTER INSERT OR UPDATE ON public.reviews
  FOR EACH ROW
  EXECUTE FUNCTION update_ratings_on_review();

-- Step 12: Add comments for documentation
COMMENT ON COLUMN public.reviews.shop_id IS 'If booking was through a shop, this is the shop being reviewed';
COMMENT ON COLUMN public.reviews.technician_id IS 'If booking was with solo mechanic, this is the mechanic being reviewed';
COMMENT ON COLUMN public.reviews.shop_technician_id IS 'For shop reviews, which specific technician performed the work';
COMMENT ON COLUMN public.reviews.review_type IS 'Auto-generated: shop or solo_mechanic';
COMMENT ON VIEW public.shop_reviews_summary IS 'Aggregated review statistics for each shop';
COMMENT ON VIEW public.solo_mechanic_reviews_summary IS 'Aggregated review statistics for solo mechanics';
