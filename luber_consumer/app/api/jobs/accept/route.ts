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

    // Update job to accepted
    const { data: job, error: updateError } = await supabase
      .from("jobs")
      .update({
        technician_id: user.id,
        status: "accepted",
        accepted_at: new Date().toISOString(),
      })
      .eq("id", job_id)
      .eq("status", "pending")
      .select()
      .single()

    if (updateError) {
      console.error("[v0] Job accept error:", updateError)
      return NextResponse.json({ error: "Failed to accept job" }, { status: 500 })
    }

    // Create notification for customer
    await supabase.from("notifications").insert({
      user_id: job.customer_id,
      title: "Technician Accepted Your Job",
      body: "A technician has accepted your oil change request.",
      type: "job_accepted",
      data: { job_id: job.id },
    })

    return NextResponse.json({ job })
  } catch (error) {
    console.error("[v0] Error accepting job:", error)
    return NextResponse.json({ error: "Internal server error" }, { status: 500 })
  }
}
