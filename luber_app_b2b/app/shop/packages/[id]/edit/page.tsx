import { redirect } from "next/navigation"
import { createServerClient } from "@/lib/supabase/server"
import EditPackageForm from "@/components/shop/edit-package-form"
import ShopNav from "@/components/shop/shop-nav"

export default async function EditPackagePage({ params }: { params: { id: string } }) {
  const supabase = await createServerClient()

  const {
    data: { user },
  } = await supabase.auth.getUser()

  if (!user) {
    redirect("/auth/login")
  }

  // Get shop owned by user
  const { data: shop } = await supabase.from("shops").select("*").eq("owner_id", user.id).single()

  if (!shop) {
    redirect("/onboarding")
  }

  // Get package owned by shop
  const { data: packageData, error } = await supabase
    .from("shop_service_packages")
    .select("*")
    .eq("id", params.id)
    .eq("shop_id", shop.id)
    .single()

  if (error || !packageData) {
    redirect("/shop/packages")
  }

  return (
    <div className="min-h-screen bg-muted/50">
      <ShopNav shop={shop} />
      <EditPackageForm packageData={packageData} shopId={shop.id} />
    </div>
  )
}
