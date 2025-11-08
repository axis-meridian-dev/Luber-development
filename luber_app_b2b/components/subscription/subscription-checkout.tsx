"use client"

import { useCallback } from "react"
import { EmbeddedCheckout, EmbeddedCheckoutProvider } from "@stripe/react-stripe-js"
import { loadStripe } from "@stripe/stripe-js"
import { createSubscriptionCheckout } from "@/app/actions/stripe-subscription"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"

const stripePromise = loadStripe(process.env.NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY!)

interface SubscriptionCheckoutProps {
  shop: any
}

export default function SubscriptionCheckout({ shop }: SubscriptionCheckoutProps) {
  const fetchClientSecret = useCallback(async () => {
    const planId = shop.subscription_tier === "solo" ? "solo-plan" : "business-plan"
    const technicianCount = shop.subscription_tier === "business" ? shop.total_technicians || 1 : 1

    return await createSubscriptionCheckout(planId, technicianCount)
  }, [shop])

  return (
    <Card>
      <CardHeader>
        <CardTitle>Complete Your Subscription</CardTitle>
        <CardDescription>Start your 14-day free trial. You won't be charged until the trial ends.</CardDescription>
      </CardHeader>
      <CardContent>
        <div id="checkout">
          <EmbeddedCheckoutProvider stripe={stripePromise} options={{ fetchClientSecret }}>
            <EmbeddedCheckout />
          </EmbeddedCheckoutProvider>
        </div>
      </CardContent>
    </Card>
  )
}
