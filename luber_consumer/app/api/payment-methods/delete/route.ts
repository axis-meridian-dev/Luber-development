import { createClient } from "@/lib/supabase/server"
import { stripe } from "@/lib/stripe"
import { NextResponse } from "next/server"

export async function DELETE(request: Request) {
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

    // Check if this is the only payment method
    const { count } = await supabase
      .from("payment_methods")
      .select("*", { count: "exact", head: true })
      .eq("user_id", user.id)

    // Detach payment method from Stripe customer
    try {
      await stripe.paymentMethods.detach(paymentMethod.stripe_payment_method_id)
    } catch (stripeError: any) {
      console.error("Error detaching payment method from Stripe:", stripeError)
      // Continue with database deletion even if Stripe fails
    }

    // Delete from database
    const { error: deleteError } = await supabase.from("payment_methods").delete().eq("id", paymentMethodId)

    if (deleteError) {
      console.error("Error deleting payment method:", deleteError)
      return NextResponse.json({ error: "Failed to delete payment method" }, { status: 500 })
    }

    // If this was the default payment method and there are others, set a new default
    if (paymentMethod.is_default && count && count > 1) {
      const { data: newDefault } = await supabase
        .from("payment_methods")
        .select("*")
        .eq("user_id", user.id)
        .limit(1)
        .single()

      if (newDefault) {
        await supabase.from("payment_methods").update({ is_default: true }).eq("id", newDefault.id)

        // Update Stripe default payment method
        const { data: profile } = await supabase
          .from("profiles")
          .select("stripe_customer_id")
          .eq("id", user.id)
          .single()

        if (profile?.stripe_customer_id) {
          await stripe.customers.update(profile.stripe_customer_id, {
            invoice_settings: {
              default_payment_method: newDefault.stripe_payment_method_id,
            },
          })
        }
      }
    }

    return NextResponse.json({ success: true })
  } catch (error: any) {
    console.error("Error deleting payment method:", error)
    return NextResponse.json({ error: error.message || "Failed to delete payment method" }, { status: 500 })
  }
}
