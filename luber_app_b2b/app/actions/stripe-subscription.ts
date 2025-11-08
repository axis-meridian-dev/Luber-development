"use server"

import { stripe, SUBSCRIPTION_PLANS } from "@/lib/stripe"
import { createServerClient } from "@/lib/supabase/server"

export async function createSubscriptionCheckout(planId: string, technicianCount = 1) {
  const supabase = await createServerClient()

  const {
    data: { user },
    error: authError,
  } = await supabase.auth.getUser()
  if (authError || !user) {
    throw new Error("Unauthorized")
  }

  // Find the plan
  const plan = SUBSCRIPTION_PLANS.find((p) => p.id === planId)
  if (!plan) {
    throw new Error(`Plan with id "${planId}" not found`)
  }

  // Get or create shop
  const { data: shop } = await supabase.from("shops").select("*").eq("owner_id", user.id).single()

  if (!shop) {
    throw new Error("Shop not found. Please complete onboarding first.")
  }

  // Calculate total amount
  let totalAmount = plan.basePrice
  if (plan.tier === "business" && technicianCount > 1) {
    totalAmount += (technicianCount - 1) * (plan.perTechnicianPrice || 0)
  }

  // Create or get Stripe customer
  let customerId = shop.stripe_customer_id
  if (!customerId) {
    const customer = await stripe.customers.create({
      email: user.email,
      name: shop.shop_name,
      metadata: {
        shop_id: shop.id,
        user_id: user.id,
      },
    })
    customerId = customer.id

    // Update shop with customer ID
    await supabase.from("shops").update({ stripe_customer_id: customerId }).eq("id", shop.id)
  }

  // Create checkout session for subscription
  const session = await stripe.checkout.sessions.create({
    customer: customerId,
    ui_mode: "embedded",
    redirect_on_completion: "never",
    line_items: [
      {
        price_data: {
          currency: "usd",
          product_data: {
            name: plan.name,
            description: plan.description,
          },
          unit_amount: totalAmount,
          recurring: {
            interval: "month",
          },
        },
        quantity: 1,
      },
    ],
    mode: "subscription",
    subscription_data: {
      metadata: {
        shop_id: shop.id,
        plan_id: planId,
        tier: plan.tier,
        technician_count: technicianCount.toString(),
      },
      trial_period_days: 14,
    },
    metadata: {
      shop_id: shop.id,
      plan_id: planId,
    },
  })

  return session.client_secret
}

export async function getSubscriptionStatus() {
  const supabase = await createServerClient()

  const {
    data: { user },
    error: authError,
  } = await supabase.auth.getUser()
  if (authError || !user) {
    return null
  }

  const { data: shop } = await supabase.from("shops").select("*").eq("owner_id", user.id).single()

  return shop
}
