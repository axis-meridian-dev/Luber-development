"use client"

import { Button } from "@/components/ui/button"
import { Check, X, ExternalLink } from "lucide-react"
import { useState } from "react"
import { useRouter } from "next/navigation"

interface ApplicationCardProps {
  application: any
}

export function ApplicationCard({ application }: ApplicationCardProps) {
  const [loading, setLoading] = useState(false)
  const router = useRouter()

  const handleApprove = async () => {
    setLoading(true)
    try {
      const response = await fetch("/api/admin/applications/approve", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ technician_id: application.id }),
      })

      if (response.ok) {
        router.refresh()
      }
    } catch (error) {
      console.error("[v0] Error approving application:", error)
    } finally {
      setLoading(false)
    }
  }

  const handleReject = async () => {
    setLoading(true)
    try {
      const reason = prompt("Enter rejection reason:")
      if (!reason) {
        setLoading(false)
        return
      }

      const response = await fetch("/api/admin/applications/reject", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ technician_id: application.id, reason }),
      })

      if (response.ok) {
        router.refresh()
      }
    } catch (error) {
      console.error("[v0] Error rejecting application:", error)
    } finally {
      setLoading(false)
    }
  }

  const profile = application.profiles

  return (
    <div className="flex items-center justify-between rounded-lg border border-border p-4">
      <div className="flex items-center gap-4">
        <div className="flex h-10 w-10 items-center justify-center rounded-full bg-muted text-sm font-medium">
          {profile?.full_name?.charAt(0) || "T"}
        </div>
        <div>
          <p className="font-medium">{profile?.full_name || "Unknown"}</p>
          <p className="text-sm text-muted-foreground">{profile?.phone || "No phone"}</p>
          <div className="mt-1 flex gap-2 text-xs">
            {application.years_experience && (
              <span className="text-muted-foreground">{application.years_experience} years exp</span>
            )}
            {application.certification_photo_url && (
              <a
                href={application.certification_photo_url}
                target="_blank"
                rel="noopener noreferrer"
                className="text-primary hover:underline flex items-center gap-1"
              >
                View Cert <ExternalLink className="h-3 w-3" />
              </a>
            )}
          </div>
        </div>
      </div>
      <div className="flex gap-2">
        <Button size="sm" variant="outline" onClick={handleApprove} disabled={loading}>
          <Check className="h-4 w-4 mr-1" />
          Approve
        </Button>
        <Button size="sm" variant="outline" onClick={handleReject} disabled={loading}>
          <X className="h-4 w-4 mr-1" />
          Reject
        </Button>
      </div>
    </div>
  )
}
