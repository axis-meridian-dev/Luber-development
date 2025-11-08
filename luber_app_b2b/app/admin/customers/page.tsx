import { redirect } from "next/navigation"
import { createClient } from "@/lib/supabase/server"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { AdminNav } from "@/components/admin/admin-nav"
import { Mail, Phone, MapPin } from "lucide-react"

export default async function AdminCustomersPage() {
  const supabase = await createClient()

  const { data, error } = await supabase.auth.getUser()
  if (error || !data?.user) {
    redirect("/admin/login")
  }

  // Fetch all customers
  const { data: customers } = await supabase
    .from("customers")
    .select("*, profiles(*)")
    .order("created_at", { ascending: false })

  return (
    <div className="flex min-h-screen">
      <AdminNav />
      <div className="flex-1 p-8">
        <div className="mb-8">
          <h1 className="text-3xl font-bold">Customers</h1>
          <p className="text-muted-foreground">Manage customer accounts</p>
        </div>

        <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-3">
          {customers && customers.length > 0 ? (
            customers.map((customer) => (
              <Card key={customer.id}>
                <CardHeader>
                  <CardTitle className="text-lg">{customer.profiles?.full_name || "Unknown"}</CardTitle>
                </CardHeader>
                <CardContent>
                  <div className="space-y-2 text-sm">
                    <div className="flex items-center gap-2 text-muted-foreground">
                      <Mail className="h-4 w-4" />
                      <span>{customer.profiles?.email || "No email"}</span>
                    </div>
                    {customer.profiles?.phone && (
                      <div className="flex items-center gap-2 text-muted-foreground">
                        <Phone className="h-4 w-4" />
                        <span>{customer.profiles.phone}</span>
                      </div>
                    )}
                    {customer.address && (
                      <div className="flex items-center gap-2 text-muted-foreground">
                        <MapPin className="h-4 w-4" />
                        <span>
                          {customer.city}, {customer.state}
                        </span>
                      </div>
                    )}
                  </div>
                </CardContent>
              </Card>
            ))
          ) : (
            <Card className="col-span-full">
              <CardContent className="py-12 text-center">
                <p className="text-muted-foreground">No customers yet</p>
              </CardContent>
            </Card>
          )}
        </div>
      </div>
    </div>
  )
}
