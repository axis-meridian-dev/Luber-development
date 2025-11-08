"use client"

import { useState } from "react"
import { useRouter } from "next/navigation"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Progress } from "@/components/ui/progress"
import { ArrowLeft } from "lucide-react"
import Link from "next/link"
import { VehicleStep } from "./booking/vehicle-step"
import { AddressStep } from "./booking/address-step"
import { ServiceStep } from "./booking/service-step"
import { ScheduleStep } from "./booking/schedule-step"
import { PaymentStep } from "./booking/payment-step"
import type { OilType } from "@/lib/types/database"

export interface BookingData {
  vehicleId?: string
  addressId?: string
  oilType?: OilType
  scheduledTime?: string
  specialInstructions?: string
  paymentMethodId?: string
}

const STEPS = [
  { id: 1, name: "Vehicle", description: "Select your vehicle" },
  { id: 2, name: "Location", description: "Choose service location" },
  { id: 3, name: "Service", description: "Select oil type" },
  { id: 4, name: "Schedule", description: "Pick date & time" },
  { id: 5, name: "Payment", description: "Confirm & pay" },
]

export function BookingFlow() {
  const [currentStep, setCurrentStep] = useState(1)
  const [bookingData, setBookingData] = useState<BookingData>({})
  const router = useRouter()

  const progress = (currentStep / STEPS.length) * 100

  const updateBookingData = (data: Partial<BookingData>) => {
    setBookingData((prev) => ({ ...prev, ...data }))
  }

  const handleNext = () => {
    if (currentStep < STEPS.length) {
      setCurrentStep(currentStep + 1)
    }
  }

  const handleBack = () => {
    if (currentStep > 1) {
      setCurrentStep(currentStep - 1)
    }
  }

  return (
    <div className="min-h-screen bg-background">
      {/* Header */}
      <header className="border-b border-border bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/60">
        <div className="container mx-auto flex h-16 items-center px-4">
          <Button variant="ghost" size="sm" asChild>
            <Link href="/">
              <ArrowLeft className="mr-2 h-4 w-4" />
              Back
            </Link>
          </Button>
        </div>
      </header>

      {/* Main Content */}
      <main className="container mx-auto max-w-3xl p-4 py-8">
        {/* Progress */}
        <div className="mb-8">
          <div className="mb-2 flex items-center justify-between">
            <h1 className="text-2xl font-bold">Book Service</h1>
            <span className="text-sm text-muted-foreground">
              Step {currentStep} of {STEPS.length}
            </span>
          </div>
          <Progress value={progress} className="h-2" />
          <p className="mt-2 text-sm text-muted-foreground">{STEPS[currentStep - 1].description}</p>
        </div>

        {/* Step Content */}
        <Card>
          <CardHeader>
            <CardTitle>{STEPS[currentStep - 1].name}</CardTitle>
          </CardHeader>
          <CardContent>
            {currentStep === 1 && (
              <VehicleStep bookingData={bookingData} updateBookingData={updateBookingData} onNext={handleNext} />
            )}
            {currentStep === 2 && (
              <AddressStep
                bookingData={bookingData}
                updateBookingData={updateBookingData}
                onNext={handleNext}
                onBack={handleBack}
              />
            )}
            {currentStep === 3 && (
              <ServiceStep
                bookingData={bookingData}
                updateBookingData={updateBookingData}
                onNext={handleNext}
                onBack={handleBack}
              />
            )}
            {currentStep === 4 && (
              <ScheduleStep
                bookingData={bookingData}
                updateBookingData={updateBookingData}
                onNext={handleNext}
                onBack={handleBack}
              />
            )}
            {currentStep === 5 && <PaymentStep bookingData={bookingData} onBack={handleBack} />}
          </CardContent>
        </Card>
      </main>
    </div>
  )
}
