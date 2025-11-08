// Central export for all Luber type definitions

// User and authentication types
export type {
  UserRole,
  Profile,
  Customer,
  Technician,
  ShopOwnerMetadata,
  ShopMechanicMetadata,
  SoloMechanicMetadata,
} from "./user"

export {
  isShopOwner,
  isShopMechanic,
  isSoloMechanic,
  isCustomer,
  isAdmin,
  canManageShop,
  canPerformService,
} from "./user"

// Shop types
export type { Shop, ShopTechnician, ShopServicePackage } from "./shop"

// Booking and review types
export type {
  BookingStatus,
  VehicleType,
  Vehicle,
  Booking,
  ReviewType,
  Review,
  ShopReviewsSummary,
  SoloMechanicReviewsSummary,
} from "./booking"

export {
  isShopBooking,
  isSoloMechanicBooking,
  calculateShopPayout,
  isBookingCompleted,
  canReview,
} from "./booking"
