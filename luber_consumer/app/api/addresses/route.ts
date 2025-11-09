import { type NextRequest, NextResponse } from "next/server"
import { createClient } from "@/lib/supabase/server"

// GET /api/addresses - Get all addresses for current user
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

    const { data: addresses, error } = await supabase
      .from("addresses")
      .select("*")
      .eq("user_id", user.id)
      .order("is_default", { ascending: false })
      .order("created_at", { ascending: false })

    if (error) {
      console.error("[v0] Error fetching addresses:", error)
      return NextResponse.json({ error: "Failed to fetch addresses" }, { status: 500 })
    }

    return NextResponse.json({ addresses })
  } catch (error) {
    console.error("[v0] Error in addresses GET:", error)
    return NextResponse.json({ error: "Internal server error" }, { status: 500 })
  }
}

// POST /api/addresses - Create new address
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
      label,
      street_address,
      city,
      state,
      zip_code,
      latitude,
      longitude,
      is_default,
    } = body

    // Validate required fields
    if (!label || !street_address || !city || !state || !zip_code) {
      return NextResponse.json(
        { error: "Missing required fields: label, street_address, city, state, zip_code" },
        { status: 400 }
      )
    }

    // If this is being set as default, unset other defaults first
    if (is_default) {
      await supabase
        .from("addresses")
        .update({ is_default: false })
        .eq("user_id", user.id)
    }

    // Create the address
    const { data: address, error } = await supabase
      .from("addresses")
      .insert({
        user_id: user.id,
        label,
        street_address,
        city,
        state,
        zip_code,
        latitude,
        longitude,
        is_default: is_default || false,
      })
      .select()
      .single()

    if (error) {
      console.error("[v0] Error creating address:", error)
      return NextResponse.json({ error: "Failed to create address" }, { status: 500 })
    }

    return NextResponse.json({ address }, { status: 201 })
  } catch (error) {
    console.error("[v0] Error in addresses POST:", error)
    return NextResponse.json({ error: "Internal server error" }, { status: 500 })
  }
}
