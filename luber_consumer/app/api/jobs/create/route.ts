import { type NextRequest, NextResponse } from "next/server"
import { createClient } from "@/lib/supabase/server"
import { calculateJobPrice } from "@/lib/pricing"
import { stripe } from "@/lib/stripe"

export async function POST(request: NextRequest) {
  try {
    const supabase = await createClient()

    // Get authenticated user
    const {
      data: { user },
      error: authError,
    } = await supabase.auth.getUser()
    if (authError || !user) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 })
    }

    const body = await request.json()
    const { vehicle_id, address_id, oil_type, scheduled_time, special_instructions, payment_method_id } = body

    // Validate required fields
    if (!vehicle_id || !address_id || !oil_type || !scheduled_time) {
      return NextResponse.json({ error: "Missing required fields" }, { status: 400 })
    }

    // Get vehicle details for pricing
    const { data: vehicle, error: vehicleError } = await supabase
      .from("vehicles")
      .select("vehicle_type")
      .eq("id", vehicle_id)
      .eq("user_id", user.id)
      .single()

    if (vehicleError || !vehicle) {
      return NextResponse.json({ error: "Vehicle not found" }, { status: 404 })
    }

    // Calculate pricing
    const pricing = calculateJobPrice(oil_type, vehicle.vehicle_type)

    // Create Stripe Payment Intent
    const paymentIntent = await stripe.paymentIntents.create({
      amount: pricing.price_cents,
      currency: "usd",
      payment_method: payment_method_id,
      confirm: false,
      metadata: {
        customer_id: user.id,
        vehicle_id,
        oil_type,
      },
    })

    // Create job in database
    const { data: job, error: jobError } = await supabase
      .from("jobs")
      .insert({
        customer_id: user.id,
        vehicle_id,
        address_id,
        oil_type,
        scheduled_time,
        special_instructions,
        status: "pending",
        stripe_payment_intent_id: paymentIntent.id,
        ...pricing,
      })
      .select()
      .single()

    if (jobError) {
      // Cancel payment intent if job creation fails
      await stripe.paymentIntents.cancel(paymentIntent.id)
      console.error("[v0] Job creation error:", jobError)
      return NextResponse.json({ error: "Failed to create job" }, { status: 500 })
    }

    return NextResponse.json({
      job,
      client_secret: paymentIntent.client_secret,
    })
  } catch (error) {
    console.error("[v0] Error creating job:", error)
    return NextResponse.json({ error: "Internal server error" }, { status: 500 })
  }
}
