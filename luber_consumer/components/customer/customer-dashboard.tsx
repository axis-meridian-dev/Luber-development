import { createClient } from "@/lib/supabase/server"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Badge } from "@/components/ui/badge"
import { Plus, MapPin, Car, CreditCard, User } from "lucide-react"
import Link from "next/link"
import { formatDistanceToNow } from "date-fns"

export async function CustomerDashboard() {
  const supabase = await createClient()

  const {
    data: { user },
  } = await supabase.auth.getUser()

  if (!user) return null

  // Get profile
  const { data: profile } = await supabase.from("profiles").select("*").eq("id", user.id).single()

  // Get active jobs
  const { data: activeJobs } = await supabase
    .from("jobs")
    .select(
      `
      *,
      vehicles (make, model, year),
      addresses (street_address, city, state),
      technician:profiles!jobs_technician_id_fkey (full_name, profile_photo_url)
    `,
    )
    .eq("customer_id", user.id)
    .in("status", ["pending", "accepted", "in_progress"])
    .order("scheduled_time", { ascending: true })
    .limit(3)

  // Get recent completed jobs
  const { data: recentJobs } = await supabase
    .from("jobs")
    .select(
      `
      *,
      vehicles (make, model, year),
      reviews (rating)
    `,
    )
    .eq("customer_id", user.id)
    .eq("status", "completed")
    .order("completed_at", { ascending: false })
    .limit(5)

  const statusColors = {
    pending: "secondary",
    accepted: "default",
    in_progress: "default",
  }

  return (
    <div className="min-h-screen bg-background">
      {/* Header */}
      <header className="border-b border-border bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/60">
        <div className="container mx-auto flex h-16 items-center justify-between px-4">
          <h1 className="text-xl font-bold">Luber</h1>
          <nav className="flex gap-2">
            <Button variant="ghost" size="sm" asChild>
              <Link href="/customer/account">
                <User className="mr-2 h-4 w-4" />
                Account
              </Link>
            </Button>
          </nav>
        </div>
      </header>

      {/* Main Content */}
      <main className="container mx-auto p-4 md:p-6">
        <div className="mb-6">
          <h2 className="text-2xl font-bold">Welcome back, {profile?.full_name}</h2>
          <p className="text-muted-foreground">Book your next oil change or track active services</p>
        </div>

        {/* Quick Action */}
        <div className="mb-8">
          <Button size="lg" className="w-full md:w-auto" asChild>
            <Link href="/customer/book">
              <Plus className="mr-2 h-5 w-5" />
              Book New Service
            </Link>
          </Button>
        </div>

        {/* Active Jobs */}
        {activeJobs && activeJobs.length > 0 && (
          <section className="mb-8">
            <h3 className="mb-4 text-lg font-semibold">Active Services</h3>
            <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
              {activeJobs.map((job) => (
                <Card key={job.id} className="hover:shadow-lg transition-shadow">
                  <CardHeader>
                    <div className="flex items-start justify-between">
                      <CardTitle className="text-base">
                        {(job.vehicles as any)?.year} {(job.vehicles as any)?.make} {(job.vehicles as any)?.model}
                      </CardTitle>
                      <Badge variant={statusColors[job.status] as any}>{job.status.replace("_", " ")}</Badge>
                    </div>
                  </CardHeader>
                  <CardContent>
                    <div className="space-y-2 text-sm">
                      <p className="text-muted-foreground">
                        {job.oil_type.replace("_", " ")} • ${(job.price_cents / 100).toFixed(2)}
                      </p>
                      <p className="flex items-center gap-2 text-muted-foreground">
                        <MapPin className="h-4 w-4" />
                        {(job.addresses as any)?.city}, {(job.addresses as any)?.state}
                      </p>
                      {(job.technician as any) && (
                        <p className="font-medium">Tech: {(job.technician as any).full_name}</p>
                      )}
                    </div>
                    <Button className="mt-4 w-full bg-transparent" variant="outline" asChild>
                      <Link href={`/customer/jobs/${job.id}`}>View Details</Link>
                    </Button>
                  </CardContent>
                </Card>
              ))}
            </div>
          </section>
        )}

        {/* Quick Links */}
        <section className="mb-8">
          <h3 className="mb-4 text-lg font-semibold">Manage</h3>
          <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
            <Card className="hover:shadow-md transition-shadow cursor-pointer" asChild>
              <Link href="/customer/vehicles">
                <CardHeader>
                  <CardTitle className="flex items-center gap-2 text-base">
                    <Car className="h-5 w-5" />
                    Vehicles
                  </CardTitle>
                </CardHeader>
                <CardContent>
                  <p className="text-sm text-muted-foreground">Manage saved vehicles</p>
                </CardContent>
              </Link>
            </Card>

            <Card className="hover:shadow-md transition-shadow cursor-pointer" asChild>
              <Link href="/customer/addresses">
                <CardHeader>
                  <CardTitle className="flex items-center gap-2 text-base">
                    <MapPin className="h-5 w-5" />
                    Addresses
                  </CardTitle>
                </CardHeader>
                <CardContent>
                  <p className="text-sm text-muted-foreground">Manage service locations</p>
                </CardContent>
              </Link>
            </Card>

            <Card className="hover:shadow-md transition-shadow cursor-pointer" asChild>
              <Link href="/customer/payment-methods">
                <CardHeader>
                  <CardTitle className="flex items-center gap-2 text-base">
                    <CreditCard className="h-5 w-5" />
                    Payments
                  </CardTitle>
                </CardHeader>
                <CardContent>
                  <p className="text-sm text-muted-foreground">Manage payment methods</p>
                </CardContent>
              </Link>
            </Card>

            <Card className="hover:shadow-md transition-shadow cursor-pointer" asChild>
              <Link href="/customer/history">
                <CardHeader>
                  <CardTitle className="flex items-center gap-2 text-base">
                    <User className="h-5 w-5" />
                    History
                  </CardTitle>
                </CardHeader>
                <CardContent>
                  <p className="text-sm text-muted-foreground">View past services</p>
                </CardContent>
              </Link>
            </Card>
          </div>
        </section>

        {/* Recent Jobs */}
        {recentJobs && recentJobs.length > 0 && (
          <section>
            <h3 className="mb-4 text-lg font-semibold">Recent Services</h3>
            <Card>
              <CardContent className="p-0">
                <div className="divide-y divide-border">
                  {recentJobs.map((job) => (
                    <Link
                      key={job.id}
                      href={`/customer/jobs/${job.id}`}
                      className="block p-4 hover:bg-muted/50 transition-colors"
                    >
                      <div className="flex items-center justify-between">
                        <div>
                          <p className="font-medium">
                            {(job.vehicles as any)?.year} {(job.vehicles as any)?.make} {(job.vehicles as any)?.model}
                          </p>
                          <p className="text-sm text-muted-foreground">
                            {job.oil_type.replace("_", " ")} • ${(job.price_cents / 100).toFixed(2)}
                          </p>
                          <p className="text-xs text-muted-foreground">
                            {formatDistanceToNow(new Date(job.completed_at!), { addSuffix: true })}
                          </p>
                        </div>
                        {(job.reviews as any)?.length > 0 && (
                          <Badge variant="secondary">⭐ {(job.reviews as any)[0].rating}</Badge>
                        )}
                      </div>
                    </Link>
                  ))}
                </div>
              </CardContent>
            </Card>
          </section>
        )}
      </main>
    </div>
  )
}
