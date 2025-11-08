import { createClient } from "@/lib/supabase/server"
import { redirect } from "next/navigation"
import { CustomerDashboard } from "@/components/customer/customer-dashboard"

export default async function HomePage() {
  const supabase = await createClient()

  const {
    data: { user },
  } = await supabase.auth.getUser()

  if (!user) {
    redirect("/auth/login")
  }

  // Get user profile to check role
  const { data: profile } = await supabase.from("profiles").select("role").eq("id", user.id).single()

  // Redirect admins to admin dashboard
  if (profile?.role === "admin") {
    redirect("/admin")
  }

  // Redirect technicians to technician dashboard
  if (profile?.role === "technician") {
    redirect("/technician")
  }

  return <CustomerDashboard />
}
