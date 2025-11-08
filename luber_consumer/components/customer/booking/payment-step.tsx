"use client"

import { useState, useEffect } from "react"
import { useRouter } from "next/navigation"
import { createClient } from "@/lib/supabase/client"
import { Button } from "@/components/ui/button"
import { RadioGroup, RadioGroupItem } from "@/components/ui/radio-group"
import { Label } from "@/components/ui/label"
import { useToast } from "@/hooks/use-toast"
import type { BookingData } from "../booking-flow"
import type { PaymentMethod } from "@/lib/types/database"
import { CreditCard, Plus } from "lucide-react"
import Link from "next/link"

interface PaymentStepProps {
  bookingData: BookingData
  onBack: () => void
}

export function PaymentStep({ bookingData, onBack }: PaymentStepProps) {
  const [paymentMethods, setPaymentMethods] = useState<PaymentMethod[]>([])
  const [selectedPaymentMethod, setSelectedPaymentMethod] = useState("")
  const [loading, setLoading] = useState(true)
  const [submitting, setSubmitting] = useState(false)
  const router = useRouter()
  const { toast } = useToast()
  const supabase = createClient()

  useEffect(() => {
    async function fetchPaymentMethods() {
      const {
        data: { user },
      } = await supabase.auth.getUser()
      if (!user) return

      const { data } = await supabase
        .from("payment_methods")
        .select("*")
        .eq("user_id", user.id)
        .order("is_default", { ascending: false })

      if (data) {
        setPaymentMethods(data)
        if (data.length > 0) {
          const defaultMethod = data.find((pm) => pm.is_default) || data[0]
          setSelectedPaymentMethod(defaultMethod.stripe_payment_method_id)
        }
      }
      setLoading(false)
    }

    fetchPaymentMethods()
  }, [supabase])

  const handleBooking = async () => {
    if (!selectedPaymentMethod) return

    setSubmitting(true)

    try {
      const response = await fetch("/api/jobs/create", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          vehicle_id: bookingData.vehicleId,
          address_id: bookingData.addressId,
          oil_type: bookingData.oilType,
          scheduled_time: bookingData.scheduledTime,
          special_instructions: bookingData.specialInstructions,
          payment_method_id: selectedPaymentMethod,
        }),
      })

      const data = await response.json()

      if (!response.ok) {
        throw new Error(data.error || "Failed to create booking")
      }

      toast({
        title: "Booking Created!",
        description: "Your oil change service has been scheduled.",
      })

      router.push(`/customer/jobs/${data.job.id}`)
    } catch (error: any) {
      toast({
        title: "Error",
        description: error.message,
        variant: "destructive",
      })
    } finally {
      setSubmitting(false)
    }
  }

  if (loading) {
    return <div className="py-8 text-center text-muted-foreground">Loading payment methods...</div>
  }

  if (paymentMethods.length === 0) {
    return (
      <div className="py-8 text-center">
        <CreditCard className="mx-auto mb-4 h-12 w-12 text-muted-foreground" />
        <h3 className="mb-2 text-lg font-semibold">No payment methods</h3>
        <p className="mb-4 text-sm text-muted-foreground">Add a payment method to complete your booking</p>
        <div className="flex justify-center gap-2">
          <Button variant="outline" onClick={onBack}>
            Back
          </Button>
          <Button asChild>
            <Link href="/customer/payment-methods/new">
              <Plus className="mr-2 h-4 w-4" />
              Add Payment Method
            </Link>
          </Button>
        </div>
      </div>
    )
  }

  return (
    <div className="space-y-6">
      <div>
        <h3 className="mb-3 font-medium">Select Payment Method</h3>
        <RadioGroup value={selectedPaymentMethod} onValueChange={setSelectedPaymentMethod}>
          <div className="space-y-3">
            {paymentMethods.map((pm) => (
              <div
                key={pm.id}
                className="flex items-center space-x-3 rounded-lg border border-border p-4 hover:bg-muted/50"
              >
                <RadioGroupItem value={pm.stripe_payment_method_id} id={pm.id} />
                <Label htmlFor={pm.id} className="flex-1 cursor-pointer">
                  <div className="flex items-center gap-2">
                    <CreditCard className="h-5 w-5 text-muted-foreground" />
                    <span className="font-medium">{pm.card_brand?.toUpperCase()}</span>
                    <span className="text-muted-foreground">•••• {pm.card_last4}</span>
                    {pm.is_default && <span className="text-xs text-muted-foreground">(Default)</span>}
                  </div>
                </Label>
              </div>
            ))}
          </div>
        </RadioGroup>
      </div>

      <div className="rounded-lg bg-muted p-4">
        <h4 className="mb-2 font-medium">Booking Summary</h4>
        <div className="space-y-1 text-sm text-muted-foreground">
          <div>Service: {bookingData.oilType?.replace("_", " ")}</div>
          <div>
            Scheduled: {bookingData.scheduledTime && new Date(bookingData.scheduledTime).toLocaleDateString()} at{" "}
            {bookingData.scheduledTime &&
              new Date(bookingData.scheduledTime).toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" })}
          </div>
        </div>
      </div>

      <div className="flex justify-between pt-4">
        <Button variant="outline" onClick={onBack} disabled={submitting}>
          Back
        </Button>
        <Button onClick={handleBooking} disabled={!selectedPaymentMethod || submitting}>
          {submitting ? "Booking..." : "Confirm Booking"}
        </Button>
      </div>
    </div>
  )
}
