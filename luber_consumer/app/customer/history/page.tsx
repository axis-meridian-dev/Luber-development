import { createClient } from "@/lib/supabase/server"
import { redirect } from "next/navigation"
import { Button } from "@/components/ui/button"
import { Card, CardContent } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { ArrowLeft, Star } from "lucide-react"
import Link from "next/link"
import { formatDistanceToNow } from "date-fns"

export default async function HistoryPage() {
  const supabase = await createClient()

  const {
    data: { user },
  } = await supabase.auth.getUser()

  if (!user) {
    redirect("/auth/login")
  }

  const { data: jobs } = await supabase
    .from("jobs")
    .select(
      `
      *,
      vehicles (make, model, year),
      reviews (rating)
    `,
    )
    .eq("customer_id", user.id)
    .order("created_at", { ascending: false })

  return (
    <div className="min-h-screen bg-background">
      <header className="border-b border-border bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/60">
        <div className="container mx-auto flex h-16 items-center px-4">
          <Button variant="ghost" size="sm" asChild>
            <Link href="/">
              <ArrowLeft className="mr-2 h-4 w-4" />
              Back
            </Link>
          </Button>
        </div>
      </header>

      <main className="container mx-auto max-w-4xl p-4 py-6">
        <div className="mb-6">
          <h1 className="text-3xl font-bold">Service History</h1>
          <p className="text-muted-foreground">View all your past and current bookings</p>
        </div>

        {jobs && jobs.length > 0 ? (
          <Card>
            <CardContent className="p-0">
              <div className="divide-y divide-border">
                {jobs.map((job) => {
                  const vehicle = job.vehicles as any
                  const review = (job.reviews as any)?.[0]

                  const statusColors: Record<string, string> = {
                    pending: "secondary",
                    accepted: "default",
                    in_progress: "default",
                    completed: "secondary",
                    cancelled: "secondary",
                  }

                  return (
                    <Link
                      key={job.id}
                      href={`/customer/jobs/${job.id}`}
                      className="block p-4 transition-colors hover:bg-muted/50"
                    >
                      <div className="flex items-start justify-between">
                        <div className="flex-1">
                          <div className="mb-1 flex items-center gap-2">
                            <h3 className="font-medium">
                              {vehicle?.year} {vehicle?.make} {vehicle?.model}
                            </h3>
                            <Badge variant={statusColors[job.status] as any}>{job.status.replace("_", " ")}</Badge>
                          </div>
                          <p className="text-sm text-muted-foreground">
                            {job.oil_type.replace("_", " ")} • ${(job.price_cents / 100).toFixed(2)}
                          </p>
                          <p className="text-xs text-muted-foreground">
                            {job.completed_at
                              ? formatDistanceToNow(new Date(job.completed_at), { addSuffix: true })
                              : formatDistanceToNow(new Date(job.created_at), { addSuffix: true })}
                          </p>
                        </div>
                        {review && (
                          <div className="flex items-center gap-1">
                            <Star className="h-4 w-4 fill-primary text-primary" />
                            <span className="text-sm font-medium">{review.rating}</span>
                          </div>
                        )}
                      </div>
                    </Link>
                  )
                })}
              </div>
            </CardContent>
          </Card>
        ) : (
          <Card>
            <CardContent className="py-12 text-center">
              <p className="text-muted-foreground">No service history yet</p>
            </CardContent>
          </Card>
        )}
      </main>
    </div>
  )
}
