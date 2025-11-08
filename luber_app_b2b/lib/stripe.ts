import "server-only"

import Stripe from "stripe"

export const stripe = new Stripe(process.env.STRIPE_SECRET_KEY!)

// Subscription plans for B2B SaaS model
export interface SubscriptionPlan {
  id: string
  name: string
  tier: "solo" | "business"
  description: string
  basePrice: number // in cents
  perTechnicianPrice?: number // in cents, only for business tier
  transactionFeePercent: number
  features: string[]
}

export const SUBSCRIPTION_PLANS: SubscriptionPlan[] = [
  {
    id: "solo-plan",
    name: "Solo Mechanic",
    tier: "solo",
    description: "Perfect for independent licensed mechanics",
    basePrice: 9900, // $99/month
    transactionFeePercent: 8,
    features: [
      "Single technician account",
      "Unlimited bookings",
      "Customer management",
      "Payment processing",
      "Mobile app access",
      "Basic analytics",
      "8% transaction fee",
    ],
  },
  {
    id: "business-plan",
    name: "Business",
    tier: "business",
    description: "For shops with multiple technicians",
    basePrice: 29900, // $299/month base
    perTechnicianPrice: 4900, // $49/month per additional technician
    transactionFeePercent: 5,
    features: [
      "Up to 10 technicians",
      "Unlimited bookings",
      "Multi-technician dispatch",
      "Custom pricing packages",
      "White-label branding",
      "Advanced analytics",
      "Priority support",
      "5% transaction fee",
      "$49/month per additional technician",
    ],
  },
]
