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
    const { technician_id, reason } = body

    if (!technician_id || !reason) {
      return NextResponse.json({ error: "Technician ID and reason required" }, { status: 400 })
    }

    const { error } = await supabase
      .from("technician_profiles")
      .update({
        application_status: "rejected",
        rejected_at: new Date().toISOString(),
        rejection_reason: reason,
      })
      .eq("id", technician_id)

    if (error) {
      console.error("[v0] Rejection error:", error)
      return NextResponse.json({ error: "Failed to reject application" }, { status: 500 })
    }

    // Create notification for technician
    await supabase.from("notifications").insert({
      user_id: technician_id,
      title: "Application Not Approved",
      body: `Unfortunately, your application was not approved. Reason: ${reason}`,
      type: "application_rejected",
      data: { reason },
    })

    return NextResponse.json({ success: true })
  } catch (error) {
    console.error("[v0] Error rejecting application:", error)
    return NextResponse.json({ error: "Internal server error" }, { status: 500 })
  }
}
