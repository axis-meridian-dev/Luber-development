import { redirect } from "next/navigation"
import { createServerClient } from "@/lib/supabase/server"
import SubscriptionCheckout from "@/components/subscription/subscription-checkout"

export default async function SubscriptionCheckoutPage() {
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

  if (shop.subscription_status === "active") {
    redirect("/shop/dashboard")
  }

  return (
    <div className="min-h-screen bg-muted/50 py-12">
      <div className="container max-w-2xl">
        <SubscriptionCheckout shop={shop} />
      </div>
    </div>
  )
}
