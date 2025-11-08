// User role types for B2B SaaS model

export type UserRole = "customer" | "shop_owner" | "shop_mechanic" | "solo_mechanic" | "admin" | "technician"

// Note: "technician" is legacy and will be migrated to "solo_mechanic"

export interface Profile {
  id: string
  email: string
  full_name: string
  phone?: string
  role: UserRole
  avatar_url?: string
  created_at: string
  updated_at: string

  // B2B additions
  shop_id?: string // For shop_mechanic role: which shop they work for
  role_metadata?: Record<string, unknown> // Additional role-specific data
}

export interface Customer {
  id: string
  address?: string
  city?: string
  state?: string
  zip_code?: string
  preferred_payment_method?: string
}

export interface Technician {
  id: string
  license_number?: string
  years_experience?: number
  rating: number
  total_jobs: number
  is_available: boolean
  current_latitude?: number
  current_longitude?: number
  service_radius_miles: number
  bio?: string
  certifications?: string[]
}

// Helper types for role-specific metadata
export interface ShopOwnerMetadata {
  onboarded_at?: string
  preferred_notification_method?: "email" | "sms" | "both"
  timezone?: string
}

export interface ShopMechanicMetadata {
  hire_date?: string
  employee_id?: string
  hourly_rate?: number
  weekly_hours?: number
}

export interface SoloMechanicMetadata {
  business_name?: string
  specializations?: string[]
  accepts_new_clients?: boolean
}

// Type guards
export function isShopOwner(profile: Profile): boolean {
  return profile.role === "shop_owner"
}

export function isShopMechanic(profile: Profile): boolean {
  return profile.role === "shop_mechanic"
}

export function isSoloMechanic(profile: Profile): boolean {
  return profile.role === "solo_mechanic"
}

export function isCustomer(profile: Profile): boolean {
  return profile.role === "customer"
}

export function isAdmin(profile: Profile): boolean {
  return profile.role === "admin"
}

export function canManageShop(profile: Profile): boolean {
  return profile.role === "shop_owner" || profile.role === "admin"
}

export function canPerformService(profile: Profile): boolean {
  return profile.role === "shop_mechanic" || profile.role === "solo_mechanic" || profile.role === "technician"
}
