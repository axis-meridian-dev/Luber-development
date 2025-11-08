"use client"

import { useState } from "react"
import { Card } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Badge } from "@/components/ui/badge"
import { Avatar, AvatarFallback } from "@/components/ui/avatar"
import { assignJobToTechnician, reassignJob } from "@/app/actions/dispatch"
import { Users, Clock, MapPin, Phone, Car } from "lucide-react"
import { toast } from "sonner"

interface DispatchBoardProps {
  shop: any
  technicians: any[]
  unassignedBookings: any[]
  assignedBookings: any[]
}

export function DispatchBoard({ shop, technicians, unassignedBookings, assignedBookings }: DispatchBoardProps) {
  const [selectedBooking, setSelectedBooking] = useState<string | null>(null)
  const [loading, setLoading] = useState(false)

  const handleAssign = async (bookingId: string, technicianId: string) => {
    setLoading(true)
    try {
      const result = await assignJobToTechnician(bookingId, technicianId, shop.id)
      if (result.success) {
        toast.success("Job assigned successfully")
        setSelectedBooking(null)
      } else {
        toast.error(result.error || "Failed to assign job")
      }
    } catch (error) {
      toast.error("An error occurred")
    } finally {
      setLoading(false)
    }
  }

  const handleReassign = async (bookingId: string, newTechnicianId: string) => {
    setLoading(true)
    try {
      const result = await reassignJob(bookingId, newTechnicianId, shop.id)
      if (result.success) {
        toast.success("Job reassigned successfully")
      } else {
        toast.error(result.error || "Failed to reassign job")
      }
    } catch (error) {
      toast.error("An error occurred")
    } finally {
      setLoading(false)
    }
  }

  const getInitials = (name: string) => {
    return name
      .split(" ")
      .map((n) => n[0])
      .join("")
      .toUpperCase()
  }

  const formatTime = (dateString: string) => {
    return new Date(dateString).toLocaleTimeString("en-US", {
      hour: "numeric",
      minute: "2-digit",
    })
  }

  return (
    <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
      {/* Technicians Column */}
      <Card className="p-6">
        <div className="flex items-center gap-2 mb-4">
          <Users className="h-5 w-5" />
          <h2 className="text-xl font-semibold">Technicians</h2>
          <Badge variant="secondary">{technicians.length}</Badge>
        </div>

        <div className="space-y-3">
          {technicians.map((tech) => {
            const isOnClock = tech.time_tracking?.some((t: any) => t.status === "clocked_in")
            const activeJobs = assignedBookings.filter(
              (b) => b.shop_technician_id === tech.id && b.status === "in_progress",
            ).length

            return (
              <div
                key={tech.id}
                className="flex items-center justify-between p-3 border rounded-lg hover:bg-accent transition-colors"
              >
                <div className="flex items-center gap-3">
                  <Avatar>
                    <AvatarFallback>{getInitials(tech.profiles?.full_name || "Tech")}</AvatarFallback>
                  </Avatar>
                  <div>
                    <p className="font-medium">{tech.profiles?.full_name}</p>
                    <div className="flex items-center gap-2 text-sm text-muted-foreground">
                      <Badge variant={tech.is_available ? "default" : "secondary"} className="text-xs">
                        {tech.is_available ? "Available" : "Unavailable"}
                      </Badge>
                      {isOnClock && (
                        <Badge variant="outline" className="text-xs">
                          On Clock
                        </Badge>
                      )}
                    </div>
                  </div>
                </div>
                {activeJobs > 0 && <Badge variant="secondary">{activeJobs} active</Badge>}
              </div>
            )
          })}

          {technicians.length === 0 && (
            <p className="text-center text-muted-foreground py-8">No technicians added yet</p>
          )}
        </div>
      </Card>

      {/* Unassigned Jobs Column */}
      <Card className="p-6">
        <div className="flex items-center gap-2 mb-4">
          <Clock className="h-5 w-5" />
          <h2 className="text-xl font-semibold">Unassigned Jobs</h2>
          <Badge variant="destructive">{unassignedBookings.length}</Badge>
        </div>

        <div className="space-y-3">
          {unassignedBookings.map((booking) => (
            <Card
              key={booking.id}
              className={`p-4 cursor-pointer transition-all ${
                selectedBooking === booking.id ? "ring-2 ring-primary" : ""
              }`}
              onClick={() => setSelectedBooking(booking.id)}
            >
              <div className="space-y-2">
                <div className="flex items-start justify-between">
                  <div>
                    <p className="font-medium">{booking.customer?.full_name}</p>
                    <p className="text-sm text-muted-foreground flex items-center gap-1">
                      <Phone className="h-3 w-3" />
                      {booking.customer?.phone}
                    </p>
                  </div>
                  <Badge>{booking.status}</Badge>
                </div>

                <div className="text-sm space-y-1">
                  <p className="flex items-center gap-1">
                    <Car className="h-3 w-3" />
                    {booking.vehicle?.year} {booking.vehicle?.make} {booking.vehicle?.model}
                  </p>
                  <p className="flex items-center gap-1">
                    <Clock className="h-3 w-3" />
                    {formatTime(booking.scheduled_time)}
                  </p>
                  <p className="flex items-center gap-1">
                    <MapPin className="h-3 w-3" />
                    {booking.service_address}
                  </p>
                </div>

                {selectedBooking === booking.id && (
                  <div className="pt-3 border-t space-y-2">
                    <p className="text-sm font-medium">Assign to:</p>
                    {technicians
                      .filter((t) => t.is_available)
                      .map((tech) => (
                        <Button
                          key={tech.id}
                          variant="outline"
                          size="sm"
                          className="w-full justify-start bg-transparent"
                          onClick={(e) => {
                            e.stopPropagation()
                            handleAssign(booking.id, tech.id)
                          }}
                          disabled={loading}
                        >
                          {tech.profiles?.full_name}
                        </Button>
                      ))}
                    {technicians.filter((t) => t.is_available).length === 0 && (
                      <p className="text-sm text-muted-foreground text-center py-2">No available technicians</p>
                    )}
                  </div>
                )}
              </div>
            </Card>
          ))}

          {unassignedBookings.length === 0 && (
            <p className="text-center text-muted-foreground py-8">No unassigned jobs</p>
          )}
        </div>
      </Card>

      {/* Assigned Jobs Column */}
      <Card className="p-6">
        <div className="flex items-center gap-2 mb-4">
          <MapPin className="h-5 w-5" />
          <h2 className="text-xl font-semibold">Active Jobs</h2>
          <Badge variant="secondary">{assignedBookings.length}</Badge>
        </div>

        <div className="space-y-3">
          {assignedBookings.map((booking) => (
            <Card key={booking.id} className="p-4">
              <div className="space-y-2">
                <div className="flex items-start justify-between">
                  <div>
                    <p className="font-medium">{booking.customer?.full_name}</p>
                    <p className="text-sm text-muted-foreground">
                      Assigned to: {booking.assignment?.[0]?.technician?.profile?.full_name}
                    </p>
                  </div>
                  <Badge variant={booking.status === "in_progress" ? "default" : "secondary"}>{booking.status}</Badge>
                </div>

                <div className="text-sm space-y-1">
                  <p className="flex items-center gap-1">
                    <Car className="h-3 w-3" />
                    {booking.vehicle?.year} {booking.vehicle?.make} {booking.vehicle?.model}
                  </p>
                  <p className="flex items-center gap-1">
                    <Clock className="h-3 w-3" />
                    {formatTime(booking.scheduled_time)}
                  </p>
                </div>

                <Button
                  variant="outline"
                  size="sm"
                  className="w-full bg-transparent"
                  onClick={() => {
                    // Show reassignment options
                    setSelectedBooking(booking.id)
                  }}
                >
                  Reassign
                </Button>
              </div>
            </Card>
          ))}

          {assignedBookings.length === 0 && <p className="text-center text-muted-foreground py-8">No active jobs</p>}
        </div>
      </Card>
    </div>
  )
}
