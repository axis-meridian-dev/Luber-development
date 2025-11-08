export type UserRole = "customer" | "technician" | "admin"
export type JobStatus = "pending" | "accepted" | "in_progress" | "completed" | "cancelled"
export type VehicleType = "sedan" | "suv" | "truck" | "sports_car" | "hybrid" | "electric"
export type OilType = "conventional" | "synthetic_blend" | "full_synthetic" | "high_mileage"
export type ApplicationStatus = "pending" | "approved" | "rejected"

export interface Profile {
  id: string
  role: UserRole
  full_name: string
  phone?: string
  profile_photo_url?: string
  created_at: string
  updated_at: string
}

export interface TechnicianProfile {
  id: string
  certification_photo_url?: string
  drivers_license_url?: string
  bio?: string
  years_experience?: number
  average_rating: number
  total_jobs_completed: number
  is_available: boolean
  stripe_account_id?: string
  application_status: ApplicationStatus
  applied_at: string
  approved_at?: string
  rejected_at?: string
  rejection_reason?: string
  created_at: string
  updated_at: string
}

export interface Address {
  id: string
  user_id: string
  label: string
  street_address: string
  city: string
  state: string
  zip_code: string
  latitude?: number
  longitude?: number
  is_default: boolean
  created_at: string
  updated_at: string
}

export interface Vehicle {
  id: string
  user_id: string
  make: string
  model: string
  year: number
  vehicle_type: VehicleType
  oil_capacity?: number
  recommended_oil_type: OilType
  license_plate?: string
  vin?: string
  is_default: boolean
  created_at: string
  updated_at: string
}

export interface Job {
  id: string
  customer_id: string
  technician_id?: string
  vehicle_id: string
  address_id: string
  status: JobStatus
  oil_type: OilType
  price_cents: number
  platform_fee_cents: number
  technician_earnings_cents: number
  scheduled_time: string
  accepted_at?: string
  started_at?: string
  completed_at?: string
  cancelled_at?: string
  cancellation_reason?: string
  special_instructions?: string
  stripe_payment_intent_id?: string
  stripe_transfer_id?: string
  created_at: string
  updated_at: string
}

export interface JobPhoto {
  id: string
  job_id: string
  photo_url: string
  photo_type: "before" | "after" | "additional"
  uploaded_at: string
}

export interface Review {
  id: string
  job_id: string
  customer_id: string
  technician_id: string
  rating: number
  comment?: string
  created_at: string
  updated_at: string
}

export interface TechnicianLocation {
  id: string
  technician_id: string
  latitude: number
  longitude: number
  heading?: number
  speed?: number
  updated_at: string
}

export interface PaymentMethod {
  id: string
  user_id: string
  stripe_payment_method_id: string
  card_brand?: string
  card_last4?: string
  is_default: boolean
  created_at: string
}

export interface Notification {
  id: string
  user_id: string
  title: string
  body: string
  type: string
  data?: Record<string, any>
  read: boolean
  created_at: string
}
