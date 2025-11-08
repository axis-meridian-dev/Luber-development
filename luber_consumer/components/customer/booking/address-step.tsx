"use client"

import { useEffect, useState } from "react"
import { createClient } from "@/lib/supabase/client"
import { Button } from "@/components/ui/button"
import { RadioGroup, RadioGroupItem } from "@/components/ui/radio-group"
import { Label } from "@/components/ui/label"
import { MapPin, Plus } from "lucide-react"
import type { BookingData } from "../booking-flow"
import type { Address } from "@/lib/types/database"
import Link from "next/link"

interface AddressStepProps {
  bookingData: BookingData
  updateBookingData: (data: Partial<BookingData>) => void
  onNext: () => void
  onBack: () => void
}

export function AddressStep({ bookingData, updateBookingData, onNext, onBack }: AddressStepProps) {
  const [addresses, setAddresses] = useState<Address[]>([])
  const [selectedAddress, setSelectedAddress] = useState(bookingData.addressId || "")
  const [loading, setLoading] = useState(true)
  const supabase = createClient()

  useEffect(() => {
    async function fetchAddresses() {
      const {
        data: { user },
      } = await supabase.auth.getUser()
      if (!user) return

      const { data } = await supabase
        .from("addresses")
        .select("*")
        .eq("user_id", user.id)
        .order("is_default", { ascending: false })

      if (data) {
        setAddresses(data)
        if (data.length > 0 && !selectedAddress) {
          const defaultAddress = data.find((a) => a.is_default) || data[0]
          setSelectedAddress(defaultAddress.id)
        }
      }
      setLoading(false)
    }

    fetchAddresses()
  }, [supabase, selectedAddress])

  const handleNext = () => {
    if (selectedAddress) {
      updateBookingData({ addressId: selectedAddress })
      onNext()
    }
  }

  if (loading) {
    return <div className="py-8 text-center text-muted-foreground">Loading addresses...</div>
  }

  if (addresses.length === 0) {
    return (
      <div className="py-8 text-center">
        <MapPin className="mx-auto mb-4 h-12 w-12 text-muted-foreground" />
        <h3 className="mb-2 text-lg font-semibold">No addresses yet</h3>
        <p className="mb-4 text-sm text-muted-foreground">Add a service location to continue</p>
        <div className="flex justify-center gap-2">
          <Button variant="outline" onClick={onBack}>
            Back
          </Button>
          <Button asChild>
            <Link href="/customer/addresses/new">
              <Plus className="mr-2 h-4 w-4" />
              Add Address
            </Link>
          </Button>
        </div>
      </div>
    )
  }

  return (
    <div className="space-y-6">
      <RadioGroup value={selectedAddress} onValueChange={setSelectedAddress}>
        <div className="space-y-3">
          {addresses.map((address) => (
            <div
              key={address.id}
              className="flex items-center space-x-3 rounded-lg border border-border p-4 hover:bg-muted/50"
            >
              <RadioGroupItem value={address.id} id={address.id} />
              <Label htmlFor={address.id} className="flex-1 cursor-pointer">
                <div className="font-medium">{address.label}</div>
                <div className="text-sm text-muted-foreground">
                  {address.street_address}, {address.city}, {address.state} {address.zip_code}
                </div>
              </Label>
            </div>
          ))}
        </div>
      </RadioGroup>

      <div className="flex justify-between pt-4">
        <Button variant="outline" onClick={onBack}>
          Back
        </Button>
        <div className="flex gap-2">
          <Button variant="outline" asChild>
            <Link href="/customer/addresses/new">
              <Plus className="mr-2 h-4 w-4" />
              Add New
            </Link>
          </Button>
          <Button onClick={handleNext} disabled={!selectedAddress}>
            Continue
          </Button>
        </div>
      </div>
    </div>
  )
}
