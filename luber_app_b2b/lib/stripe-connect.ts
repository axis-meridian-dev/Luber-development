import "server-only"

import Stripe from "stripe"
import { stripe, SUBSCRIPTION_PLANS } from "./stripe"

/**
 * Stripe Connect Configuration
 *
 * Business model: Collect-then-transfer pattern
 * - Platform collects payment from customer
 * - Platform deducts transaction fee (5% or 8% based on tier)
 * - Platform transfers remaining amount to shop's Connect account
 */

export interface ConnectAccountStatus {
  accountId: string | null
  onboardingCompleted: boolean
  chargesEnabled: boolean
  payoutsEnabled: boolean
  detailsSubmitted: boolean
  requirementsCurrentlyDue: string[]
  requirementsEventuallyDue: string[]
}

/**
 * Create a Stripe Connect Express account for a shop
 * Express accounts are ideal for B2B platforms - Stripe handles onboarding/compliance
 *
 * @param shopId - Shop UUID from database
 * @param businessEmail - Shop's business email
 * @param businessName - Shop's legal business name
 * @param country - Two-letter country code (default: US)
 * @returns Stripe Connect account ID
 */
export async function createConnectAccount(
  shopId: string,
  businessEmail: string,
  businessName: string,
  country: string = "US"
): Promise<string> {
  try {
    // Create Express Connect account
    // Express accounts: Stripe manages verification, compliance, and payouts
    const account = await stripe.accounts.create({
      type: "express",
      country,
      email: businessEmail,
      business_type: "company", // Assume shops are registered businesses
      capabilities: {
        card_payments: { requested: true },
        transfers: { requested: true },
      },
      business_profile: {
        name: businessName,
      },
      metadata: {
        shop_id: shopId,
        platform: "luber_b2b",
      },
    })

    return account.id
  } catch (error) {
    console.error("Error creating Stripe Connect account:", error)
    throw new Error(`Failed to create Connect account: ${error instanceof Error ? error.message : "Unknown error"}`)
  }
}

/**
 * Generate Stripe Connect onboarding link
 * This is where shop owners complete identity verification, bank details, etc.
 *
 * @param connectAccountId - Stripe Connect account ID (acct_xxx)
 * @param refreshUrl - URL to redirect if user needs to refresh onboarding
 * @param returnUrl - URL to redirect after successful onboarding
 * @returns Account link URL (expires in 5 minutes)
 */
export async function createConnectAccountLink(
  connectAccountId: string,
  refreshUrl: string,
  returnUrl: string
): Promise<string> {
  try {
    const accountLink = await stripe.accountLinks.create({
      account: connectAccountId,
      refresh_url: refreshUrl,
      return_url: returnUrl,
      type: "account_onboarding",
      collect: "eventually_due", // Collect all required information upfront
    })

    return accountLink.url
  } catch (error) {
    console.error("Error creating Connect account link:", error)
    throw new Error(`Failed to create account link: ${error instanceof Error ? error.message : "Unknown error"}`)
  }
}

/**
 * Check the current status of a Stripe Connect account
 * Use this to determine if shop can accept payments
 *
 * @param connectAccountId - Stripe Connect account ID
 * @returns Account status details
 */
export async function getConnectAccountStatus(
  connectAccountId: string
): Promise<ConnectAccountStatus> {
  try {
    const account = await stripe.accounts.retrieve(connectAccountId)

    return {
      accountId: account.id,
      onboardingCompleted: account.details_submitted === true,
      chargesEnabled: account.charges_enabled === true,
      payoutsEnabled: account.payouts_enabled === true,
      detailsSubmitted: account.details_submitted === true,
      requirementsCurrentlyDue: account.requirements?.currently_due || [],
      requirementsEventuallyDue: account.requirements?.eventually_due || [],
    }
  } catch (error) {
    console.error("Error fetching Connect account status:", error)
    throw new Error(`Failed to fetch account status: ${error instanceof Error ? error.message : "Unknown error"}`)
  }
}

/**
 * Calculate platform fee and shop payout for a booking
 *
 * Business tier: 95% to shop, 5% platform fee
 * Solo tier: 92% to shop, 8% platform fee
 *
 * @param totalAmount - Total booking amount in cents
 * @param subscriptionTier - "solo" or "business"
 * @returns { platformFee, shopPayout } in cents
 */
export function calculatePaymentSplit(
  totalAmount: number,
  subscriptionTier: "solo" | "business"
): { platformFee: number; shopPayout: number } {
  // Get transaction fee percentage from subscription plan
  const plan = SUBSCRIPTION_PLANS.find((p) => p.tier === subscriptionTier)
  if (!plan) {
    throw new Error(`Invalid subscription tier: ${subscriptionTier}`)
  }

  const feePercent = plan.transactionFeePercent
  const platformFee = Math.round(totalAmount * (feePercent / 100))
  const shopPayout = totalAmount - platformFee

  return {
    platformFee,
    shopPayout,
  }
}

/**
 * Create a payment intent with platform fee and transfer to shop
 * This is the core payment flow for B2B bookings
 *
 * @param totalAmount - Total booking amount in cents
 * @param connectAccountId - Shop's Stripe Connect account ID
 * @param subscriptionTier - Shop's subscription tier ("solo" or "business")
 * @param bookingId - Booking UUID for metadata
 * @param shopId - Shop UUID for metadata
 * @returns Stripe PaymentIntent
 */
export async function createPaymentIntentWithTransfer(
  totalAmount: number,
  connectAccountId: string,
  subscriptionTier: "solo" | "business",
  bookingId: string,
  shopId: string
): Promise<Stripe.PaymentIntent> {
  try {
    // Calculate platform fee and shop payout
    const { platformFee, shopPayout } = calculatePaymentSplit(totalAmount, subscriptionTier)

    // Create payment intent with application fee
    // Platform collects full amount, then transfers shop's portion
    const paymentIntent = await stripe.paymentIntents.create({
      amount: totalAmount,
      currency: "usd",
      application_fee_amount: platformFee,
      transfer_data: {
        destination: connectAccountId,
      },
      metadata: {
        booking_id: bookingId,
        shop_id: shopId,
        subscription_tier: subscriptionTier,
        platform_fee: platformFee.toString(),
        shop_payout: shopPayout.toString(),
      },
      description: `Luber B2B - Mobile oil change service`,
    })

    return paymentIntent
  } catch (error) {
    console.error("Error creating payment intent with transfer:", error)
    throw new Error(`Failed to create payment: ${error instanceof Error ? error.message : "Unknown error"}`)
  }
}

/**
 * Create a transfer to a Connect account (for manual payouts)
 * Useful for refunds, bonuses, or other one-off payments
 *
 * @param amount - Amount to transfer in cents
 * @param connectAccountId - Shop's Stripe Connect account ID
 * @param description - Description of transfer
 * @param metadata - Additional metadata
 * @returns Stripe Transfer
 */
export async function createTransfer(
  amount: number,
  connectAccountId: string,
  description: string,
  metadata?: Record<string, string>
): Promise<Stripe.Transfer> {
  try {
    const transfer = await stripe.transfers.create({
      amount,
      currency: "usd",
      destination: connectAccountId,
      description,
      metadata,
    })

    return transfer
  } catch (error) {
    console.error("Error creating transfer:", error)
    throw new Error(`Failed to create transfer: ${error instanceof Error ? error.message : "Unknown error"}`)
  }
}

/**
 * Disconnect a shop's Connect account
 * Call this when a shop cancels their subscription or closes their account
 *
 * @param connectAccountId - Stripe Connect account ID to disconnect
 */
export async function disconnectAccount(connectAccountId: string): Promise<void> {
  try {
    await stripe.accounts.del(connectAccountId)
  } catch (error) {
    console.error("Error disconnecting Connect account:", error)
    throw new Error(`Failed to disconnect account: ${error instanceof Error ? error.message : "Unknown error"}`)
  }
}

/**
 * Update Connect account capabilities (e.g., enable card payments)
 *
 * @param connectAccountId - Stripe Connect account ID
 * @param capabilities - Capabilities to update
 * @returns Updated Stripe account
 */
export async function updateConnectAccountCapabilities(
  connectAccountId: string,
  capabilities: Stripe.AccountUpdateParams.Capabilities
): Promise<Stripe.Account> {
  try {
    const account = await stripe.accounts.update(connectAccountId, {
      capabilities,
    })

    return account
  } catch (error) {
    console.error("Error updating Connect account capabilities:", error)
    throw new Error(`Failed to update capabilities: ${error instanceof Error ? error.message : "Unknown error"}`)
  }
}
