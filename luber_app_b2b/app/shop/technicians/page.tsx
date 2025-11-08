import { redirect } from "next/navigation"
import { createServerClient } from "@/lib/supabase/server"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Plus } from "lucide-react"
import Link from "next/link"
import ShopNav from "@/components/shop/shop-nav"
import Users from "lucide-react" // Import Users component

export default async function TechniciansPage() {
  const supabase = await createServerClient()

  const {
    data: { user },
  } = await supabase.auth.getUser()

  if (!user) {
    redirect("/auth/login")
  }

  const { data: shop } = await supabase.from("shops").select("*").eq("owner_id", user.id).single()

  if (!shop) {
    redirect("/onboarding")
  }

  const { data: technicians } = await supabase.from("shop_technicians").select("*, profiles(*)").eq("shop_id", shop.id)

  return (
    <div className="min-h-screen bg-muted/50">
      <ShopNav shop={shop} />

      <div className="container py-8">
        <div className="flex items-center justify-between mb-8">
          <div>
            <h1 className="text-3xl font-bold mb-2">Technicians</h1>
            <p className="text-muted-foreground">Manage your team of mobile technicians</p>
          </div>
          <Link href="/shop/technicians/add">
            <Button>
              <Plus className="h-4 w-4 mr-2" />
              Add Technician
            </Button>
          </Link>
        </div>

        {technicians && technicians.length > 0 ? (
          <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-3">
            {technicians.map((tech) => (
              <Card key={tech.id}>
                <CardHeader>
                  <CardTitle className="flex items-center justify-between">
                    <span>Technician #{tech.id.slice(0, 8)}</span>
                    <span
                      className={`inline-flex items-center rounded-full px-2 py-1 text-xs font-medium ${
                        tech.is_available
                          ? "bg-green-50 text-green-700 dark:bg-green-900/30 dark:text-green-400"
                          : "bg-gray-50 text-gray-700 dark:bg-gray-900/30 dark:text-gray-400"
                      }`}
                    >
                      {tech.is_available ? "Available" : "Offline"}
                    </span>
                  </CardTitle>
                </CardHeader>
                <CardContent>
                  <div className="space-y-2 text-sm">
                    <div>
                      <span className="text-muted-foreground">License:</span>{" "}
                      <span className="font-medium">{tech.license_number}</span>
                    </div>
                    <div>
                      <span className="text-muted-foreground">Experience:</span>{" "}
                      <span className="font-medium">{tech.years_experience} years</span>
                    </div>
                    <div>
                      <span className="text-muted-foreground">Rating:</span>{" "}
                      <span className="font-medium">{tech.rating}/5.0</span>
                    </div>
                    <div>
                      <span className="text-muted-foreground">Jobs Completed:</span>{" "}
                      <span className="font-medium">{tech.total_jobs}</span>
                    </div>
                    {tech.certifications && tech.certifications.length > 0 && (
                      <div>
                        <span className="text-muted-foreground">Certifications:</span>
                        <div className="flex flex-wrap gap-1 mt-1">
                          {tech.certifications.map((cert, idx) => (
                            <span
                              key={idx}
                              className="inline-flex items-center rounded-full bg-primary/10 px-2 py-0.5 text-xs font-medium text-primary"
                            >
                              {cert}
                            </span>
                          ))}
                        </div>
                      </div>
                    )}
                  </div>
                </CardContent>
              </Card>
            ))}
          </div>
        ) : (
          <Card>
            <CardContent className="flex flex-col items-center justify-center py-12">
              <Users className="h-12 w-12 text-muted-foreground mb-4" />
              <h3 className="text-lg font-semibold mb-2">No technicians yet</h3>
              <p className="text-sm text-muted-foreground mb-4">
                Add your first technician to start accepting bookings
              </p>
              <Link href="/shop/technicians/add">
                <Button>
                  <Plus className="h-4 w-4 mr-2" />
                  Add Technician
                </Button>
              </Link>
            </CardContent>
          </Card>
        )}
      </div>
    </div>
  )
}
