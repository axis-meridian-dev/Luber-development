import { createClient } from "@/lib/supabase/server"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { ApplicationCard } from "./application-card"

export async function PendingApplications() {
  const supabase = await createClient()

  const { data: applications } = await supabase
    .from("technician_profiles")
    .select(`
      *,
      profiles (
        full_name,
        email,
        phone,
        profile_photo_url
      )
    `)
    .eq("application_status", "pending")
    .order("applied_at", { ascending: false })
    .limit(5)

  return (
    <Card>
      <CardHeader>
        <CardTitle>Pending Applications</CardTitle>
      </CardHeader>
      <CardContent>
        {applications && applications.length > 0 ? (
          <div className="space-y-4">
            {applications.map((app) => (
              <ApplicationCard key={app.id} application={app} />
            ))}
          </div>
        ) : (
          <p className="text-sm text-muted-foreground">No pending applications</p>
        )}
      </CardContent>
    </Card>
  )
}
