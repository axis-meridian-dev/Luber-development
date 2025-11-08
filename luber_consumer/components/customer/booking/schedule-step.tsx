"use client"

import { useState } from "react"
import { Button } from "@/components/ui/button"
import { Calendar } from "@/components/ui/calendar"
import { Label } from "@/components/ui/label"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import type { BookingData } from "../booking-flow"
import { addDays, format, set } from "date-fns"

interface ScheduleStepProps {
  bookingData: BookingData
  updateBookingData: (data: Partial<BookingData>) => void
  onNext: () => void
  onBack: () => void
}

const TIME_SLOTS = [
  "08:00 AM",
  "09:00 AM",
  "10:00 AM",
  "11:00 AM",
  "12:00 PM",
  "01:00 PM",
  "02:00 PM",
  "03:00 PM",
  "04:00 PM",
  "05:00 PM",
]

export function ScheduleStep({ bookingData, updateBookingData, onNext, onBack }: ScheduleStepProps) {
  const [selectedDate, setSelectedDate] = useState<Date | undefined>(
    bookingData.scheduledTime ? new Date(bookingData.scheduledTime) : undefined,
  )
  const [selectedTime, setSelectedTime] = useState<string>("")

  const handleNext = () => {
    if (selectedDate && selectedTime) {
      const [time, period] = selectedTime.split(" ")
      const [hours, minutes] = time.split(":")
      let hour = Number.parseInt(hours)
      if (period === "PM" && hour !== 12) hour += 12
      if (period === "AM" && hour === 12) hour = 0

      const scheduledDateTime = set(selectedDate, { hours: hour, minutes: Number.parseInt(minutes) })
      updateBookingData({ scheduledTime: scheduledDateTime.toISOString() })
      onNext()
    }
  }

  return (
    <div className="space-y-6">
      <div>
        <Label className="mb-3 block">Select Date</Label>
        <Calendar
          mode="single"
          selected={selectedDate}
          onSelect={setSelectedDate}
          disabled={(date) => date < new Date() || date > addDays(new Date(), 30)}
          className="rounded-md border border-border"
        />
      </div>

      {selectedDate && (
        <div>
          <Label htmlFor="time">Select Time</Label>
          <Select value={selectedTime} onValueChange={setSelectedTime}>
            <SelectTrigger id="time" className="mt-2">
              <SelectValue placeholder="Choose a time slot" />
            </SelectTrigger>
            <SelectContent>
              {TIME_SLOTS.map((time) => (
                <SelectItem key={time} value={time}>
                  {time}
                </SelectItem>
              ))}
            </SelectContent>
          </Select>
        </div>
      )}

      {selectedDate && selectedTime && (
        <div className="rounded-lg bg-muted p-4">
          <div className="text-sm text-muted-foreground">Scheduled for</div>
          <div className="text-lg font-semibold">
            {format(selectedDate, "EEEE, MMMM d, yyyy")} at {selectedTime}
          </div>
        </div>
      )}

      <div className="flex justify-between pt-4">
        <Button variant="outline" onClick={onBack}>
          Back
        </Button>
        <Button onClick={handleNext} disabled={!selectedDate || !selectedTime}>
          Continue
        </Button>
      </div>
    </div>
  )
}
