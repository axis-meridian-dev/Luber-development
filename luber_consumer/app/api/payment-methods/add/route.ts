import { createClient } from "@/lib/supabase/server"
import { stripe } from "@/lib/stripe"
import { NextResponse } from "next/server"

export async function POST(request: Request) {
  try {
    const supabase = await createClient()

    // Verify user is authenticated
    const {
      data: { user },
    } = await supabase.auth.getUser()

    if (!user) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 })
    }

    // Parse request body
    const body = await request.json()
    const { paymentMethodId, setAsDefault } = body

    if (!paymentMethodId) {
      return NextResponse.json({ error: "Payment method ID is required" }, { status: 400 })
    }

    // Get or create Stripe customer
    const { data: profile } = await supabase.from("profiles").select("*").eq("id", user.id).single()

    let customerId = profile?.stripe_customer_id

    if (!customerId) {
      // Create Stripe customer
      const customer = await stripe.customers.create({
        email: user.email,
        name: profile?.full_name,
        metadata: {
          supabase_user_id: user.id,
        },
      })

      customerId = customer.id

      // Update profile with Stripe customer ID
      await supabase.from("profiles").update({ stripe_customer_id: customerId }).eq("id", user.id)
    }

    // Attach payment method to customer
    await stripe.paymentMethods.attach(paymentMethodId, {
      customer: customerId,
    })

    // Retrieve payment method details
    const paymentMethod = await stripe.paymentMethods.retrieve(paymentMethodId)

    if (paymentMethod.type !== "card") {
      return NextResponse.json({ error: "Only card payment methods are supported" }, { status: 400 })
    }

    // If setting as default, unset other default payment methods
    if (setAsDefault) {
      await supabase.from("payment_methods").update({ is_default: false }).eq("user_id", user.id)
    }

    // Check if this is the first payment method (auto-set as default)
    const { count } = await supabase
      .from("payment_methods")
      .select("*", { count: "exact", head: true })
      .eq("user_id", user.id)

    const isFirstPaymentMethod = count === 0

    // Save payment method to database
    const { data: savedPaymentMethod, error: dbError } = await supabase
      .from("payment_methods")
      .insert({
        user_id: user.id,
        stripe_payment_method_id: paymentMethod.id,
        card_brand: paymentMethod.card?.brand || null,
        card_last4: paymentMethod.card?.last4 || null,
        exp_month: paymentMethod.card?.exp_month || null,
        exp_year: paymentMethod.card?.exp_year || null,
        is_default: setAsDefault || isFirstPaymentMethod,
      })
      .select()
      .single()

    if (dbError) {
      console.error("Error saving payment method to database:", dbError)
      return NextResponse.json({ error: "Failed to save payment method" }, { status: 500 })
    }

    // Set as default payment method in Stripe if requested
    if (setAsDefault || isFirstPaymentMethod) {
      await stripe.customers.update(customerId, {
        invoice_settings: {
          default_payment_method: paymentMethod.id,
        },
      })
    }

    return NextResponse.json({ paymentMethod: savedPaymentMethod })
  } catch (error: any) {
    console.error("Error adding payment method:", error)
    return NextResponse.json({ error: error.message || "Failed to add payment method" }, { status: 500 })
  }
}
