"use client"

import { useState } from "react"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar"
import { Separator } from "@/components/ui/separator"
import { Progress } from "@/components/ui/progress"
import { ArrowLeft, MapPin, Phone, Star, Clock, Car, DollarSign } from "lucide-react"
import Link from "next/link"
import { useRealtimeLocation } from "@/lib/hooks/use-realtime-location"
import { ReviewDialog } from "./review-dialog"
import { format } from "date-fns"

interface JobTrackerProps {
  job: any
}

const statusSteps = {
  pending: { label: "Pending", progress: 25 },
  accepted: { label: "Accepted", progress: 50 },
  in_progress: { label: "In Progress", progress: 75 },
  completed: { label: "Completed", progress: 100 },
  cancelled: { label: "Cancelled", progress: 0 },
}

export function JobTracker({ job }: JobTrackerProps) {
  const [showReviewDialog, setShowReviewDialog] = useState(false)
  const technicianLocation = useRealtimeLocation(job.technician_id)

  const statusInfo = statusSteps[job.status as keyof typeof statusSteps]
  const vehicle = job.vehicles
  const address = job.addresses
  const technician = job.technician
  const techProfile = job.technician_profiles
  const photos = job.job_photos || []
  const review = job.reviews?.[0]

  return (
    <div className="min-h-screen bg-background">
      {/* Header */}
      <header className="border-b border-border bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/60">
        <div className="container mx-auto flex h-16 items-center px-4">
          <Button variant="ghost" size="sm" asChild>
            <Link href="/">
              <ArrowLeft className="mr-2 h-4 w-4" />
              Back to Dashboard
            </Link>
          </Button>
        </div>
      </header>

      {/* Main Content */}
      <main className="container mx-auto max-w-4xl p-4 py-6">
        {/* Status Progress */}
        <Card className="mb-6">
          <CardHeader>
            <div className="flex items-center justify-between">
              <CardTitle>Service Status</CardTitle>
              <Badge variant={job.status === "completed" ? "default" : "secondary"}>{statusInfo.label}</Badge>
            </div>
          </CardHeader>
          <CardContent>
            <Progress value={statusInfo.progress} className="mb-2 h-2" />
            <p className="text-sm text-muted-foreground">
              {job.status === "pending" && "Searching for an available technician..."}
              {job.status === "accepted" && "Technician is on the way!"}
              {job.status === "in_progress" && "Service is in progress"}
              {job.status === "completed" && "Service completed successfully"}
              {job.status === "cancelled" && "Service was cancelled"}
            </p>
          </CardContent>
        </Card>

        {/* Technician Info */}
        {technician && (
          <Card className="mb-6">
            <CardHeader>
              <CardTitle>Your Technician</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="flex items-start gap-4">
                <Avatar className="h-16 w-16">
                  <AvatarImage src={technician.profile_photo_url || "/placeholder.svg"} alt={technician.full_name} />
                  <AvatarFallback>{technician.full_name?.charAt(0)}</AvatarFallback>
                </Avatar>
                <div className="flex-1">
                  <h3 className="text-lg font-semibold">{technician.full_name}</h3>
                  <div className="flex items-center gap-3 text-sm text-muted-foreground">
                    <div className="flex items-center gap-1">
                      <Star className="h-4 w-4 fill-primary text-primary" />
                      <span>{techProfile?.average_rating.toFixed(1)}</span>
                    </div>
                    <span>•</span>
                    <span>{techProfile?.total_jobs_completed} jobs completed</span>
                  </div>
                  {technician.phone && (
                    <Button variant="outline" size="sm" className="mt-2 bg-transparent" asChild>
                      <a href={`tel:${technician.phone}`}>
                        <Phone className="mr-2 h-4 w-4" />
                        Call Technician
                      </a>
                    </Button>
                  )}
                </div>
              </div>

              {technicianLocation && job.status === "accepted" && (
                <div className="mt-4 rounded-lg bg-muted p-3">
                  <p className="text-sm font-medium">Technician Location</p>
                  <p className="text-sm text-muted-foreground">
                    Last updated: {new Date(technicianLocation.updated_at).toLocaleTimeString()}
                  </p>
                </div>
              )}
            </CardContent>
          </Card>
        )}

        {/* Job Details */}
        <Card className="mb-6">
          <CardHeader>
            <CardTitle>Service Details</CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="flex items-start gap-3">
              <Car className="mt-1 h-5 w-5 text-muted-foreground" />
              <div>
                <p className="font-medium">
                  {vehicle.year} {vehicle.make} {vehicle.model}
                </p>
                <p className="text-sm text-muted-foreground">{vehicle.vehicle_type}</p>
              </div>
            </div>

            <Separator />

            <div className="flex items-start gap-3">
              <MapPin className="mt-1 h-5 w-5 text-muted-foreground" />
              <div>
                <p className="font-medium">{address.label}</p>
                <p className="text-sm text-muted-foreground">
                  {address.street_address}
                  <br />
                  {address.city}, {address.state} {address.zip_code}
                </p>
              </div>
            </div>

            <Separator />

            <div className="flex items-start gap-3">
              <Clock className="mt-1 h-5 w-5 text-muted-foreground" />
              <div>
                <p className="font-medium">Scheduled Time</p>
                <p className="text-sm text-muted-foreground">
                  {format(new Date(job.scheduled_time), "EEEE, MMMM d, yyyy 'at' h:mm a")}
                </p>
              </div>
            </div>

            <Separator />

            <div className="flex items-start gap-3">
              <DollarSign className="mt-1 h-5 w-5 text-muted-foreground" />
              <div>
                <p className="font-medium">{job.oil_type.replace("_", " ")}</p>
                <p className="text-sm text-muted-foreground">${(job.price_cents / 100).toFixed(2)}</p>
              </div>
            </div>

            {job.special_instructions && (
              <>
                <Separator />
                <div>
                  <p className="font-medium">Special Instructions</p>
                  <p className="text-sm text-muted-foreground">{job.special_instructions}</p>
                </div>
              </>
            )}
          </CardContent>
        </Card>

        {/* Photos */}
        {photos.length > 0 && (
          <Card className="mb-6">
            <CardHeader>
              <CardTitle>Service Photos</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="grid gap-4 sm:grid-cols-2">
                {photos.map((photo: any) => (
                  <div key={photo.id} className="space-y-2">
                    <img
                      src={photo.photo_url || "/placeholder.svg"}
                      alt={photo.photo_type}
                      className="h-48 w-full rounded-lg object-cover"
                    />
                    <p className="text-sm font-medium capitalize">{photo.photo_type}</p>
                  </div>
                ))}
              </div>
            </CardContent>
          </Card>
        )}

        {/* Review Section */}
        {job.status === "completed" && (
          <Card>
            <CardHeader>
              <CardTitle>Service Review</CardTitle>
            </CardHeader>
            <CardContent>
              {review ? (
                <div className="space-y-2">
                  <div className="flex items-center gap-1">
                    {Array.from({ length: 5 }).map((_, i) => (
                      <Star
                        key={i}
                        className={`h-5 w-5 ${i < review.rating ? "fill-primary text-primary" : "text-muted"}`}
                      />
                    ))}
                  </div>
                  {review.comment && <p className="text-sm text-muted-foreground">{review.comment}</p>}
                </div>
              ) : (
                <div>
                  <p className="mb-4 text-sm text-muted-foreground">How was your service?</p>
                  <Button onClick={() => setShowReviewDialog(true)}>Leave a Review</Button>
                </div>
              )}
            </CardContent>
          </Card>
        )}
      </main>

      <ReviewDialog open={showReviewDialog} onOpenChange={setShowReviewDialog} jobId={job.id} />
    </div>
  )
}
