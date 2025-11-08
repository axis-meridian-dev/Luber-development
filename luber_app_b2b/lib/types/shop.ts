export interface Shop {
  id: string
  created_at: string
  updated_at: string

  // Shop Information
  shop_name: string
  business_legal_name: string
  business_license_number: string
  insurance_policy_number: string
  insurance_expiry_date: string
  tax_id?: string

  // Contact Information
  owner_id: string
  business_email: string
  business_phone: string
  business_address: string
  business_city: string
  business_state: string
  business_zip: string

  // Subscription Information
  subscription_tier: "solo" | "business"
  stripe_customer_id?: string
  stripe_subscription_id?: string
  subscription_status: "active" | "trialing" | "past_due" | "canceled" | "incomplete"
  trial_ends_at?: string
  current_period_end?: string

  // White-labeling & Branding
  logo_url?: string
  primary_color: string
  secondary_color: string
  custom_domain?: string

  // Business Settings
  service_radius_miles: number
  is_active: boolean
  onboarding_completed: boolean

  // Metadata
  total_technicians: number
  total_bookings: number
  total_revenue: number
}

export interface ShopTechnician {
  id: string
  created_at: string
  updated_at: string
  shop_id: string
  profile_id: string
  license_number: string
  certifications: string[]
  years_experience: number
  bio?: string
  is_available: boolean
  current_latitude?: number
  current_longitude?: number
  rating: number
  total_jobs: number
}

export interface ShopServicePackage {
  id: string
  created_at: string
  updated_at: string
  shop_id: string
  package_name: string
  description?: string
  price: number
  estimated_duration_minutes: number
  oil_brand?: string
  oil_type?: string
  includes_filter: boolean
  includes_inspection: boolean
  is_active: boolean
}
