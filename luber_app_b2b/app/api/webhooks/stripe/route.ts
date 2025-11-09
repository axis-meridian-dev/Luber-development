import { NextRequest, NextResponse } from "next/server"
import Stripe from "stripe"
import { stripe } from "@/lib/stripe"
import { createClient } from "@/lib/supabase/server"

/**
 * Stripe Webhook Handler
 *
 * Handles webhook events from Stripe for:
 * 1. Subscription lifecycle (created, updated, deleted)
 * 2. Payment events (succeeded, failed)
 * 3. Connect account events (account.updated)
 *
 * See: https://stripe.com/docs/webhooks
 */

export async function POST(req: NextRequest) {
  const supabase = await createClient()

  try {
    // Get the webhook signature from headers
    const signature = req.headers.get("stripe-signature")
    if (!signature) {
      console.error("Missing Stripe signature header")
      return NextResponse.json({ error: "Missing signature" }, { status: 400 })
    }

    // Get webhook secret from environment
    const webhookSecret = process.env.STRIPE_WEBHOOK_SECRET
    if (!webhookSecret) {
      console.error("STRIPE_WEBHOOK_SECRET not configured")
      return NextResponse.json({ error: "Webhook secret not configured" }, { status: 500 })
    }

    // Read raw request body
    const body = await req.text()

    // Verify webhook signature and construct event
    let event: Stripe.Event
    try {
      event = stripe.webhooks.constructEvent(body, signature, webhookSecret)
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : "Unknown error"
      console.error("Webhook signature verification failed:", errorMessage)
      return NextResponse.json({ error: `Webhook signature verification failed: ${errorMessage}` }, { status: 400 })
    }

    console.log(`Received Stripe webhook: ${event.type} (${event.id})`)

    // Handle different event types
    switch (event.type) {
      // --- SUBSCRIPTION LIFECYCLE EVENTS ---

      case "customer.subscription.created": {
        const subscription = event.data.object as Stripe.Subscription

        // Extract shop_id from metadata
        const shopId = subscription.metadata?.shop_id
        if (!shopId) {
          console.error("Missing shop_id in subscription metadata")
          break
        }

        // Update shop subscription status
        const { error } = await supabase
          .from("shops")
          .update({
            subscription_status: subscription.status,
            stripe_subscription_id: subscription.id,
            trial_ends_at: subscription.trial_end ? new Date(subscription.trial_end * 1000).toISOString() : null,
            current_period_end: subscription.current_period_end ? new Date(subscription.current_period_end * 1000).toISOString() : null,
            updated_at: new Date().toISOString(),
          })
          .eq("id", shopId)

        if (error) {
          console.error("Failed to update shop subscription status:", error)
        } else {
          console.log(`Subscription created for shop ${shopId}: ${subscription.id}`)
        }

        // Log to subscription history
        await supabase.from("shop_subscription_history").insert({
          shop_id: shopId,
          event_type: "subscription_created",
          stripe_event_id: event.id,
          subscription_tier: subscription.metadata.tier,
          technician_count: parseInt(subscription.metadata.technician_count || "1"),
          metadata: event.data.object,
        })

        break
      }

      case "customer.subscription.updated": {
        const subscription = event.data.object as Stripe.Subscription

        const shopId = subscription.metadata?.shop_id
        if (!shopId) {
          console.error("Missing shop_id in subscription metadata")
          break
        }

        // Update shop subscription status
        const { error } = await supabase
          .from("shops")
          .update({
            subscription_status: subscription.status,
            trial_ends_at: subscription.trial_end ? new Date(subscription.trial_end * 1000).toISOString() : null,
            current_period_end: subscription.current_period_end ? new Date(subscription.current_period_end * 1000).toISOString() : null,
            updated_at: new Date().toISOString(),
          })
          .eq("stripe_subscription_id", subscription.id)

        if (error) {
          console.error("Failed to update shop subscription:", error)
        } else {
          console.log(`Subscription updated: ${subscription.id} -> status: ${subscription.status}`)
        }

        // Log to subscription history
        await supabase.from("shop_subscription_history").insert({
          shop_id: shopId,
          event_type: "subscription_updated",
          stripe_event_id: event.id,
          subscription_tier: subscription.metadata.tier,
          technician_count: parseInt(subscription.metadata.technician_count || "1"),
          metadata: event.data.object,
        })

        break
      }

      case "customer.subscription.deleted": {
        const subscription = event.data.object as Stripe.Subscription

        // Update subscription status to canceled
        const { error } = await supabase
          .from("shops")
          .update({
            subscription_status: "canceled",
            updated_at: new Date().toISOString(),
          })
          .eq("stripe_subscription_id", subscription.id)

        if (error) {
          console.error("Failed to cancel shop subscription:", error)
        } else {
          console.log(`Subscription canceled: ${subscription.id}`)
        }

        // Log to subscription history
        const shopId = subscription.metadata?.shop_id
        if (shopId) {
          await supabase.from("shop_subscription_history").insert({
            shop_id: shopId,
            event_type: "subscription_deleted",
            stripe_event_id: event.id,
            subscription_tier: subscription.metadata?.tier,
            metadata: event.data.object,
          })
        }

        break
      }

      // --- PAYMENT EVENTS ---

      case "invoice.payment_succeeded": {
        const invoice = event.data.object as Stripe.Invoice

        // Get subscription from invoice
        const subscriptionId = typeof invoice.subscription === 'string' ? invoice.subscription : invoice.subscription?.id
        if (!subscriptionId) {
          console.log("Invoice not associated with subscription, skipping")
          break
        }

        // Retrieve subscription to get metadata
        const subscription = await stripe.subscriptions.retrieve(subscriptionId)
        const shopId = subscription.metadata?.shop_id

        if (!shopId) {
          console.error("Missing shop_id in subscription metadata")
          break
        }

        // Ensure subscription is active
        const { error: updateError } = await supabase
          .from("shops")
          .update({
            subscription_status: "active",
            updated_at: new Date().toISOString(),
          })
          .eq("id", shopId)

        if (updateError) {
          console.error("Failed to update shop status to active:", updateError)
        }

        // Log payment to subscription history
        await supabase.from("shop_subscription_history").insert({
          shop_id: shopId,
          event_type: "payment_succeeded",
          stripe_event_id: event.id,
          subscription_tier: subscription.metadata.tier,
          amount_paid: invoice.amount_paid / 100, // Convert from cents to dollars
          technician_count: parseInt(subscription.metadata.technician_count || "1"),
          metadata: {
            invoice_id: invoice.id,
            invoice_number: invoice.number,
            period_start: invoice.period_start,
            period_end: invoice.period_end,
          },
        })

        console.log(`Payment succeeded for shop ${shopId}: $${invoice.amount_paid / 100}`)

        break
      }

      case "invoice.payment_failed": {
        const invoice = event.data.object as Stripe.Invoice

        const subscriptionId = typeof invoice.subscription === 'string' ? invoice.subscription : invoice.subscription?.id
        if (!subscriptionId) {
          console.log("Invoice not associated with subscription, skipping")
          break
        }

        // Retrieve subscription to get metadata
        const subscription = await stripe.subscriptions.retrieve(subscriptionId)
        const shopId = subscription.metadata?.shop_id

        if (!shopId) {
          console.error("Missing shop_id in subscription metadata")
          break
        }

        // Mark subscription as past_due
        const { error: updateError } = await supabase
          .from("shops")
          .update({
            subscription_status: "past_due",
            updated_at: new Date().toISOString(),
          })
          .eq("id", shopId)

        if (updateError) {
          console.error("Failed to mark subscription as past_due:", updateError)
        }

        // Log payment failure to subscription history
        await supabase.from("shop_subscription_history").insert({
          shop_id: shopId,
          event_type: "payment_failed",
          stripe_event_id: event.id,
          subscription_tier: subscription.metadata.tier,
          amount_paid: 0,
          technician_count: parseInt(subscription.metadata.technician_count || "1"),
          metadata: {
            invoice_id: invoice.id,
            attempt_count: invoice.attempt_count,
            next_payment_attempt: invoice.next_payment_attempt,
          },
        })

        console.error(`Payment failed for shop ${shopId}`)

        // TODO: Send notification email to shop owner about payment failure
        // TODO: Implement email service integration

        break
      }

      // --- STRIPE CONNECT EVENTS ---

      case "account.updated": {
        const account = event.data.object as Stripe.Account

        // Extract shop_id from account metadata
        const shopId = account.metadata?.shop_id
        if (!shopId) {
          console.log("Account update not associated with a shop, skipping")
          break
        }

        // Update shop's Connect account status
        const { error } = await supabase
          .from("shops")
          .update({
            connect_account_id: account.id,
            connect_onboarding_completed: account.details_submitted === true,
            connect_charges_enabled: account.charges_enabled === true,
            connect_payouts_enabled: account.payouts_enabled === true,
            connect_details_submitted: account.details_submitted === true,
            connect_requirements_currently_due: account.requirements?.currently_due || [],
            connect_requirements_eventually_due: account.requirements?.eventually_due || [],
            updated_at: new Date().toISOString(),
          })
          .eq("id", shopId)

        if (error) {
          console.error("Failed to update Connect account status:", error)
        } else {
          console.log(
            `Connect account updated for shop ${shopId}: onboarding=${account.details_submitted}, charges=${account.charges_enabled}, payouts=${account.payouts_enabled}`
          )
        }

        break
      }

      // --- UNHANDLED EVENTS ---

      default:
        console.log(`Unhandled event type: ${event.type}`)
    }

    // Always return 200 to acknowledge receipt
    return NextResponse.json({ received: true, eventType: event.type }, { status: 200 })
  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : "Unknown error"
    console.error("Webhook handler error:", errorMessage)

    // Return 500 to trigger Stripe retry
    return NextResponse.json({ error: "Internal server error", message: errorMessage }, { status: 500 })
  }
}

// Disable Next.js body parsing so we can verify webhook signature
export const config = {
  api: {
    bodyParser: false,
  },
}
