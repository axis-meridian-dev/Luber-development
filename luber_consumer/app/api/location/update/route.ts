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
    const { latitude, longitude, heading, speed } = body

    if (!latitude || !longitude) {
      return NextResponse.json({ error: "Location required" }, { status: 400 })
    }

    // Verify user is a technician
    const { data: profile } = await supabase.from("profiles").select("role").eq("id", user.id).single()

    if (profile?.role !== "technician") {
      return NextResponse.json({ error: "Unauthorized" }, { status: 403 })
    }

    // Upsert location
    const { data, error } = await supabase
      .from("technician_locations")
      .upsert({
        technician_id: user.id,
        latitude,
        longitude,
        heading,
        speed,
        updated_at: new Date().toISOString(),
      })
      .select()
      .single()

    if (error) {
      console.error("[v0] Location update error:", error)
      return NextResponse.json({ error: "Failed to update location" }, { status: 500 })
    }

    return NextResponse.json({ location: data })
  } catch (error) {
    console.error("[v0] Error updating location:", error)
    return NextResponse.json({ error: "Internal server error" }, { status: 500 })
  }
}
