import { redirect } from "next/navigation"
import { createServerClient } from "@/lib/supabase/server"
import EditTechnicianForm from "@/components/shop/edit-technician-form"
import { Button } from "@/components/ui/button"
import { ArrowLeft } from "lucide-react"
import Link from "next/link"

interface EditTechnicianPageProps {
  params: Promise<{ id: string }>
}

export default async function EditTechnicianPage({ params }: EditTechnicianPageProps) {
  const { id } = await params
  const supabase = await createServerClient()

  const {
    data: { user },
  } = await supabase.auth.getUser()

  if (!user) {
    redirect("/auth/login")
  }

  // Get the shop owned by this user
  const { data: shop, error: shopError } = await supabase
    .from("shops")
    .select("*")
    .eq("owner_id", user.id)
    .single()

  if (shopError || !shop) {
    redirect("/onboarding")
  }

  // Get the technician and verify they belong to this shop
  const { data: technician, error: techError } = await supabase
    .from("shop_technicians")
    .select(
      `
      *,
      profiles (
        id,
        email,
        full_name,
        phone
      )
    `
    )
    .eq("id", id)
    .single()

  if (techError || !technician) {
    redirect("/shop/technicians")
  }

  // Verify technician belongs to this shop
  if (technician.shop_id !== shop.id) {
    redirect("/shop/technicians")
  }

  return (
    <div className="container max-w-3xl py-8">
      <div className="mb-6">
        <Link href="/shop/technicians">
          <Button variant="ghost" size="sm">
            <ArrowLeft className="h-4 w-4 mr-2" />
            Back to Technicians
          </Button>
        </Link>
      </div>

      <EditTechnicianForm technician={technician} shop={shop} />
    </div>
  )
}
