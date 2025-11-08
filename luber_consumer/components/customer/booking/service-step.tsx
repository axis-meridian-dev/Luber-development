"use client"

import { useState, useEffect } from "react"
import { createClient } from "@/lib/supabase/client"
import { Button } from "@/components/ui/button"
import { RadioGroup, RadioGroupItem } from "@/components/ui/radio-group"
import { Label } from "@/components/ui/label"
import { Textarea } from "@/components/ui/textarea"
import { calculateJobPrice } from "@/lib/pricing"
import type { BookingData } from "../booking-flow"
import type { OilType, VehicleType } from "@/lib/types/database"
import { Check } from "lucide-react"

interface ServiceStepProps {
  bookingData: BookingData
  updateBookingData: (data: Partial<BookingData>) => void
  onNext: () => void
  onBack: () => void
}

const OIL_TYPES: Array<{ value: OilType; label: string; description: string }> = [
  { value: "conventional", label: "Conventional", description: "Standard mineral oil for everyday driving" },
  {
    value: "synthetic_blend",
    label: "Synthetic Blend",
    description: "Mix of synthetic and conventional for better protection",
  },
  { value: "full_synthetic", label: "Full Synthetic", description: "Premium protection for high-performance engines" },
  { value: "high_mileage", label: "High Mileage", description: "Specially formulated for vehicles over 75,000 miles" },
]

export function ServiceStep({ bookingData, updateBookingData, onNext, onBack }: ServiceStepProps) {
  const [selectedOilType, setSelectedOilType] = useState<OilType | undefined>(bookingData.oilType)
  const [specialInstructions, setSpecialInstructions] = useState(bookingData.specialInstructions || "")
  const [recommendedOilType, setRecommendedOilType] = useState<OilType>()
  const [vehicleType, setVehicleType] = useState<VehicleType>()
  const [pricing, setPricing] = useState<{
    price_cents: number
    platform_fee_cents: number
    technician_earnings_cents: number
  }>()
  const supabase = createClient()

  useEffect(() => {
    async function fetchVehicleInfo() {
      if (!bookingData.vehicleId) return

      const { data: vehicle } = await supabase
        .from("vehicles")
        .select("recommended_oil_type, vehicle_type")
        .eq("id", bookingData.vehicleId)
        .single()

      if (vehicle) {
        setRecommendedOilType(vehicle.recommended_oil_type)
        setVehicleType(vehicle.vehicle_type)
        if (!selectedOilType) {
          setSelectedOilType(vehicle.recommended_oil_type)
        }
      }
    }

    fetchVehicleInfo()
  }, [bookingData.vehicleId, supabase, selectedOilType])

  useEffect(() => {
    if (selectedOilType && vehicleType) {
      const calculatedPricing = calculateJobPrice(selectedOilType, vehicleType)
      setPricing(calculatedPricing)
    }
  }, [selectedOilType, vehicleType])

  const handleNext = () => {
    if (selectedOilType) {
      updateBookingData({ oilType: selectedOilType, specialInstructions })
      onNext()
    }
  }

  return (
    <div className="space-y-6">
      <div>
        <h3 className="mb-3 font-medium">Select Oil Type</h3>
        <RadioGroup value={selectedOilType} onValueChange={(value) => setSelectedOilType(value as OilType)}>
          <div className="space-y-3">
            {OIL_TYPES.map((oilType) => (
              <div
                key={oilType.value}
                className="flex items-start space-x-3 rounded-lg border border-border p-4 hover:bg-muted/50"
              >
                <RadioGroupItem value={oilType.value} id={oilType.value} className="mt-1" />
                <Label htmlFor={oilType.value} className="flex-1 cursor-pointer">
                  <div className="flex items-center justify-between">
                    <div>
                      <div className="flex items-center gap-2 font-medium">
                        {oilType.label}
                        {recommendedOilType === oilType.value && (
                          <span className="inline-flex items-center gap-1 rounded-full bg-primary/10 px-2 py-0.5 text-xs text-primary">
                            <Check className="h-3 w-3" />
                            Recommended
                          </span>
                        )}
                      </div>
                      <div className="text-sm text-muted-foreground">{oilType.description}</div>
                    </div>
                    {vehicleType && selectedOilType === oilType.value && pricing && (
                      <div className="text-right">
                        <div className="font-semibold">${(pricing.price_cents / 100).toFixed(2)}</div>
                      </div>
                    )}
                  </div>
                </Label>
              </div>
            ))}
          </div>
        </RadioGroup>
      </div>

      <div>
        <Label htmlFor="instructions">Special Instructions (Optional)</Label>
        <Textarea
          id="instructions"
          placeholder="Any specific requirements or notes for the technician..."
          value={specialInstructions}
          onChange={(e) => setSpecialInstructions(e.target.value)}
          className="mt-2"
          rows={3}
        />
      </div>

      {pricing && (
        <div className="rounded-lg bg-muted p-4">
          <div className="flex justify-between text-sm">
            <span>Estimated Total</span>
            <span className="text-2xl font-bold">${(pricing.price_cents / 100).toFixed(2)}</span>
          </div>
        </div>
      )}

      <div className="flex justify-between pt-4">
        <Button variant="outline" onClick={onBack}>
          Back
        </Button>
        <Button onClick={handleNext} disabled={!selectedOilType}>
          Continue
        </Button>
      </div>
    </div>
  )
}
