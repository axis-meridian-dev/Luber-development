import { type NextRequest, NextResponse } from "next/server"
import { createClient } from "@/lib/supabase/server"

// GET /api/vehicles - Get all vehicles for current user
export async function GET() {
  try {
    const supabase = await createClient()

    const {
      data: { user },
      error: authError,
    } = await supabase.auth.getUser()
    if (authError || !user) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 })
    }

    const { data: vehicles, error } = await supabase
      .from("vehicles")
      .select("*")
      .eq("user_id", user.id)
      .order("is_default", { ascending: false })
      .order("created_at", { ascending: false })

    if (error) {
      console.error("[v0] Error fetching vehicles:", error)
      return NextResponse.json({ error: "Failed to fetch vehicles" }, { status: 500 })
    }

    return NextResponse.json({ vehicles })
  } catch (error) {
    console.error("[v0] Error in vehicles GET:", error)
    return NextResponse.json({ error: "Internal server error" }, { status: 500 })
  }
}

// POST /api/vehicles - Create new vehicle
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
    const {
      make,
      model,
      year,
      vehicle_type,
      oil_capacity,
      recommended_oil_type,
      license_plate,
      vin,
      is_default,
    } = body

    // Validate required fields
    if (!make || !model || !year || !vehicle_type || !recommended_oil_type) {
      return NextResponse.json(
        { error: "Missing required fields: make, model, year, vehicle_type, recommended_oil_type" },
        { status: 400 }
      )
    }

    // If this is being set as default, unset other defaults first
    if (is_default) {
      await supabase
        .from("vehicles")
        .update({ is_default: false })
        .eq("user_id", user.id)
    }

    // Create the vehicle
    const { data: vehicle, error } = await supabase
      .from("vehicles")
      .insert({
        user_id: user.id,
        make,
        model,
        year,
        vehicle_type,
        oil_capacity,
        recommended_oil_type,
        license_plate,
        vin,
        is_default: is_default || false,
      })
      .select()
      .single()

    if (error) {
      console.error("[v0] Error creating vehicle:", error)
      return NextResponse.json({ error: "Failed to create vehicle" }, { status: 500 })
    }

    return NextResponse.json({ vehicle }, { status: 201 })
  } catch (error) {
    console.error("[v0] Error in vehicles POST:", error)
    return NextResponse.json({ error: "Internal server error" }, { status: 500 })
  }
}
