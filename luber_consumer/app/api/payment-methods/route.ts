import { NextResponse } from "next/server"
import { createClient } from "@/lib/supabase/server"

// GET /api/payment-methods - list authenticated user's payment methods
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

    const { data: paymentMethods, error } = await supabase
      .from("payment_methods")
      .select("*")
      .eq("user_id", user.id)
      .order("is_default", { ascending: false })
      .order("created_at", { ascending: false })

    if (error) {
      console.error("Error fetching payment methods:", error)
      return NextResponse.json({ error: "Failed to fetch payment methods" }, { status: 500 })
    }

    return NextResponse.json({ paymentMethods })
  } catch (error) {
    console.error("Error in payment methods GET:", error)
    return NextResponse.json({ error: "Internal server error" }, { status: 500 })
  }
}
