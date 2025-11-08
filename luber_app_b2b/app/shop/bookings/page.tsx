import { redirect } from "next/navigation"
import { createServerClient } from "@/lib/supabase/server"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Calendar } from "lucide-react"
import ShopNav from "@/components/shop/shop-nav"

export default async function BookingsPage() {
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

  const { data: bookings } = await supabase
    .from("bookings")
    .select("*, customers(*), shop_technicians(*), shop_service_packages(*)")
    .eq("shop_id", shop.id)
    .order("scheduled_date", { ascending: false })

  return (
    <div className="min-h-screen bg-muted/50">
      <ShopNav shop={shop} />

      <div className="container py-8">
        <div className="mb-8">
          <h1 className="text-3xl font-bold mb-2">Bookings</h1>
          <p className="text-muted-foreground">Manage all your service bookings</p>
        </div>

        {bookings && bookings.length > 0 ? (
          <Card>
            <CardHeader>
              <CardTitle>All Bookings</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="space-y-4">
                {bookings.map((booking) => (
                  <div key={booking.id} className="flex items-center justify-between border-b pb-4 last:border-0">
                    <div className="space-y-1">
                      <p className="font-medium">Booking #{booking.id.slice(0, 8)}</p>
                      <p className="text-sm text-muted-foreground">
                        {new Date(booking.scheduled_date).toLocaleString()}
                      </p>
                      <p className="text-sm text-muted-foreground">
                        {booking.service_address}, {booking.service_city}
                      </p>
                    </div>
                    <div className="text-right space-y-1">
                      <p className="font-medium">${booking.final_price || booking.estimated_price}</p>
                      <span
                        className={`inline-flex items-center rounded-full px-2 py-1 text-xs font-medium ${
                          booking.status === "completed"
                            ? "bg-green-50 text-green-700 dark:bg-green-900/30 dark:text-green-400"
                            : booking.status === "in_progress"
                              ? "bg-blue-50 text-blue-700 dark:bg-blue-900/30 dark:text-blue-400"
                              : "bg-yellow-50 text-yellow-700 dark:bg-yellow-900/30 dark:text-yellow-400"
                        }`}
                      >
                        {booking.status.replace("_", " ")}
                      </span>
                    </div>
                  </div>
                ))}
              </div>
            </CardContent>
          </Card>
        ) : (
          <Card>
            <CardContent className="flex flex-col items-center justify-center py-12">
              <Calendar className="h-12 w-12 text-muted-foreground mb-4" />
              <h3 className="text-lg font-semibold mb-2">No bookings yet</h3>
              <p className="text-sm text-muted-foreground">Bookings will appear here once customers start booking</p>
            </CardContent>
          </Card>
        )}
      </div>
    </div>
  )
}
