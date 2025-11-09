import { type NextRequest, NextResponse } from "next/server"
import { createClient } from "@/lib/supabase/server"

// PATCH /api/vehicles/[id] - Update vehicle
export async function PATCH(request: NextRequest, { params }: { params: { id: string } }) {
  try {
    const supabase = await createClient()

    const {
      data: { user },
      error: authError,
    } = await supabase.auth.getUser()
    if (authError || !user) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 })
    }

    const vehicleId = params.id
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

    // Verify vehicle belongs to user
    const { data: existingVehicle } = await supabase
      .from("vehicles")
      .select("id")
      .eq("id", vehicleId)
      .eq("user_id", user.id)
      .single()

    if (!existingVehicle) {
      return NextResponse.json({ error: "Vehicle not found" }, { status: 404 })
    }

    // If setting as default, unset other defaults first
    if (is_default) {
      await supabase
        .from("vehicles")
        .update({ is_default: false })
        .eq("user_id", user.id)
        .neq("id", vehicleId)
    }

    // Update the vehicle
    const { data: vehicle, error } = await supabase
      .from("vehicles")
      .update({
        make,
        model,
        year,
        vehicle_type,
        oil_capacity,
        recommended_oil_type,
        license_plate,
        vin,
        is_default,
      })
      .eq("id", vehicleId)
      .select()
      .single()

    if (error) {
      console.error("[v0] Error updating vehicle:", error)
      return NextResponse.json({ error: "Failed to update vehicle" }, { status: 500 })
    }

    return NextResponse.json({ vehicle })
  } catch (error) {
    console.error("[v0] Error in vehicles PATCH:", error)
    return NextResponse.json({ error: "Internal server error" }, { status: 500 })
  }
}

// DELETE /api/vehicles/[id] - Delete vehicle
export async function DELETE(request: NextRequest, { params }: { params: { id: string } }) {
  try {
    const supabase = await createClient()

    const {
      data: { user },
      error: authError,
    } = await supabase.auth.getUser()
    if (authError || !user) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 })
    }

    const vehicleId = params.id

    // Check if vehicle has any associated jobs
    const { data: jobs } = await supabase
      .from("jobs")
      .select("id")
      .eq("vehicle_id", vehicleId)
      .limit(1)

    if (jobs && jobs.length > 0) {
      return NextResponse.json(
        { error: "Cannot delete vehicle with associated jobs" },
        { status: 400 }
      )
    }

    // Delete the vehicle
    const { error } = await supabase
      .from("vehicles")
      .delete()
      .eq("id", vehicleId)
      .eq("user_id", user.id)

    if (error) {
      console.error("[v0] Error deleting vehicle:", error)
      return NextResponse.json({ error: "Failed to delete vehicle" }, { status: 500 })
    }

    return NextResponse.json({ success: true })
  } catch (error) {
    console.error("[v0] Error in vehicles DELETE:", error)
    return NextResponse.json({ error: "Internal server error" }, { status: 500 })
  }
}
