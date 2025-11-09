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
    const { job_id } = body

    if (!job_id) {
      return NextResponse.json({ error: "Job ID required" }, { status: 400 })
    }

    // Verify user is a technician
    const { data: profile } = await supabase.from("profiles").select("role").eq("id", user.id).single()

    if (profile?.role !== "technician") {
      return NextResponse.json({ error: "Unauthorized" }, { status: 403 })
    }

    // Get job to verify it belongs to this technician and is in accepted status
    const { data: existingJob } = await supabase
      .from("jobs")
      .select("customer_id, status")
      .eq("id", job_id)
      .eq("technician_id", user.id)
      .eq("status", "accepted")
      .single()

    if (!existingJob) {
      return NextResponse.json(
        { error: "Job not found or already started" },
        { status: 404 }
      )
    }

    // Update job to in_progress
    const { data: job, error: updateError } = await supabase
      .from("jobs")
      .update({
        status: "in_progress",
        started_at: new Date().toISOString(),
      })
      .eq("id", job_id)
      .select()
      .single()

    if (updateError) {
      console.error("[v0] Job start error:", updateError)
      return NextResponse.json({ error: "Failed to start job" }, { status: 500 })
    }

    // Create notification for customer
    await supabase.from("notifications").insert({
      user_id: existingJob.customer_id,
      title: "Technician Started Your Job",
      body: "Your technician is on the way!",
      type: "job_started",
      data: { job_id: job.id },
    })

    return NextResponse.json({ job })
  } catch (error) {
    console.error("[v0] Error starting job:", error)
    return NextResponse.json({ error: "Internal server error" }, { status: 500 })
  }
}
