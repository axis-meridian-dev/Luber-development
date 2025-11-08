import { redirect } from "next/navigation"
import { createServerClient } from "@/lib/supabase/server"
import OnboardingWizard from "@/components/onboarding/onboarding-wizard"

export default async function OnboardingPage() {
  const supabase = await createServerClient()

  const {
    data: { user },
  } = await supabase.auth.getUser()

  if (!user) {
    redirect("/auth/login")
  }

  // Check if shop already exists
  const { data: shop } = await supabase.from("shops").select("*").eq("owner_id", user.id).single()

  // If shop exists and onboarding is complete, redirect to dashboard
  if (shop?.onboarding_completed) {
    redirect("/shop/dashboard")
  }

  return (
    <div className="min-h-screen bg-muted/50">
      <OnboardingWizard existingShop={shop} />
    </div>
  )
}
