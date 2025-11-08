import { createClient } from "@/lib/supabase/server"
import { redirect } from "next/navigation"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { ArrowLeft, Plus, MapPin } from "lucide-react"
import Link from "next/link"

export default async function AddressesPage() {
  const supabase = await createClient()

  const {
    data: { user },
  } = await supabase.auth.getUser()

  if (!user) {
    redirect("/auth/login")
  }

  const { data: addresses } = await supabase
    .from("addresses")
    .select("*")
    .eq("user_id", user.id)
    .order("is_default", { ascending: false })

  return (
    <div className="min-h-screen bg-background">
      <header className="border-b border-border bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/60">
        <div className="container mx-auto flex h-16 items-center justify-between px-4">
          <Button variant="ghost" size="sm" asChild>
            <Link href="/">
              <ArrowLeft className="mr-2 h-4 w-4" />
              Back
            </Link>
          </Button>
          <Button asChild>
            <Link href="/customer/addresses/new">
              <Plus className="mr-2 h-4 w-4" />
              Add Address
            </Link>
          </Button>
        </div>
      </header>

      <main className="container mx-auto max-w-4xl p-4 py-6">
        <div className="mb-6">
          <h1 className="text-3xl font-bold">My Addresses</h1>
          <p className="text-muted-foreground">Manage your service locations</p>
        </div>

        {addresses && addresses.length > 0 ? (
          <div className="grid gap-4 md:grid-cols-2">
            {addresses.map((address) => (
              <Card key={address.id}>
                <CardHeader>
                  <div className="flex items-start justify-between">
                    <CardTitle className="text-lg">{address.label}</CardTitle>
                    {address.is_default && <Badge>Default</Badge>}
                  </div>
                </CardHeader>
                <CardContent>
                  <p className="text-sm text-muted-foreground">
                    {address.street_address}
                    <br />
                    {address.city}, {address.state} {address.zip_code}
                  </p>
                </CardContent>
              </Card>
            ))}
          </div>
        ) : (
          <Card>
            <CardContent className="flex flex-col items-center justify-center py-12">
              <MapPin className="mb-4 h-12 w-12 text-muted-foreground" />
              <h3 className="mb-2 text-lg font-semibold">No addresses yet</h3>
              <p className="mb-4 text-sm text-muted-foreground">Add your first service location</p>
              <Button asChild>
                <Link href="/customer/addresses/new">
                  <Plus className="mr-2 h-4 w-4" />
                  Add Address
                </Link>
              </Button>
            </CardContent>
          </Card>
        )}
      </main>
    </div>
  )
}
