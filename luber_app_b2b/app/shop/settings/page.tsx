import { redirect } from "next/navigation"
import { createServerClient } from "@/lib/supabase/server"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import ShopNav from "@/components/shop/shop-nav"
import { SUBSCRIPTION_PLANS } from "@/lib/stripe"

export default async function SettingsPage() {
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

  const currentPlan = SUBSCRIPTION_PLANS.find((p) => p.tier === shop.subscription_tier)

  return (
    <div className="min-h-screen bg-muted/50">
      <ShopNav shop={shop} />

      <div className="container py-8 max-w-4xl">
        <div className="mb-8">
          <h1 className="text-3xl font-bold mb-2">Settings</h1>
          <p className="text-muted-foreground">Manage your shop settings and subscription</p>
        </div>

        <div className="space-y-6">
          {/* Business Information */}
          <Card>
            <CardHeader>
              <CardTitle>Business Information</CardTitle>
              <CardDescription>Your registered business details</CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="grid md:grid-cols-2 gap-4">
                <div>
                  <p className="text-sm font-medium text-muted-foreground">Shop Name</p>
                  <p className="text-sm">{shop.shop_name}</p>
                </div>
                <div>
                  <p className="text-sm font-medium text-muted-foreground">Legal Name</p>
                  <p className="text-sm">{shop.business_legal_name}</p>
                </div>
                <div>
                  <p className="text-sm font-medium text-muted-foreground">License Number</p>
                  <p className="text-sm">{shop.business_license_number}</p>
                </div>
                <div>
                  <p className="text-sm font-medium text-muted-foreground">Insurance Policy</p>
                  <p className="text-sm">{shop.insurance_policy_number}</p>
                </div>
              </div>
            </CardContent>
          </Card>

          {/* Subscription */}
          <Card>
            <CardHeader>
              <CardTitle>Subscription</CardTitle>
              <CardDescription>Your current plan and billing information</CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              <div>
                <p className="text-sm font-medium text-muted-foreground mb-1">Current Plan</p>
                <p className="text-lg font-semibold">{currentPlan?.name}</p>
                <p className="text-sm text-muted-foreground">{currentPlan?.description}</p>
              </div>
              <div>
                <p className="text-sm font-medium text-muted-foreground mb-1">Status</p>
                <span
                  className={`inline-flex items-center rounded-full px-2 py-1 text-xs font-medium ${
                    shop.subscription_status === "active"
                      ? "bg-green-50 text-green-700 dark:bg-green-900/30 dark:text-green-400"
                      : shop.subscription_status === "trialing"
                        ? "bg-blue-50 text-blue-700 dark:bg-blue-900/30 dark:text-blue-400"
                        : "bg-red-50 text-red-700 dark:bg-red-900/30 dark:text-red-400"
                  }`}
                >
                  {shop.subscription_status}
                </span>
              </div>
              {shop.trial_ends_at && (
                <div>
                  <p className="text-sm font-medium text-muted-foreground mb-1">Trial Ends</p>
                  <p className="text-sm">{new Date(shop.trial_ends_at).toLocaleDateString()}</p>
                </div>
              )}
            </CardContent>
          </Card>

          {/* Branding */}
          <Card>
            <CardHeader>
              <CardTitle>Branding</CardTitle>
              <CardDescription>Customize your shop's appearance</CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="grid md:grid-cols-2 gap-4">
                <div>
                  <p className="text-sm font-medium text-muted-foreground mb-1">Primary Color</p>
                  <div className="flex items-center gap-2">
                    <div className="h-8 w-8 rounded border" style={{ backgroundColor: shop.primary_color }} />
                    <p className="text-sm">{shop.primary_color}</p>
                  </div>
                </div>
                <div>
                  <p className="text-sm font-medium text-muted-foreground mb-1">Secondary Color</p>
                  <div className="flex items-center gap-2">
                    <div className="h-8 w-8 rounded border" style={{ backgroundColor: shop.secondary_color }} />
                    <p className="text-sm">{shop.secondary_color}</p>
                  </div>
                </div>
              </div>
            </CardContent>
          </Card>
        </div>
      </div>
    </div>
  )
}
