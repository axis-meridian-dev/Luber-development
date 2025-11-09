"use server"

import { createClient } from "@/lib/supabase/server"
import {
  createConnectAccount,
  createConnectAccountLink,
  getConnectAccountStatus,
  type ConnectAccountStatus,
} from "@/lib/stripe-connect"

/**
 * Server actions for Stripe Connect integration
 *
 * These actions handle shop onboarding to Stripe Connect for payment splitting
 */

interface ActionResponse<T = void> {
  success: boolean
  data?: T
  error?: string
}

/**
 * Create a Stripe Connect account for the authenticated shop owner
 * Called during shop onboarding or when setting up payments
 *
 * @returns { success, data: { accountId }, error }
 */
export async function createConnectAccountAction(): Promise<ActionResponse<{ accountId: string }>> {
  const supabase = await createClient()

  try {
    // Verify user is authenticated
    const {
      data: { user },
      error: authError,
    } = await supabase.auth.getUser()

    if (authError || !user) {
      return { success: false, error: "Unauthorized. Please log in." }
    }

    // Get shop owned by this user
    const { data: shop, error: shopError } = await supabase
      .from("shops")
      .select("*")
      .eq("owner_id", user.id)
      .single()

    if (shopError || !shop) {
      return { success: false, error: "Shop not found. Please complete onboarding first." }
    }

    // Check if shop already has a Connect account
    if (shop.connect_account_id) {
      return {
        success: true,
        data: { accountId: shop.connect_account_id },
      }
    }

    // Create new Connect account
    const accountId = await createConnectAccount(
      shop.id,
      shop.business_email,
      shop.business_legal_name,
      "US" // Currently only supporting US shops
    )

    // Save Connect account ID to database
    const { error: updateError } = await supabase
      .from("shops")
      .update({
        connect_account_id: accountId,
        updated_at: new Date().toISOString(),
      })
      .eq("id", shop.id)

    if (updateError) {
      console.error("Failed to save Connect account ID:", updateError)
      return { success: false, error: "Failed to save Connect account. Please try again." }
    }

    return {
      success: true,
      data: { accountId },
    }
  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : "Unknown error"
    console.error("Error creating Connect account:", errorMessage)
    return { success: false, error: errorMessage }
  }
}

/**
 * Get Stripe Connect onboarding link for shop owner
 * Redirects shop owner to Stripe-hosted onboarding flow
 *
 * @param refreshUrl - URL to redirect if onboarding link expires
 * @param returnUrl - URL to redirect after successful onboarding
 * @returns { success, data: { onboardingUrl }, error }
 */
export async function getConnectAccountLinkAction(
  refreshUrl: string,
  returnUrl: string
): Promise<ActionResponse<{ onboardingUrl: string }>> {
  const supabase = await createClient()

  try {
    // Verify user is authenticated
    const {
      data: { user },
      error: authError,
    } = await supabase.auth.getUser()

    if (authError || !user) {
      return { success: false, error: "Unauthorized. Please log in." }
    }

    // Get shop owned by this user
    const { data: shop, error: shopError } = await supabase
      .from("shops")
      .select("connect_account_id")
      .eq("owner_id", user.id)
      .single()

    if (shopError || !shop) {
      return { success: false, error: "Shop not found. Please complete onboarding first." }
    }

    if (!shop.connect_account_id) {
      return { success: false, error: "Connect account not found. Please create an account first." }
    }

    // Generate onboarding link
    const onboardingUrl = await createConnectAccountLink(shop.connect_account_id, refreshUrl, returnUrl)

    return {
      success: true,
      data: { onboardingUrl },
    }
  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : "Unknown error"
    console.error("Error creating Connect account link:", errorMessage)
    return { success: false, error: errorMessage }
  }
}

/**
 * Get current status of shop's Stripe Connect account
 * Use this to check if shop can accept payments
 *
 * @returns { success, data: ConnectAccountStatus, error }
 */
export async function getConnectAccountStatusAction(): Promise<ActionResponse<ConnectAccountStatus>> {
  const supabase = await createClient()

  try {
    // Verify user is authenticated
    const {
      data: { user },
      error: authError,
    } = await supabase.auth.getUser()

    if (authError || !user) {
      return { success: false, error: "Unauthorized. Please log in." }
    }

    // Get shop owned by this user
    const { data: shop, error: shopError } = await supabase
      .from("shops")
      .select("connect_account_id, connect_onboarding_completed")
      .eq("owner_id", user.id)
      .single()

    if (shopError || !shop) {
      return { success: false, error: "Shop not found. Please complete onboarding first." }
    }

    // If no Connect account exists yet
    if (!shop.connect_account_id) {
      return {
        success: true,
        data: {
          accountId: null,
          onboardingCompleted: false,
          chargesEnabled: false,
          payoutsEnabled: false,
          detailsSubmitted: false,
          requirementsCurrentlyDue: [],
          requirementsEventuallyDue: [],
        },
      }
    }

    // Fetch latest status from Stripe
    const status = await getConnectAccountStatus(shop.connect_account_id)

    // Update database with latest status (cache for UI)
    await supabase
      .from("shops")
      .update({
        connect_onboarding_completed: status.onboardingCompleted,
        connect_charges_enabled: status.chargesEnabled,
        connect_payouts_enabled: status.payoutsEnabled,
        connect_details_submitted: status.detailsSubmitted,
        connect_requirements_currently_due: status.requirementsCurrentlyDue,
        connect_requirements_eventually_due: status.requirementsEventuallyDue,
        updated_at: new Date().toISOString(),
      })
      .eq("id", shop.connect_account_id)

    return {
      success: true,
      data: status,
    }
  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : "Unknown error"
    console.error("Error fetching Connect account status:", errorMessage)
    return { success: false, error: errorMessage }
  }
}

/**
 * Refresh Connect account onboarding link
 * Use this if the original link expired (links expire after 5 minutes)
 *
 * @param returnUrl - URL to redirect after successful onboarding
 * @returns { success, data: { onboardingUrl }, error }
 */
export async function refreshConnectAccountLinkAction(
  returnUrl: string
): Promise<ActionResponse<{ onboardingUrl: string }>> {
  // Use same logic as getConnectAccountLinkAction
  // The refresh URL will be the same page that calls this action
  return getConnectAccountLinkAction(returnUrl, returnUrl)
}

/**
 * Check if shop's Connect account is ready to accept payments
 * Convenience action for UI conditionals
 *
 * @returns { success, data: { ready: boolean, reason?: string }, error }
 */
export async function isConnectAccountReadyAction(): Promise<
  ActionResponse<{ ready: boolean; reason?: string }>
> {
  const statusResult = await getConnectAccountStatusAction()

  if (!statusResult.success || !statusResult.data) {
    return {
      success: false,
      error: statusResult.error || "Failed to check account status",
    }
  }

  const status = statusResult.data

  // Account is ready if:
  // 1. It exists
  // 2. Onboarding is complete
  // 3. Charges and payouts are enabled
  if (!status.accountId) {
    return {
      success: true,
      data: {
        ready: false,
        reason: "No Connect account found. Please set up payments.",
      },
    }
  }

  if (!status.onboardingCompleted) {
    return {
      success: true,
      data: {
        ready: false,
        reason: "Please complete Stripe onboarding to accept payments.",
      },
    }
  }

  if (!status.chargesEnabled) {
    return {
      success: true,
      data: {
        ready: false,
        reason: "Your account cannot accept charges yet. Please contact support.",
      },
    }
  }

  if (!status.payoutsEnabled) {
    return {
      success: true,
      data: {
        ready: false,
        reason: "Your account cannot receive payouts yet. Please contact support.",
      },
    }
  }

  if (status.requirementsCurrentlyDue.length > 0) {
    return {
      success: true,
      data: {
        ready: false,
        reason: `Please complete the following requirements: ${status.requirementsCurrentlyDue.join(", ")}`,
      },
    }
  }

  return {
    success: true,
    data: { ready: true },
  }
}
