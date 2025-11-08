"use server"

import { createServerClient } from "@/lib/supabase/server"
import { revalidatePath } from "next/cache"

export async function assignJobToTechnician(bookingId: string, technicianId: string, shopId: string) {
  try {
    const supabase = await createServerClient()

    const {
      data: { user },
    } = await supabase.auth.getUser()
    if (!user) {
      return { success: false, error: "Not authenticated" }
    }

    // Verify shop ownership
    const { data: shop } = await supabase.from("shops").select("id").eq("id", shopId).eq("owner_id", user.id).single()

    if (!shop) {
      return { success: false, error: "Unauthorized" }
    }

    // Update booking with technician
    const { error: bookingError } = await supabase
      .from("bookings")
      .update({
        shop_technician_id: technicianId,
        status: "confirmed",
        updated_at: new Date().toISOString(),
      })
      .eq("id", bookingId)

    if (bookingError) throw bookingError

    // Create job assignment record
    const { error: assignmentError } = await supabase.from("job_assignments").insert({
      booking_id: bookingId,
      shop_id: shopId,
      assigned_to: technicianId,
      assigned_by: user.id,
      assignment_type: "manual",
      status: "assigned",
    })

    if (assignmentError) throw assignmentError

    revalidatePath("/shop/dispatch")
    return { success: true }
  } catch (error: any) {
    console.error("[v0] Error assigning job:", error)
    return { success: false, error: error.message }
  }
}

export async function reassignJob(bookingId: string, newTechnicianId: string, shopId: string) {
  try {
    const supabase = await createServerClient()

    const {
      data: { user },
    } = await supabase.auth.getUser()
    if (!user) {
      return { success: false, error: "Not authenticated" }
    }

    // Verify shop ownership
    const { data: shop } = await supabase.from("shops").select("id").eq("id", shopId).eq("owner_id", user.id).single()

    if (!shop) {
      return { success: false, error: "Unauthorized" }
    }

    // Update existing assignment to reassigned
    const { error: updateError } = await supabase
      .from("job_assignments")
      .update({ status: "reassigned" })
      .eq("booking_id", bookingId)

    if (updateError) throw updateError

    // Update booking with new technician
    const { error: bookingError } = await supabase
      .from("bookings")
      .update({
        shop_technician_id: newTechnicianId,
        updated_at: new Date().toISOString(),
      })
      .eq("id", bookingId)

    if (bookingError) throw bookingError

    // Create new assignment record
    const { error: assignmentError } = await supabase.from("job_assignments").insert({
      booking_id: bookingId,
      shop_id: shopId,
      assigned_to: newTechnicianId,
      assigned_by: user.id,
      assignment_type: "manual",
      status: "assigned",
    })

    if (assignmentError) throw assignmentError

    revalidatePath("/shop/dispatch")
    return { success: true }
  } catch (error: any) {
    console.error("[v0] Error reassigning job:", error)
    return { success: false, error: error.message }
  }
}

export async function autoAssignJob(bookingId: string, shopId: string) {
  try {
    const supabase = await createServerClient()

    // Find available technician with lowest current workload
    const { data: technicians } = await supabase
      .from("shop_technicians")
      .select(`
        id,
        total_jobs,
        bookings:bookings(count)
      `)
      .eq("shop_id", shopId)
      .eq("is_available", true)
      .order("total_jobs", { ascending: true })
      .limit(1)

    if (!technicians || technicians.length === 0) {
      return { success: false, error: "No available technicians" }
    }

    const selectedTechnician = technicians[0]

    // Assign the job
    const { error: bookingError } = await supabase
      .from("bookings")
      .update({
        shop_technician_id: selectedTechnician.id,
        status: "confirmed",
        updated_at: new Date().toISOString(),
      })
      .eq("id", bookingId)

    if (bookingError) throw bookingError

    // Create assignment record
    const { error: assignmentError } = await supabase.from("job_assignments").insert({
      booking_id: bookingId,
      shop_id: shopId,
      assigned_to: selectedTechnician.id,
      assignment_type: "auto",
      status: "assigned",
    })

    if (assignmentError) throw assignmentError

    return { success: true, technicianId: selectedTechnician.id }
  } catch (error: any) {
    console.error("[v0] Error auto-assigning job:", error)
    return { success: false, error: error.message }
  }
}
