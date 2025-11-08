import { type NextRequest, NextResponse } from "next/server"
import { createClient } from "@/lib/supabase/server"

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
    const { job_id, rating, comment } = body

    if (!job_id || !rating) {
      return NextResponse.json({ error: "Job ID and rating required" }, { status: 400 })
    }

    if (rating < 1 || rating > 5) {
      return NextResponse.json({ error: "Rating must be between 1 and 5" }, { status: 400 })
    }

    // Get job details
    const { data: job, error: jobError } = await supabase
      .from("jobs")
      .select("customer_id, technician_id, status")
      .eq("id", job_id)
      .single()

    if (jobError || !job) {
      return NextResponse.json({ error: "Job not found" }, { status: 404 })
    }

    if (job.customer_id !== user.id) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 403 })
    }

    if (job.status !== "completed") {
      return NextResponse.json({ error: "Can only review completed jobs" }, { status: 400 })
    }

    // Create review
    const { data: review, error: reviewError } = await supabase
      .from("reviews")
      .insert({
        job_id,
        customer_id: user.id,
        technician_id: job.technician_id!,
        rating,
        comment,
      })
      .select()
      .single()

    if (reviewError) {
      console.error("[v0] Review creation error:", reviewError)
      return NextResponse.json({ error: "Failed to create review" }, { status: 500 })
    }

    return NextResponse.json({ review })
  } catch (error) {
    console.error("[v0] Error creating review:", error)
    return NextResponse.json({ error: "Internal server error" }, { status: 500 })
  }
}
