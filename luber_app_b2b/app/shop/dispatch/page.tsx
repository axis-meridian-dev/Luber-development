import { createServerClient } from "@/lib/supabase/server"
import { redirect } from "next/navigation"
import { DispatchBoard } from "@/components/shop/dispatch-board"

export default async function DispatchPage() {
  const supabase = await createServerClient()

  const {
    data: { user },
  } = await supabase.auth.getUser()
  if (!user) redirect("/auth/login")

  // Get shop for current user
  const { data: shop } = await supabase.from("shops").select("*").eq("owner_id", user.id).single()

  if (!shop) redirect("/onboarding")

  // Get all available technicians
  const { data: technicians } = await supabase
    .from("shop_technicians")
    .select(`
      *,
      profiles:profile_id (
        full_name,
        email,
        phone
      ),
      time_tracking:technician_time_tracking (
        status,
        clock_in_time
      )
    `)
    .eq("shop_id", shop.id)
    .order("is_available", { ascending: false })

  // Get unassigned bookings
  const { data: unassignedBookings } = await supabase
    .from("bookings")
    .select(`
      *,
      customer:customer_id (
        full_name,
        phone
      ),
      vehicle:vehicle_id (
        make,
        model,
        year
      )
    `)
    .eq("shop_id", shop.id)
    .is("shop_technician_id", null)
    .in("status", ["pending", "confirmed"])
    .order("scheduled_time", { ascending: true })

  // Get assigned bookings with assignments
  const { data: assignedBookings } = await supabase
    .from("bookings")
    .select(`
      *,
      customer:customer_id (
        full_name,
        phone
      ),
      vehicle:vehicle_id (
        make,
        model,
        year
      ),
      assignment:job_assignments (
        *,
        technician:assigned_to (
          *,
          profile:profile_id (
            full_name
          )
        )
      )
    `)
    .eq("shop_id", shop.id)
    .not("shop_technician_id", "is", null)
    .in("status", ["confirmed", "in_progress"])
    .order("scheduled_time", { ascending: true })

  return (
    <div className="min-h-screen bg-background">
      <div className="container mx-auto p-6">
        <div className="mb-6">
          <h1 className="text-3xl font-bold">Dispatch Board</h1>
          <p className="text-muted-foreground">Assign jobs to your technicians</p>
        </div>

        <DispatchBoard
          shop={shop}
          technicians={technicians || []}
          unassignedBookings={unassignedBookings || []}
          assignedBookings={assignedBookings || []}
        />
      </div>
    </div>
  )
}
