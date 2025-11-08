import { Card, CardContent } from "@/components/ui/card"
import { Wrench, MapPin, CheckCircle2 } from "lucide-react"
import Link from "next/link"

export default function ServiceAreasPage() {
  const cities = [
    { state: "California", cities: ["San Francisco", "Los Angeles", "San Diego", "San Jose", "Sacramento"] },
    { state: "Texas", cities: ["Houston", "Dallas", "Austin", "San Antonio", "Fort Worth"] },
    { state: "Florida", cities: ["Miami", "Orlando", "Tampa", "Jacksonville", "Fort Lauderdale"] },
    { state: "New York", cities: ["New York City", "Buffalo", "Rochester", "Albany", "Syracuse"] },
    { state: "Illinois", cities: ["Chicago", "Aurora", "Naperville", "Joliet", "Rockford"] },
  ]

  return (
    <div className="flex min-h-screen flex-col">
      <header className="sticky top-0 z-50 w-full border-b bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/60">
        <div className="container flex h-16 items-center justify-between">
          <Link href="/" className="flex items-center gap-2">
            <Wrench className="h-6 w-6 text-primary" />
            <span className="text-xl font-bold">Luber</span>
          </Link>
          <nav className="flex items-center gap-6">
            <Link href="/" className="text-sm font-medium hover:text-primary transition-colors">
              Home
            </Link>
            <Link href="/about" className="text-sm font-medium hover:text-primary transition-colors">
              About
            </Link>
            <Link href="/pricing" className="text-sm font-medium hover:text-primary transition-colors">
              Pricing
            </Link>
          </nav>
        </div>
      </header>

      <main className="flex-1">
        <section className="py-20">
          <div className="container">
            <div className="max-w-3xl mx-auto text-center mb-16">
              <h1 className="text-4xl font-bold mb-4">Service Areas</h1>
              <p className="text-lg text-muted-foreground">
                Luber is available in major cities across the United States. We're constantly expanding to new areas!
              </p>
            </div>

            <div className="max-w-5xl mx-auto space-y-8">
              {cities.map((region) => (
                <Card key={region.state}>
                  <CardContent className="pt-6">
                    <div className="flex items-start gap-4 mb-4">
                      <MapPin className="h-6 w-6 text-primary flex-shrink-0 mt-1" />
                      <h2 className="text-2xl font-bold">{region.state}</h2>
                    </div>
                    <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-3 ml-10">
                      {region.cities.map((city) => (
                        <div key={city} className="flex items-center gap-2">
                          <CheckCircle2 className="h-4 w-4 text-primary flex-shrink-0" />
                          <span className="text-muted-foreground">{city}</span>
                        </div>
                      ))}
                    </div>
                  </CardContent>
                </Card>
              ))}
            </div>

            <div className="mt-16 text-center">
              <Card className="max-w-2xl mx-auto bg-muted/50">
                <CardContent className="pt-6">
                  <h2 className="text-xl font-bold mb-2">Don't see your city?</h2>
                  <p className="text-muted-foreground mb-4">
                    We're expanding rapidly! Contact us to let us know where you'd like to see Luber next.
                  </p>
                  <Link
                    href="/contact"
                    className="text-primary hover:underline font-medium inline-flex items-center gap-2"
                  >
                    Request Service in Your Area
                  </Link>
                </CardContent>
              </Card>
            </div>
          </div>
        </section>
      </main>
    </div>
  )
}
