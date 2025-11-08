import { Button } from "@/components/ui/button"
import { Card, CardContent } from "@/components/ui/card"
import { Wrench, Smartphone, Calendar, MapPin, CreditCard, Star } from "lucide-react"
import Link from "next/link"

export default function HowItWorksPage() {
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
              <h1 className="text-4xl font-bold mb-4">How Luber Works</h1>
              <p className="text-lg text-muted-foreground">
                Getting your oil changed has never been easier. Here's how it works in 6 simple steps.
              </p>
            </div>

            <div className="max-w-4xl mx-auto space-y-12">
              <Card>
                <CardContent className="pt-6">
                  <div className="flex items-start gap-6">
                    <div className="flex-shrink-0 inline-flex h-16 w-16 items-center justify-center rounded-full bg-primary text-primary-foreground text-2xl font-bold">
                      1
                    </div>
                    <div className="flex-1">
                      <div className="flex items-center gap-2 mb-2">
                        <Smartphone className="h-5 w-5 text-primary" />
                        <h3 className="text-xl font-semibold">Download the App</h3>
                      </div>
                      <p className="text-muted-foreground">
                        Download the Luber app from the App Store or Google Play. Create your account in minutes with
                        just your email and phone number.
                      </p>
                    </div>
                  </div>
                </CardContent>
              </Card>

              <Card>
                <CardContent className="pt-6">
                  <div className="flex items-start gap-6">
                    <div className="flex-shrink-0 inline-flex h-16 w-16 items-center justify-center rounded-full bg-primary text-primary-foreground text-2xl font-bold">
                      2
                    </div>
                    <div className="flex-1">
                      <div className="flex items-center gap-2 mb-2">
                        <Calendar className="h-5 w-5 text-primary" />
                        <h3 className="text-xl font-semibold">Choose Your Service</h3>
                      </div>
                      <p className="text-muted-foreground">
                        Select the type of oil change you need (conventional, synthetic blend, or full synthetic) and
                        pick a date and time that works for you.
                      </p>
                    </div>
                  </div>
                </CardContent>
              </Card>

              <Card>
                <CardContent className="pt-6">
                  <div className="flex items-start gap-6">
                    <div className="flex-shrink-0 inline-flex h-16 w-16 items-center justify-center rounded-full bg-primary text-primary-foreground text-2xl font-bold">
                      3
                    </div>
                    <div className="flex-1">
                      <div className="flex items-center gap-2 mb-2">
                        <MapPin className="h-5 w-5 text-primary" />
                        <h3 className="text-xl font-semibold">Set Your Location</h3>
                      </div>
                      <p className="text-muted-foreground">
                        Enter where you want the service done - your home, office, or any parking location. Our
                        technicians come to you!
                      </p>
                    </div>
                  </div>
                </CardContent>
              </Card>

              <Card>
                <CardContent className="pt-6">
                  <div className="flex items-start gap-6">
                    <div className="flex-shrink-0 inline-flex h-16 w-16 items-center justify-center rounded-full bg-primary text-primary-foreground text-2xl font-bold">
                      4
                    </div>
                    <div className="flex-1">
                      <div className="flex items-center gap-2 mb-2">
                        <Wrench className="h-5 w-5 text-primary" />
                        <h3 className="text-xl font-semibold">Technician Arrives</h3>
                      </div>
                      <p className="text-muted-foreground">
                        A certified, background-checked technician arrives at your location with all the necessary
                        equipment and supplies. Track their arrival in real-time through the app.
                      </p>
                    </div>
                  </div>
                </CardContent>
              </Card>

              <Card>
                <CardContent className="pt-6">
                  <div className="flex items-start gap-6">
                    <div className="flex-shrink-0 inline-flex h-16 w-16 items-center justify-center rounded-full bg-primary text-primary-foreground text-2xl font-bold">
                      5
                    </div>
                    <div className="flex-1">
                      <div className="flex items-center gap-2 mb-2">
                        <CreditCard className="h-5 w-5 text-primary" />
                        <h3 className="text-xl font-semibold">Service Complete & Pay</h3>
                      </div>
                      <p className="text-muted-foreground">
                        Your oil change is completed professionally in about 30 minutes. Pay securely through the app
                        with your saved payment method. No cash needed!
                      </p>
                    </div>
                  </div>
                </CardContent>
              </Card>

              <Card>
                <CardContent className="pt-6">
                  <div className="flex items-start gap-6">
                    <div className="flex-shrink-0 inline-flex h-16 w-16 items-center justify-center rounded-full bg-primary text-primary-foreground text-2xl font-bold">
                      6
                    </div>
                    <div className="flex-1">
                      <div className="flex items-center gap-2 mb-2">
                        <Star className="h-5 w-5 text-primary" />
                        <h3 className="text-xl font-semibold">Rate Your Experience</h3>
                      </div>
                      <p className="text-muted-foreground">
                        Leave a review to help other customers and support great technicians. Your feedback helps us
                        maintain the highest quality service.
                      </p>
                    </div>
                  </div>
                </CardContent>
              </Card>
            </div>

            <div className="mt-16 text-center">
              <h2 className="text-2xl font-bold mb-4">Ready to Get Started?</h2>
              <p className="text-muted-foreground mb-6">Download the app and book your first oil change today!</p>
              <Button size="lg">Download the App</Button>
            </div>
          </div>
        </section>
      </main>
    </div>
  )
}
