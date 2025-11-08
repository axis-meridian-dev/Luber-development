import { Button } from "@/components/ui/button"
import { Card, CardContent } from "@/components/ui/card"
import { Wrench, CheckCircle2, DollarSign, Calendar, Shield } from "lucide-react"
import Link from "next/link"

export default function BecomeTechnicianPage() {
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
            <Link href="/contact" className="text-sm font-medium hover:text-primary transition-colors">
              Contact
            </Link>
          </nav>
        </div>
      </header>

      <main className="flex-1">
        <section className="py-20">
          <div className="container">
            <div className="max-w-3xl mx-auto text-center mb-16">
              <h1 className="text-4xl font-bold mb-4">Become a Luber Technician</h1>
              <p className="text-lg text-muted-foreground">
                Join our network of professional mobile technicians and build your own business on your schedule.
              </p>
            </div>

            <div className="grid md:grid-cols-3 gap-8 max-w-5xl mx-auto mb-16">
              <Card>
                <CardContent className="pt-6 text-center">
                  <div className="mb-4 mx-auto inline-flex h-12 w-12 items-center justify-center rounded-lg bg-primary/10">
                    <Calendar className="h-6 w-6 text-primary" />
                  </div>
                  <h3 className="text-xl font-semibold mb-2">Flexible Schedule</h3>
                  <p className="text-muted-foreground">Work when you want. Set your own hours and availability.</p>
                </CardContent>
              </Card>

              <Card>
                <CardContent className="pt-6 text-center">
                  <div className="mb-4 mx-auto inline-flex h-12 w-12 items-center justify-center rounded-lg bg-primary/10">
                    <DollarSign className="h-6 w-6 text-primary" />
                  </div>
                  <h3 className="text-xl font-semibold mb-2">Great Earnings</h3>
                  <p className="text-muted-foreground">Earn $30-50 per job. Top technicians make $1,000+ per week.</p>
                </CardContent>
              </Card>

              <Card>
                <CardContent className="pt-6 text-center">
                  <div className="mb-4 mx-auto inline-flex h-12 w-12 items-center justify-center rounded-lg bg-primary/10">
                    <Shield className="h-6 w-6 text-primary" />
                  </div>
                  <h3 className="text-xl font-semibold mb-2">Full Support</h3>
                  <p className="text-muted-foreground">We provide the platform, insurance, and customer support.</p>
                </CardContent>
              </Card>
            </div>

            <div className="max-w-3xl mx-auto mb-16">
              <h2 className="text-2xl font-bold mb-6 text-center">Requirements</h2>
              <Card>
                <CardContent className="pt-6">
                  <ul className="space-y-4">
                    <li className="flex items-start gap-3">
                      <CheckCircle2 className="h-6 w-6 text-primary flex-shrink-0 mt-0.5" />
                      <div>
                        <strong>Valid Driver's License</strong>
                        <p className="text-sm text-muted-foreground">Must be at least 21 years old</p>
                      </div>
                    </li>
                    <li className="flex items-start gap-3">
                      <CheckCircle2 className="h-6 w-6 text-primary flex-shrink-0 mt-0.5" />
                      <div>
                        <strong>ASE Certification or Equivalent</strong>
                        <p className="text-sm text-muted-foreground">
                          Proof of automotive service training or 2+ years experience
                        </p>
                      </div>
                    </li>
                    <li className="flex items-start gap-3">
                      <CheckCircle2 className="h-6 w-6 text-primary flex-shrink-0 mt-0.5" />
                      <div>
                        <strong>Background Check</strong>
                        <p className="text-sm text-muted-foreground">Clean criminal record required</p>
                      </div>
                    </li>
                    <li className="flex items-start gap-3">
                      <CheckCircle2 className="h-6 w-6 text-primary flex-shrink-0 mt-0.5" />
                      <div>
                        <strong>Reliable Vehicle</strong>
                        <p className="text-sm text-muted-foreground">
                          To transport equipment and supplies to job sites
                        </p>
                      </div>
                    </li>
                    <li className="flex items-start gap-3">
                      <CheckCircle2 className="h-6 w-6 text-primary flex-shrink-0 mt-0.5" />
                      <div>
                        <strong>Basic Tools & Equipment</strong>
                        <p className="text-sm text-muted-foreground">
                          Oil drain pan, wrenches, jack stands (we can help you get started)
                        </p>
                      </div>
                    </li>
                    <li className="flex items-start gap-3">
                      <CheckCircle2 className="h-6 w-6 text-primary flex-shrink-0 mt-0.5" />
                      <div>
                        <strong>Smartphone</strong>
                        <p className="text-sm text-muted-foreground">iOS or Android device to use the Luber app</p>
                      </div>
                    </li>
                  </ul>
                </CardContent>
              </Card>
            </div>

            <div className="max-w-3xl mx-auto mb-16">
              <h2 className="text-2xl font-bold mb-6 text-center">How to Apply</h2>
              <div className="space-y-6">
                <Card>
                  <CardContent className="pt-6">
                    <div className="flex items-start gap-4">
                      <div className="flex-shrink-0 inline-flex h-10 w-10 items-center justify-center rounded-full bg-primary text-primary-foreground font-bold">
                        1
                      </div>
                      <div>
                        <h3 className="font-semibold mb-1">Download the Technician App</h3>
                        <p className="text-sm text-muted-foreground">
                          Get the Luber Technician app from the App Store or Google Play
                        </p>
                      </div>
                    </div>
                  </CardContent>
                </Card>

                <Card>
                  <CardContent className="pt-6">
                    <div className="flex items-start gap-4">
                      <div className="flex-shrink-0 inline-flex h-10 w-10 items-center justify-center rounded-full bg-primary text-primary-foreground font-bold">
                        2
                      </div>
                      <div>
                        <h3 className="font-semibold mb-1">Complete Your Profile</h3>
                        <p className="text-sm text-muted-foreground">
                          Submit your certifications, license, and background check authorization
                        </p>
                      </div>
                    </div>
                  </CardContent>
                </Card>

                <Card>
                  <CardContent className="pt-6">
                    <div className="flex items-start gap-4">
                      <div className="flex-shrink-0 inline-flex h-10 w-10 items-center justify-center rounded-full bg-primary text-primary-foreground font-bold">
                        3
                      </div>
                      <div>
                        <h3 className="font-semibold mb-1">Get Approved</h3>
                        <p className="text-sm text-muted-foreground">
                          We'll review your application within 2-3 business days
                        </p>
                      </div>
                    </div>
                  </CardContent>
                </Card>

                <Card>
                  <CardContent className="pt-6">
                    <div className="flex items-start gap-4">
                      <div className="flex-shrink-0 inline-flex h-10 w-10 items-center justify-center rounded-full bg-primary text-primary-foreground font-bold">
                        4
                      </div>
                      <div>
                        <h3 className="font-semibold mb-1">Start Earning</h3>
                        <p className="text-sm text-muted-foreground">
                          Once approved, turn on your availability and start accepting jobs!
                        </p>
                      </div>
                    </div>
                  </CardContent>
                </Card>
              </div>
            </div>

            <div className="text-center">
              <h2 className="text-2xl font-bold mb-4">Ready to Join?</h2>
              <p className="text-muted-foreground mb-6">Download the technician app and start your application today</p>
              <Button size="lg">Download Technician App</Button>
            </div>
          </div>
        </section>
      </main>
    </div>
  )
}
