// Booking and Review types for B2B SaaS model

export type BookingStatus = "pending" | "accepted" | "in_progress" | "completed" | "cancelled"

export type VehicleType = "sedan" | "suv" | "truck" | "van" | "sports" | "other"

export interface Vehicle {
  id: string
  customer_id: string
  make: string
  model: string
  year: number
  color?: string
  license_plate?: string
  vin?: string
  vehicle_type: VehicleType
  created_at: string
}

export interface Booking {
  id: string
  customer_id: string
  technician_id?: string // For solo mechanic bookings
  vehicle_id: string
  status: BookingStatus
  service_type: string
  scheduled_date: string
  completed_date?: string
  service_address: string
  service_city: string
  service_state: string
  service_zip: string
  service_latitude?: number
  service_longitude?: number
  estimated_price: number
  final_price?: number
  notes?: string
  created_at: string
  updated_at: string

  // B2B additions
  shop_id?: string // If booked through a shop
  shop_technician_id?: string // Which shop employee is assigned
  service_package_id?: string // Which service package was selected
  transaction_fee?: number // Platform fee (5% or 8% based on subscription)
  shop_payout?: number // Amount paid to shop after fee
}

export type ReviewType = "shop" | "solo_mechanic"

export interface Review {
  id: string
  booking_id: string
  customer_id: string
  technician_id?: string // For solo mechanic reviews
  rating: number // 1-5 overall rating
  comment?: string
  created_at: string

  // B2B additions
  shop_id?: string // For shop reviews
  shop_technician_id?: string // Which shop employee performed the service
  review_type?: ReviewType // Auto-generated: 'shop' or 'solo_mechanic'

  // Detailed ratings (optional)
  service_quality_rating?: number // 1-5
  communication_rating?: number // 1-5
  value_rating?: number // 1-5
  would_recommend?: boolean
}

// Review summary types (from database views)
export interface ShopReviewsSummary {
  shop_id: string
  shop_name: string
  total_reviews: number
  avg_overall_rating: number
  avg_service_quality: number
  avg_communication: number
  avg_value: number
  recommend_count: number
  recommend_percentage: number
}

export interface SoloMechanicReviewsSummary {
  technician_id: string
  technician_name: string
  total_reviews: number
  avg_overall_rating: number
  avg_service_quality: number
  avg_communication: number
  avg_value: number
  recommend_count: number
  recommend_percentage: number
}

// Helper functions
export function isShopBooking(booking: Booking): boolean {
  return booking.shop_id !== null && booking.shop_id !== undefined
}

export function isSoloMechanicBooking(booking: Booking): boolean {
  return booking.technician_id !== null && booking.technician_id !== undefined && !booking.shop_id
}

export function calculateShopPayout(booking: Booking, transactionFeePercent: number): number {
  const price = booking.final_price || booking.estimated_price
  const fee = price * (transactionFeePercent / 100)
  return price - fee
}

export function isBookingCompleted(booking: Booking): boolean {
  return booking.status === "completed"
}

export function canReview(booking: Booking): boolean {
  return booking.status === "completed" && !booking.completed_date
}
