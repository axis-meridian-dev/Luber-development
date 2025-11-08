import { createClient } from "@/lib/supabase/server"
import { Card, CardContent } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Input } from "@/components/ui/input"
import { Star } from "lucide-react"

export default async function TechniciansPage() {
  const supabase = await createClient()

  const { data: technicians } = await supabase
    .from("technician_profiles")
    .select(`
      *,
      profiles (
        full_name,
        phone,
        profile_photo_url
      )
    `)
    .order("created_at", { ascending: false })

  return (
    <div className="mx-auto max-w-7xl p-6">
      <div className="mb-8">
        <h1 className="text-3xl font-bold">Technicians</h1>
        <p className="text-muted-foreground">Manage technician accounts and applications</p>
      </div>

      <div className="mb-6">
        <Input placeholder="Search technicians..." className="max-w-md" />
      </div>

      <div className="grid gap-4">
        {technicians?.map((tech) => {
          const profile = tech.profiles as any
          const statusColors = {
            pending: "secondary",
            approved: "secondary",
            rejected: "destructive",
          }

          return (
            <Card key={tech.id}>
              <CardContent className="flex items-center justify-between p-6">
                <div className="flex items-center gap-4">
                  <div className="flex h-12 w-12 items-center justify-center rounded-full bg-muted text-lg font-medium">
                    {profile?.full_name?.charAt(0) || "T"}
                  </div>
                  <div>
                    <p className="font-medium">{profile?.full_name || "Unknown"}</p>
                    <p className="text-sm text-muted-foreground">{profile?.phone || "No phone"}</p>
                    <div className="mt-1 flex items-center gap-3 text-sm">
                      <span className="flex items-center gap-1">
                        <Star className="h-4 w-4 fill-yellow-500 text-yellow-500" />
                        {tech.average_rating.toFixed(1)}
                      </span>
                      <span className="text-muted-foreground">{tech.total_jobs_completed} jobs</span>
                      {tech.is_available && (
                        <Badge variant="secondary" className="text-xs">
                          Available
                        </Badge>
                      )}
                    </div>
                  </div>
                </div>
                <Badge variant={statusColors[tech.application_status] as any}>{tech.application_status}</Badge>
              </CardContent>
            </Card>
          )
        })}
      </div>
    </div>
  )
}
