import { redirect } from "next/navigation"
import { createServerClient } from "@/lib/supabase/server"
import { Button } from "@/components/ui/button"
import { Card, CardContent } from "@/components/ui/card"
import { Plus, Package } from "lucide-react"
import Link from "next/link"
import ShopNav from "@/components/shop/shop-nav"
import PackageCard from "@/components/shop/package-card"

export default async function PackagesPage() {
  const supabase = await createServerClient()

  const {
    data: { user },
  } = await supabase.auth.getUser()

  if (!user) {
    redirect("/auth/login")
  }

  const { data: shop } = await supabase.from("shops").select("*").eq("owner_id", user.id).single()

  if (!shop) {
    redirect("/onboarding")
  }

  const { data: packages } = await supabase
    .from("shop_service_packages")
    .select("*")
    .eq("shop_id", shop.id)
    .order("created_at", { ascending: false })

  return (
    <div className="min-h-screen bg-muted/50">
      <ShopNav shop={shop} />

      <div className="container py-8">
        <div className="flex items-center justify-between mb-8">
          <div>
            <h1 className="text-3xl font-bold mb-2">Service Packages</h1>
            <p className="text-muted-foreground">Create custom pricing packages for your services</p>
          </div>
          <Link href="/shop/packages/add">
            <Button>
              <Plus className="h-4 w-4 mr-2" />
              Add Package
            </Button>
          </Link>
        </div>

        {packages && packages.length > 0 ? (
          <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-3">
            {packages.map((pkg) => (
              <PackageCard key={pkg.id} packageData={pkg} />
            ))}
          </div>
        ) : (
          <Card>
            <CardContent className="flex flex-col items-center justify-center py-12">
              <Package className="h-12 w-12 text-muted-foreground mb-4" />
              <h3 className="text-lg font-semibold mb-2">No service packages yet</h3>
              <p className="text-sm text-muted-foreground mb-4">Create your first package to start offering services</p>
              <Link href="/shop/packages/add">
                <Button>
                  <Plus className="h-4 w-4 mr-2" />
                  Add Package
                </Button>
              </Link>
            </CardContent>
          </Card>
        )}
      </div>
    </div>
  )
}
