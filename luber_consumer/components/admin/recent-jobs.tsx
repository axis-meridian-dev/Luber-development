import { createClient } from "@/lib/supabase/server"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { formatDistanceToNow } from "date-fns"

export async function RecentJobs() {
  const supabase = await createClient()

  const { data: jobs } = await supabase
    .from("jobs")
    .select(`
      *,
      profiles!jobs_customer_id_fkey (full_name),
      technician:profiles!jobs_technician_id_fkey (full_name)
    `)
    .order("created_at", { ascending: false })
    .limit(5)

  const statusColors = {
    pending: "secondary",
    accepted: "default",
    in_progress: "default",
    completed: "secondary",
    cancelled: "secondary",
  }

  return (
    <Card>
      <CardHeader>
        <CardTitle>Recent Jobs</CardTitle>
      </CardHeader>
      <CardContent>
        {jobs && jobs.length > 0 ? (
          <div className="space-y-4">
            {jobs.map((job) => (
              <div key={job.id} className="flex items-center justify-between rounded-lg border border-border p-4">
                <div>
                  <p className="font-medium">{(job.profiles as any)?.full_name || "Unknown Customer"}</p>
                  <p className="text-sm text-muted-foreground">
                    {job.oil_type.replace("_", " ")} • ${(job.price_cents / 100).toFixed(2)}
                  </p>
                  <p className="text-xs text-muted-foreground">
                    {formatDistanceToNow(new Date(job.created_at), { addSuffix: true })}
                  </p>
                </div>
                <Badge variant={statusColors[job.status] as any}>{job.status.replace("_", " ")}</Badge>
              </div>
            ))}
          </div>
        ) : (
          <p className="text-sm text-muted-foreground">No recent jobs</p>
        )}
      </CardContent>
    </Card>
  )
}
