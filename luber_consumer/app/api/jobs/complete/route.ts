import { type NextRequest, NextResponse } from "next/server"
import { createClient } from "@/lib/supabase/server"
import { stripe } from "@/lib/stripe"

export async function POST(request: NextRequest) {
  try {
    const supabase = await createClient()

    const {
      data: { user },
      error: authError,
    } = await supabase.auth.getUser()
    if (authError || !user) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 })
    }

    const body = await request.json()
    const { job_id } = body

    if (!job_id) {
      return NextResponse.json({ error: "Job ID required" }, { status: 400 })
    }

    // Get job details
    const { data: job, error: jobError } = await supabase
      .from("jobs")
      .select("*, technician_profiles!inner(stripe_account_id)")
      .eq("id", job_id)
      .eq("technician_id", user.id)
      .single()

    if (jobError || !job) {
      return NextResponse.json({ error: "Job not found" }, { status: 404 })
    }

    // Confirm payment intent
    if (job.stripe_payment_intent_id) {
      await stripe.paymentIntents.confirm(job.stripe_payment_intent_id)

      // Transfer earnings to technician (if they have Stripe Connect account)
      const techProfile = job.technician_profiles as any
      if (techProfile?.stripe_account_id) {
        const transfer = await stripe.transfers.create({
          amount: job.technician_earnings_cents,
          currency: "usd",
          destination: techProfile.stripe_account_id,
          transfer_group: job_id,
        })

        await supabase.from("jobs").update({ stripe_transfer_id: transfer.id }).eq("id", job_id)
      }
    }

    // Update job to completed
    const { data: updatedJob, error: updateError } = await supabase
      .from("jobs")
      .update({
        status: "completed",
        completed_at: new Date().toISOString(),
      })
      .eq("id", job_id)
      .select()
      .single()

    if (updateError) {
      console.error("[v0] Job complete error:", updateError)
      return NextResponse.json({ error: "Failed to complete job" }, { status: 500 })
    }

    // Create notification for customer
    await supabase.from("notifications").insert({
      user_id: job.customer_id,
      title: "Job Completed",
      body: "Your oil change has been completed!",
      type: "job_completed",
      data: { job_id: job.id },
    })

    return NextResponse.json({ job: updatedJob })
  } catch (error) {
    console.error("[v0] Error completing job:", error)
    return NextResponse.json({ error: "Internal server error" }, { status: 500 })
  }
}
