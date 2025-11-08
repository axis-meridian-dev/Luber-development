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
    const { is_available } = body

    if (typeof is_available !== "boolean") {
      return NextResponse.json({ error: "is_available must be boolean" }, { status: 400 })
    }

    // Update technician availability
    const { data, error } = await supabase
      .from("technician_profiles")
      .update({ is_available })
      .eq("id", user.id)
      .select()
      .single()

    if (error) {
      console.error("[v0] Availability update error:", error)
      return NextResponse.json({ error: "Failed to update availability" }, { status: 500 })
    }

    return NextResponse.json({ technician: data })
  } catch (error) {
    console.error("[v0] Error updating availability:", error)
    return NextResponse.json({ error: "Internal server error" }, { status: 500 })
  }
}
