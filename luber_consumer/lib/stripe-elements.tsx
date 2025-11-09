"use client"

import { Elements } from "@stripe/react-stripe-js"
import { loadStripe, Stripe } from "@stripe/stripe-js"
import { useEffect, useState } from "react"

let stripePromise: Promise<Stripe | null> | null = null

const getStripe = () => {
  if (!stripePromise) {
    const publishableKey = process.env.NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY
    if (!publishableKey) {
      console.error("Missing NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY environment variable")
      return null
    }
    stripePromise = loadStripe(publishableKey)
  }
  return stripePromise
}

interface StripeElementsProviderProps {
  children: React.ReactNode
}

export function StripeElementsProvider({ children }: StripeElementsProviderProps) {
  const [stripe, setStripe] = useState<Stripe | null>(null)

  useEffect(() => {
    const initStripe = async () => {
      const stripeInstance = await getStripe()
      setStripe(stripeInstance)
    }
    initStripe()
  }, [])

  if (!stripe) {
    return (
      <div className="flex items-center justify-center p-8">
        <div className="text-muted-foreground">Loading payment form...</div>
      </div>
    )
  }

  return (
    <Elements
      stripe={stripe}
      options={{
        appearance: {
          theme: "stripe",
          variables: {
            colorPrimary: "hsl(var(--primary))",
            colorBackground: "hsl(var(--background))",
            colorText: "hsl(var(--foreground))",
            colorDanger: "hsl(var(--destructive))",
            fontFamily: "var(--font-sans)",
            borderRadius: "calc(var(--radius) - 2px)",
          },
        },
      }}
    >
      {children}
    </Elements>
  )
}
