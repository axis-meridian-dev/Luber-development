"use client"

import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Checkbox } from "@/components/ui/checkbox"
import { ArrowLeft, CreditCard } from "lucide-react"
import Link from "next/link"
import { useRouter } from "next/navigation"
import { useState } from "react"
import { StripeElementsProvider } from "@/lib/stripe-elements"
import { PaymentElement, useStripe, useElements } from "@stripe/react-stripe-js"
import { toast } from "sonner"

function AddPaymentMethodForm() {
  const stripe = useStripe()
  const elements = useElements()
  const router = useRouter()

  const [cardholderName, setCardholderName] = useState("")
  const [setAsDefault, setSetAsDefault] = useState(false)
  const [isProcessing, setIsProcessing] = useState(false)

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()

    if (!stripe || !elements) {
      toast.error("Stripe has not loaded yet. Please wait and try again.")
      return
    }

    if (!cardholderName.trim()) {
      toast.error("Please enter the cardholder name")
      return
    }

    setIsProcessing(true)

    try {
      // Submit the payment element to create a payment method
      const { error: submitError } = await elements.submit()

      if (submitError) {
        toast.error(submitError.message || "Failed to validate card information")
        setIsProcessing(false)
        return
      }

      // Create payment method
      const { error: paymentMethodError, paymentMethod } = await stripe.createPaymentMethod({
        elements,
        params: {
          billing_details: {
            name: cardholderName,
          },
        },
      })

      if (paymentMethodError) {
        toast.error(paymentMethodError.message || "Failed to create payment method")
        setIsProcessing(false)
        return
      }

      if (!paymentMethod) {
        toast.error("Failed to create payment method")
        setIsProcessing(false)
        return
      }

      // Save payment method to database via API
      const response = await fetch("/api/payment-methods/add", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          paymentMethodId: paymentMethod.id,
          setAsDefault,
        }),
      })

      const data = await response.json()

      if (!response.ok) {
        toast.error(data.error || "Failed to save payment method")
        setIsProcessing(false)
        return
      }

      toast.success("Payment method added successfully!")
      router.push("/customer/payment-methods")
    } catch (error: any) {
      console.error("Error adding payment method:", error)
      toast.error(error.message || "An unexpected error occurred")
      setIsProcessing(false)
    }
  }

  return (
    <form onSubmit={handleSubmit}>
      <div className="space-y-6">
        {/* Cardholder Name */}
        <div className="space-y-2">
          <Label htmlFor="cardholder-name">Cardholder Name</Label>
          <Input
            id="cardholder-name"
            type="text"
            placeholder="John Doe"
            value={cardholderName}
            onChange={(e) => setCardholderName(e.target.value)}
            required
            disabled={isProcessing}
          />
        </div>

        {/* Stripe Payment Element */}
        <div className="space-y-2">
          <Label>Card Information</Label>
          <div className="rounded-lg border border-input bg-background p-3">
            <PaymentElement
              options={{
                layout: "tabs",
              }}
            />
          </div>
        </div>

        {/* Set as Default */}
        <div className="flex items-center space-x-2">
          <Checkbox
            id="set-default"
            checked={setAsDefault}
            onCheckedChange={(checked) => setSetAsDefault(checked as boolean)}
            disabled={isProcessing}
          />
          <Label
            htmlFor="set-default"
            className="text-sm font-normal leading-none peer-disabled:cursor-not-allowed peer-disabled:opacity-70"
          >
            Set as default payment method
          </Label>
        </div>

        {/* Submit Button */}
        <div className="flex gap-3">
          <Button type="button" variant="outline" asChild disabled={isProcessing}>
            <Link href="/customer/payment-methods">Cancel</Link>
          </Button>
          <Button type="submit" disabled={!stripe || isProcessing} className="flex-1">
            {isProcessing ? (
              <>
                <div className="mr-2 h-4 w-4 animate-spin rounded-full border-2 border-background border-t-transparent" />
                Processing...
              </>
            ) : (
              <>
                <CreditCard className="mr-2 h-4 w-4" />
                Add Payment Method
              </>
            )}
          </Button>
        </div>

        {/* Test Card Notice */}
        <div className="rounded-lg border border-muted bg-muted/50 p-3 text-xs text-muted-foreground">
          <p className="font-semibold">Test Card (Stripe Test Mode):</p>
          <p>Card: 4242 4242 4242 4242</p>
          <p>Expiry: Any future date</p>
          <p>CVC: Any 3 digits</p>
          <p>ZIP: Any 5 digits</p>
        </div>
      </div>
    </form>
  )
}

export default function NewPaymentMethodPage() {
  return (
    <div className="min-h-screen bg-background">
      <header className="border-b border-border bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/60">
        <div className="container mx-auto flex h-16 items-center px-4">
          <Button variant="ghost" size="sm" asChild>
            <Link href="/customer/payment-methods">
              <ArrowLeft className="mr-2 h-4 w-4" />
              Back
            </Link>
          </Button>
        </div>
      </header>

      <main className="container mx-auto max-w-2xl p-4 py-6">
        <Card>
          <CardHeader>
            <CardTitle>Add Payment Method</CardTitle>
            <CardDescription>Add a new card to your account for booking services</CardDescription>
          </CardHeader>
          <CardContent>
            <StripeElementsProvider>
              <AddPaymentMethodForm />
            </StripeElementsProvider>
          </CardContent>
        </Card>
      </main>
    </div>
  )
}
