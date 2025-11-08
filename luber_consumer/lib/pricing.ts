import type { OilType, VehicleType } from "./types/database"

// Base pricing in cents
const BASE_PRICES = {
  conventional: 3999, // $39.99
  synthetic_blend: 5999, // $59.99
  full_synthetic: 7999, // $79.99
  high_mileage: 6999, // $69.99
}

// Vehicle type multipliers
const VEHICLE_MULTIPLIERS = {
  sedan: 1.0,
  suv: 1.2,
  truck: 1.3,
  sports_car: 1.4,
  hybrid: 1.1,
  electric: 0, // No oil changes for electric vehicles
}

export function calculateJobPrice(oilType: OilType, vehicleType: VehicleType) {
  const basePrice = BASE_PRICES[oilType]
  const multiplier = VEHICLE_MULTIPLIERS[vehicleType]
  const totalPrice = Math.round(basePrice * multiplier)

  // Platform takes 20% fee
  const platformFee = Math.round(totalPrice * 0.2)
  const technicianEarnings = totalPrice - platformFee

  return {
    price_cents: totalPrice,
    platform_fee_cents: platformFee,
    technician_earnings_cents: technicianEarnings,
  }
}
