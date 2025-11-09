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
    const { paymentMethodId } = body

    if (!paymentMethodId) {
      return NextResponse.json({ error: "Payment method ID is required" }, { status: 400 })
    }

    // Verify the payment method belongs to the user
    const { data: paymentMethod, error: fetchError } = await supabase
      .from("payment_methods")
      .select("*")
      .eq("id", paymentMethodId)
      .eq("user_id", user.id)
      .single()

    if (fetchError || !paymentMethod) {
      return NextResponse.json({ error: "Payment method not found" }, { status: 404 })
    }

    // Unset all default payment methods for this user
    await supabase.from("payment_methods").update({ is_default: false }).eq("user_id", user.id)

    // Set the selected payment method as default
    const { error: updateError } = await supabase
      .from("payment_methods")
      .update({ is_default: true })
      .eq("id", paymentMethodId)

    if (updateError) {
      console.error("Error setting default payment method:", updateError)
      return NextResponse.json({ error: "Failed to set default payment method" }, { status: 500 })
    }

    // Update default payment method in Stripe
    const { data: profile } = await supabase.from("profiles").select("stripe_customer_id").eq("id", user.id).single()

    if (profile?.stripe_customer_id) {
      await stripe.customers.update(profile.stripe_customer_id, {
        invoice_settings: {
          default_payment_method: paymentMethod.stripe_payment_method_id,
        },
      })
    }

    return NextResponse.json({ success: true })
  } catch (error: any) {
    console.error("Error setting default payment method:", error)
    return NextResponse.json({ error: error.message || "Failed to set default payment method" }, { status: 500 })
  }
}
