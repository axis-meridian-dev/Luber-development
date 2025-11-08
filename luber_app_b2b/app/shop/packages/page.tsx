import { redirect } from "next/navigation"
import { createServerClient } from "@/lib/supabase/server"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Plus, Package } from "lucide-react"
import Link from "next/link"
import ShopNav from "@/components/shop/shop-nav"

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
              <Card key={pkg.id}>
                <CardHeader>
                  <CardTitle className="flex items-center justify-between">
                    <span>{pkg.package_name}</span>
                    <span
                      className={`inline-flex items-center rounded-full px-2 py-1 text-xs font-medium ${
                        pkg.is_active
                          ? "bg-green-50 text-green-700 dark:bg-green-900/30 dark:text-green-400"
                          : "bg-gray-50 text-gray-700 dark:bg-gray-900/30 dark:text-gray-400"
                      }`}
                    >
                      {pkg.is_active ? "Active" : "Inactive"}
                    </span>
                  </CardTitle>
                </CardHeader>
                <CardContent>
                  <div className="space-y-3">
                    <div>
                      <div className="text-3xl font-bold text-primary">${pkg.price}</div>
                      <p className="text-sm text-muted-foreground">{pkg.estimated_duration_minutes} minutes</p>
                    </div>
                    {pkg.description && <p className="text-sm text-muted-foreground">{pkg.description}</p>}
                    <div className="space-y-1 text-sm">
                      {pkg.oil_brand && (
                        <div>
                          <span className="text-muted-foreground">Oil Brand:</span>{" "}
                          <span className="font-medium">{pkg.oil_brand}</span>
                        </div>
                      )}
                      {pkg.oil_type && (
                        <div>
                          <span className="text-muted-foreground">Oil Type:</span>{" "}
                          <span className="font-medium capitalize">{pkg.oil_type}</span>
                        </div>
                      )}
                      <div>
                        <span className="text-muted-foreground">Includes Filter:</span>{" "}
                        <span className="font-medium">{pkg.includes_filter ? "Yes" : "No"}</span>
                      </div>
                      <div>
                        <span className="text-muted-foreground">Includes Inspection:</span>{" "}
                        <span className="font-medium">{pkg.includes_inspection ? "Yes" : "No"}</span>
                      </div>
                    </div>
                  </div>
                </CardContent>
              </Card>
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
