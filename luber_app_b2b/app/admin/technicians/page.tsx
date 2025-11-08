import { redirect } from "next/navigation"
import { createClient } from "@/lib/supabase/server"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { AdminNav } from "@/components/admin/admin-nav"
import { Mail, Phone, Star, Briefcase, CheckCircle2, XCircle } from "lucide-react"
import { Badge } from "@/components/ui/badge"

export default async function AdminTechniciansPage() {
  const supabase = await createClient()

  const { data, error } = await supabase.auth.getUser()
  if (error || !data?.user) {
    redirect("/admin/login")
  }

  // Fetch all technicians
  const { data: technicians } = await supabase
    .from("technicians")
    .select("*, profiles(*)")
    .order("created_at", { ascending: false })

  return (
    <div className="flex min-h-screen">
      <AdminNav />
      <div className="flex-1 p-8">
        <div className="mb-8">
          <h1 className="text-3xl font-bold">Technicians</h1>
          <p className="text-muted-foreground">Manage technician accounts</p>
        </div>

        <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-3">
          {technicians && technicians.length > 0 ? (
            technicians.map((technician) => (
              <Card key={technician.id}>
                <CardHeader>
                  <div className="flex items-start justify-between">
                    <CardTitle className="text-lg">{technician.profiles?.full_name || "Unknown"}</CardTitle>
                    {technician.is_available ? (
                      <Badge variant="default" className="gap-1">
                        <CheckCircle2 className="h-3 w-3" />
                        Available
                      </Badge>
                    ) : (
                      <Badge variant="secondary" className="gap-1">
                        <XCircle className="h-3 w-3" />
                        Offline
                      </Badge>
                    )}
                  </div>
                </CardHeader>
                <CardContent>
                  <div className="space-y-2 text-sm">
                    <div className="flex items-center gap-2 text-muted-foreground">
                      <Mail className="h-4 w-4" />
                      <span>{technician.profiles?.email || "No email"}</span>
                    </div>
                    {technician.profiles?.phone && (
                      <div className="flex items-center gap-2 text-muted-foreground">
                        <Phone className="h-4 w-4" />
                        <span>{technician.profiles.phone}</span>
                      </div>
                    )}
                    <div className="flex items-center gap-2 text-muted-foreground">
                      <Star className="h-4 w-4" />
                      <span>Rating: {technician.rating?.toFixed(1) || "0.0"}</span>
                    </div>
                    <div className="flex items-center gap-2 text-muted-foreground">
                      <Briefcase className="h-4 w-4" />
                      <span>{technician.total_jobs || 0} jobs completed</span>
                    </div>
                  </div>
                </CardContent>
              </Card>
            ))
          ) : (
            <Card className="col-span-full">
              <CardContent className="py-12 text-center">
                <p className="text-muted-foreground">No technicians yet</p>
              </CardContent>
            </Card>
          )}
        </div>
      </div>
    </div>
  )
}
