"use client"

import { useEffect, useState } from "react"
import { createClient } from "@/lib/supabase/client"
import { Button } from "@/components/ui/button"
import { RadioGroup, RadioGroupItem } from "@/components/ui/radio-group"
import { Label } from "@/components/ui/label"
import { Car, Plus } from "lucide-react"
import type { BookingData } from "../booking-flow"
import type { Vehicle } from "@/lib/types/database"
import Link from "next/link"

interface VehicleStepProps {
  bookingData: BookingData
  updateBookingData: (data: Partial<BookingData>) => void
  onNext: () => void
}

export function VehicleStep({ bookingData, updateBookingData, onNext }: VehicleStepProps) {
  const [vehicles, setVehicles] = useState<Vehicle[]>([])
  const [selectedVehicle, setSelectedVehicle] = useState(bookingData.vehicleId || "")
  const [loading, setLoading] = useState(true)
  const supabase = createClient()

  useEffect(() => {
    async function fetchVehicles() {
      const {
        data: { user },
      } = await supabase.auth.getUser()
      if (!user) return

      const { data } = await supabase
        .from("vehicles")
        .select("*")
        .eq("user_id", user.id)
        .order("is_default", { ascending: false })

      if (data) {
        setVehicles(data)
        if (data.length > 0 && !selectedVehicle) {
          const defaultVehicle = data.find((v) => v.is_default) || data[0]
          setSelectedVehicle(defaultVehicle.id)
        }
      }
      setLoading(false)
    }

    fetchVehicles()
  }, [supabase, selectedVehicle])

  const handleNext = () => {
    if (selectedVehicle) {
      updateBookingData({ vehicleId: selectedVehicle })
      onNext()
    }
  }

  if (loading) {
    return <div className="py-8 text-center text-muted-foreground">Loading vehicles...</div>
  }

  if (vehicles.length === 0) {
    return (
      <div className="py-8 text-center">
        <Car className="mx-auto mb-4 h-12 w-12 text-muted-foreground" />
        <h3 className="mb-2 text-lg font-semibold">No vehicles yet</h3>
        <p className="mb-4 text-sm text-muted-foreground">Add your first vehicle to continue booking</p>
        <Button asChild>
          <Link href="/customer/vehicles/new">
            <Plus className="mr-2 h-4 w-4" />
            Add Vehicle
          </Link>
        </Button>
      </div>
    )
  }

  return (
    <div className="space-y-6">
      <RadioGroup value={selectedVehicle} onValueChange={setSelectedVehicle}>
        <div className="space-y-3">
          {vehicles.map((vehicle) => (
            <div
              key={vehicle.id}
              className="flex items-center space-x-3 rounded-lg border border-border p-4 hover:bg-muted/50"
            >
              <RadioGroupItem value={vehicle.id} id={vehicle.id} />
              <Label htmlFor={vehicle.id} className="flex-1 cursor-pointer">
                <div className="font-medium">
                  {vehicle.year} {vehicle.make} {vehicle.model}
                </div>
                <div className="text-sm text-muted-foreground">
                  {vehicle.vehicle_type} • Recommended: {vehicle.recommended_oil_type.replace("_", " ")}
                </div>
              </Label>
            </div>
          ))}
        </div>
      </RadioGroup>

      <div className="flex justify-between pt-4">
        <Button variant="outline" asChild>
          <Link href="/customer/vehicles/new">
            <Plus className="mr-2 h-4 w-4" />
            Add New Vehicle
          </Link>
        </Button>
        <Button onClick={handleNext} disabled={!selectedVehicle}>
          Continue
        </Button>
      </div>
    </div>
  )
}
