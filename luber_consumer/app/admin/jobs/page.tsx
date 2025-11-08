import { createClient } from "@/lib/supabase/server"
import { Card, CardContent } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Input } from "@/components/ui/input"
import { format } from "date-fns"

export default async function JobsPage() {
  const supabase = await createClient()

  const { data: jobs } = await supabase
    .from("jobs")
    .select(`
      *,
      customer:profiles!jobs_customer_id_fkey (full_name),
      technician:profiles!jobs_technician_id_fkey (full_name),
      vehicle:vehicles (make, model, year)
    `)
    .order("created_at", { ascending: false })
    .limit(50)

  const statusColors = {
    pending: "secondary",
    accepted: "default",
    in_progress: "default",
    completed: "secondary",
    cancelled: "secondary",
  }

  return (
    <div className="mx-auto max-w-7xl p-6">
      <div className="mb-8">
        <h1 className="text-3xl font-bold">Jobs</h1>
        <p className="text-muted-foreground">Monitor and manage all platform jobs</p>
      </div>

      <div className="mb-6">
        <Input placeholder="Search jobs..." className="max-w-md" />
      </div>

      <div className="grid gap-4">
        {jobs?.map((job) => {
          const customer = job.customer as any
          const technician = job.technician as any
          const vehicle = job.vehicle as any

          return (
            <Card key={job.id}>
              <CardContent className="p-6">
                <div className="flex items-start justify-between">
                  <div className="space-y-2">
                    <div className="flex items-center gap-3">
                      <p className="font-medium">
                        {vehicle?.year} {vehicle?.make} {vehicle?.model}
                      </p>
                      <Badge variant={statusColors[job.status] as any}>{job.status.replace("_", " ")}</Badge>
                    </div>
                    <div className="grid gap-1 text-sm text-muted-foreground">
                      <p>Customer: {customer?.full_name || "Unknown"}</p>
                      {technician && <p>Technician: {technician.full_name}</p>}
                      <p>Oil Type: {job.oil_type.replace("_", " ")}</p>
                      <p>Scheduled: {format(new Date(job.scheduled_time), "PPp")}</p>
                    </div>
                  </div>
                  <div className="text-right">
                    <p className="text-lg font-bold">${(job.price_cents / 100).toFixed(2)}</p>
                    <p className="text-xs text-muted-foreground">
                      Platform fee: ${(job.platform_fee_cents / 100).toFixed(2)}
                    </p>
                  </div>
                </div>
              </CardContent>
            </Card>
          )
        })}
      </div>
    </div>
  )
}
