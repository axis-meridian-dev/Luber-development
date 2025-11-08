import { type NextRequest, NextResponse } from "next/server"
import { createClient } from "@/lib/supabase/server"
import { findAvailableTechnicians } from "@/lib/job-matching"

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
    const { address_id, scheduled_time } = body

    if (!address_id || !scheduled_time) {
      return NextResponse.json({ error: "Address and scheduled time required" }, { status: 400 })
    }

    // Get address coordinates
    const { data: address, error: addressError } = await supabase
      .from("addresses")
      .select("latitude, longitude")
      .eq("id", address_id)
      .eq("user_id", user.id)
      .single()

    if (addressError || !address || !address.latitude || !address.longitude) {
      return NextResponse.json({ error: "Address not found or missing coordinates" }, { status: 404 })
    }

    // Find available technicians
    const technicians = await findAvailableTechnicians({
      latitude: address.latitude,
      longitude: address.longitude,
      scheduled_time,
    })

    return NextResponse.json({ technicians })
  } catch (error) {
    console.error("[v0] Error finding technicians:", error)
    return NextResponse.json({ error: "Internal server error" }, { status: 500 })
  }
}
