import { type NextRequest, NextResponse } from "next/server"
import { createClient } from "@/lib/supabase/server"

// PATCH /api/addresses/[id] - Update address
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

    const addressId = params.id
    const body = await request.json()
    const {
      label,
      street_address,
      city,
      state,
      zip_code,
      latitude,
      longitude,
      is_default,
    } = body

    // Verify address belongs to user
    const { data: existingAddress } = await supabase
      .from("addresses")
      .select("id")
      .eq("id", addressId)
      .eq("user_id", user.id)
      .single()

    if (!existingAddress) {
      return NextResponse.json({ error: "Address not found" }, { status: 404 })
    }

    // If setting as default, unset other defaults first
    if (is_default) {
      await supabase
        .from("addresses")
        .update({ is_default: false })
        .eq("user_id", user.id)
        .neq("id", addressId)
    }

    // Update the address
    const { data: address, error } = await supabase
      .from("addresses")
      .update({
        label,
        street_address,
        city,
        state,
        zip_code,
        latitude,
        longitude,
        is_default,
      })
      .eq("id", addressId)
      .select()
      .single()

    if (error) {
      console.error("[v0] Error updating address:", error)
      return NextResponse.json({ error: "Failed to update address" }, { status: 500 })
    }

    return NextResponse.json({ address })
  } catch (error) {
    console.error("[v0] Error in addresses PATCH:", error)
    return NextResponse.json({ error: "Internal server error" }, { status: 500 })
  }
}

// DELETE /api/addresses/[id] - Delete address
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

    const addressId = params.id

    // Check if address has any associated jobs
    const { data: jobs } = await supabase
      .from("jobs")
      .select("id")
      .eq("address_id", addressId)
      .limit(1)

    if (jobs && jobs.length > 0) {
      return NextResponse.json(
        { error: "Cannot delete address with associated jobs" },
        { status: 400 }
      )
    }

    // Delete the address
    const { error } = await supabase
      .from("addresses")
      .delete()
      .eq("id", addressId)
      .eq("user_id", user.id)

    if (error) {
      console.error("[v0] Error deleting address:", error)
      return NextResponse.json({ error: "Failed to delete address" }, { status: 500 })
    }

    return NextResponse.json({ success: true })
  } catch (error) {
    console.error("[v0] Error in addresses DELETE:", error)
    return NextResponse.json({ error: "Internal server error" }, { status: 500 })
  }
}
