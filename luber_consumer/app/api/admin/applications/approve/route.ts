import { type NextRequest, NextResponse } from "next/server"
import { createClient } from "@/lib/supabase/server"

export async function POST(request: NextRequest) {
  try {
    const supabase = await createClient()

    const {
      data: { user },
      error: authError,
    } = await supabase.auth.getUser()
    if (authError || !user || user.user_metadata?.role !== "admin") {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 })
    }

    const body = await request.json()
    const { technician_id } = body

    if (!technician_id) {
      return NextResponse.json({ error: "Technician ID required" }, { status: 400 })
    }

    const { error } = await supabase
      .from("technician_profiles")
      .update({
        application_status: "approved",
        approved_at: new Date().toISOString(),
      })
      .eq("id", technician_id)

    if (error) {
      console.error("[v0] Approval error:", error)
      return NextResponse.json({ error: "Failed to approve application" }, { status: 500 })
    }

    // Create notification for technician
    await supabase.from("notifications").insert({
      user_id: technician_id,
      title: "Application Approved",
      body: "Your technician application has been approved!",
      type: "application_approved",
    })

    return NextResponse.json({ success: true })
  } catch (error) {
    console.error("[v0] Error approving application:", error)
    return NextResponse.json({ error: "Internal server error" }, { status: 500 })
  }
}
