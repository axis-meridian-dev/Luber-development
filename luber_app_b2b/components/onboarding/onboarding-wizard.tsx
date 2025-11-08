"use client"

import { useState } from "react"
import { useRouter } from "next/navigation"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { CheckCircle2, Building2, FileText, CreditCard, Loader2 } from "lucide-react"
import { createBrowserClient } from "@/lib/supabase/client"

interface OnboardingWizardProps {
  existingShop: any
}

export default function OnboardingWizard({ existingShop }: OnboardingWizardProps) {
  const router = useRouter()
  const [step, setStep] = useState(1)
  const [loading, setLoading] = useState(false)
  const [formData, setFormData] = useState({
    // Business Info
    shop_name: existingShop?.shop_name || "",
    business_legal_name: existingShop?.business_legal_name || "",
    business_license_number: existingShop?.business_license_number || "",
    insurance_policy_number: existingShop?.insurance_policy_number || "",
    insurance_expiry_date: existingShop?.insurance_expiry_date || "",
    tax_id: existingShop?.tax_id || "",

    // Contact Info
    business_email: existingShop?.business_email || "",
    business_phone: existingShop?.business_phone || "",
    business_address: existingShop?.business_address || "",
    business_city: existingShop?.business_city || "",
    business_state: existingShop?.business_state || "",
    business_zip: existingShop?.business_zip || "",

    // Subscription
    subscription_tier: existingShop?.subscription_tier || "solo",
    technician_count: 1,
  })

  const handleInputChange = (field: string, value: string | number) => {
    setFormData((prev) => ({ ...prev, [field]: value }))
  }

  const handleStep1Submit = async () => {
    setLoading(true)
    try {
      const supabase = createBrowserClient()
      const {
        data: { user },
      } = await supabase.auth.getUser()

      if (!user) throw new Error("Not authenticated")

      const shopData = {
        owner_id: user.id,
        shop_name: formData.shop_name,
        business_legal_name: formData.business_legal_name,
        business_license_number: formData.business_license_number,
        insurance_policy_number: formData.insurance_policy_number,
        insurance_expiry_date: formData.insurance_expiry_date,
        tax_id: formData.tax_id,
        business_email: formData.business_email,
        business_phone: formData.business_phone,
        business_address: formData.business_address,
        business_city: formData.business_city,
        business_state: formData.business_state,
        business_zip: formData.business_zip,
        subscription_tier: formData.subscription_tier,
        onboarding_completed: false,
      }

      if (existingShop) {
        await supabase.from("shops").update(shopData).eq("id", existingShop.id)
      } else {
        await supabase.from("shops").insert(shopData)
      }

      setStep(2)
    } catch (error) {
      console.error("Error saving shop:", error)
      alert("Failed to save shop information")
    } finally {
      setLoading(false)
    }
  }

  const handleStep2Submit = () => {
    setStep(3)
  }

  const steps = [
    { number: 1, title: "Business Info", icon: Building2 },
    { number: 2, title: "Choose Plan", icon: FileText },
    { number: 3, title: "Payment", icon: CreditCard },
  ]

  return (
    <div className="container max-w-4xl py-12">
      {/* Progress Steps */}
      <div className="mb-8">
        <div className="flex items-center justify-between">
          {steps.map((s, idx) => (
            <div key={s.number} className="flex items-center flex-1">
              <div className="flex flex-col items-center">
                <div
                  className={`flex h-12 w-12 items-center justify-center rounded-full border-2 ${
                    step >= s.number
                      ? "border-primary bg-primary text-primary-foreground"
                      : "border-muted-foreground/30 bg-background text-muted-foreground"
                  }`}
                >
                  {step > s.number ? <CheckCircle2 className="h-6 w-6" /> : <s.icon className="h-6 w-6" />}
                </div>
                <span className="mt-2 text-sm font-medium">{s.title}</span>
              </div>
              {idx < steps.length - 1 && (
                <div className={`h-0.5 flex-1 mx-4 ${step > s.number ? "bg-primary" : "bg-muted-foreground/30"}`} />
              )}
            </div>
          ))}
        </div>
      </div>

      {/* Step 1: Business Information */}
      {step === 1 && (
        <Card>
          <CardHeader>
            <CardTitle>Business Information</CardTitle>
            <CardDescription>Tell us about your business. We'll verify your license and insurance.</CardDescription>
          </CardHeader>
          <CardContent className="space-y-6">
            <div className="grid md:grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label htmlFor="shop_name">Shop Name *</Label>
                <Input
                  id="shop_name"
                  value={formData.shop_name}
                  onChange={(e) => handleInputChange("shop_name", e.target.value)}
                  placeholder="Joe's Mobile Oil Change"
                  required
                />
              </div>
              <div className="space-y-2">
                <Label htmlFor="business_legal_name">Legal Business Name *</Label>
                <Input
                  id="business_legal_name"
                  value={formData.business_legal_name}
                  onChange={(e) => handleInputChange("business_legal_name", e.target.value)}
                  placeholder="Joe's Auto Services LLC"
                  required
                />
              </div>
            </div>

            <div className="grid md:grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label htmlFor="business_license_number">Business License Number *</Label>
                <Input
                  id="business_license_number"
                  value={formData.business_license_number}
                  onChange={(e) => handleInputChange("business_license_number", e.target.value)}
                  placeholder="BL-123456"
                  required
                />
              </div>
              <div className="space-y-2">
                <Label htmlFor="tax_id">Tax ID (EIN)</Label>
                <Input
                  id="tax_id"
                  value={formData.tax_id}
                  onChange={(e) => handleInputChange("tax_id", e.target.value)}
                  placeholder="12-3456789"
                />
              </div>
            </div>

            <div className="grid md:grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label htmlFor="insurance_policy_number">Insurance Policy Number *</Label>
                <Input
                  id="insurance_policy_number"
                  value={formData.insurance_policy_number}
                  onChange={(e) => handleInputChange("insurance_policy_number", e.target.value)}
                  placeholder="INS-789012"
                  required
                />
              </div>
              <div className="space-y-2">
                <Label htmlFor="insurance_expiry_date">Insurance Expiry Date *</Label>
                <Input
                  id="insurance_expiry_date"
                  type="date"
                  value={formData.insurance_expiry_date}
                  onChange={(e) => handleInputChange("insurance_expiry_date", e.target.value)}
                  required
                />
              </div>
            </div>

            <div className="grid md:grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label htmlFor="business_email">Business Email *</Label>
                <Input
                  id="business_email"
                  type="email"
                  value={formData.business_email}
                  onChange={(e) => handleInputChange("business_email", e.target.value)}
                  placeholder="contact@joesmobile.com"
                  required
                />
              </div>
              <div className="space-y-2">
                <Label htmlFor="business_phone">Business Phone *</Label>
                <Input
                  id="business_phone"
                  type="tel"
                  value={formData.business_phone}
                  onChange={(e) => handleInputChange("business_phone", e.target.value)}
                  placeholder="(555) 123-4567"
                  required
                />
              </div>
            </div>

            <div className="space-y-2">
              <Label htmlFor="business_address">Business Address *</Label>
              <Input
                id="business_address"
                value={formData.business_address}
                onChange={(e) => handleInputChange("business_address", e.target.value)}
                placeholder="123 Main St"
                required
              />
            </div>

            <div className="grid md:grid-cols-3 gap-4">
              <div className="space-y-2">
                <Label htmlFor="business_city">City *</Label>
                <Input
                  id="business_city"
                  value={formData.business_city}
                  onChange={(e) => handleInputChange("business_city", e.target.value)}
                  placeholder="San Francisco"
                  required
                />
              </div>
              <div className="space-y-2">
                <Label htmlFor="business_state">State *</Label>
                <Input
                  id="business_state"
                  value={formData.business_state}
                  onChange={(e) => handleInputChange("business_state", e.target.value)}
                  placeholder="CA"
                  maxLength={2}
                  required
                />
              </div>
              <div className="space-y-2">
                <Label htmlFor="business_zip">ZIP Code *</Label>
                <Input
                  id="business_zip"
                  value={formData.business_zip}
                  onChange={(e) => handleInputChange("business_zip", e.target.value)}
                  placeholder="94102"
                  required
                />
              </div>
            </div>

            <div className="flex justify-end gap-4">
              <Button onClick={handleStep1Submit} disabled={loading}>
                {loading && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
                Continue to Plan Selection
              </Button>
            </div>
          </CardContent>
        </Card>
      )}

      {/* Step 2: Choose Plan */}
      {step === 2 && (
        <Card>
          <CardHeader>
            <CardTitle>Choose Your Plan</CardTitle>
            <CardDescription>Select the plan that best fits your business needs</CardDescription>
          </CardHeader>
          <CardContent className="space-y-6">
            <div className="grid md:grid-cols-2 gap-6">
              <Card
                className={`cursor-pointer transition-all ${
                  formData.subscription_tier === "solo" ? "border-primary shadow-lg" : ""
                }`}
                onClick={() => handleInputChange("subscription_tier", "solo")}
              >
                <CardContent className="pt-6">
                  <div className="mb-4">
                    <h3 className="text-2xl font-bold mb-2">Solo Mechanic</h3>
                    <div className="flex items-baseline gap-2 mb-2">
                      <span className="text-4xl font-bold">$99</span>
                      <span className="text-muted-foreground">/month</span>
                    </div>
                    <p className="text-sm text-muted-foreground">+ 8% transaction fee</p>
                  </div>
                  <ul className="space-y-2 text-sm">
                    <li className="flex items-start gap-2">
                      <CheckCircle2 className="h-4 w-4 text-primary flex-shrink-0 mt-0.5" />
                      <span>Single technician account</span>
                    </li>
                    <li className="flex items-start gap-2">
                      <CheckCircle2 className="h-4 w-4 text-primary flex-shrink-0 mt-0.5" />
                      <span>Unlimited bookings</span>
                    </li>
                    <li className="flex items-start gap-2">
                      <CheckCircle2 className="h-4 w-4 text-primary flex-shrink-0 mt-0.5" />
                      <span>Payment processing</span>
                    </li>
                    <li className="flex items-start gap-2">
                      <CheckCircle2 className="h-4 w-4 text-primary flex-shrink-0 mt-0.5" />
                      <span>Basic analytics</span>
                    </li>
                  </ul>
                </CardContent>
              </Card>

              <Card
                className={`cursor-pointer transition-all ${
                  formData.subscription_tier === "business" ? "border-primary shadow-lg" : ""
                }`}
                onClick={() => handleInputChange("subscription_tier", "business")}
              >
                <CardContent className="pt-6">
                  <div className="mb-4">
                    <h3 className="text-2xl font-bold mb-2">Business</h3>
                    <div className="flex items-baseline gap-2 mb-2">
                      <span className="text-4xl font-bold">$299</span>
                      <span className="text-muted-foreground">/month</span>
                    </div>
                    <p className="text-sm text-muted-foreground">+ $49/tech + 5% transaction fee</p>
                  </div>
                  <ul className="space-y-2 text-sm">
                    <li className="flex items-start gap-2">
                      <CheckCircle2 className="h-4 w-4 text-primary flex-shrink-0 mt-0.5" />
                      <span>Up to 10 technicians</span>
                    </li>
                    <li className="flex items-start gap-2">
                      <CheckCircle2 className="h-4 w-4 text-primary flex-shrink-0 mt-0.5" />
                      <span>Multi-technician dispatch</span>
                    </li>
                    <li className="flex items-start gap-2">
                      <CheckCircle2 className="h-4 w-4 text-primary flex-shrink-0 mt-0.5" />
                      <span>Custom pricing packages</span>
                    </li>
                    <li className="flex items-start gap-2">
                      <CheckCircle2 className="h-4 w-4 text-primary flex-shrink-0 mt-0.5" />
                      <span>White-label branding</span>
                    </li>
                  </ul>
                </CardContent>
              </Card>
            </div>

            {formData.subscription_tier === "business" && (
              <div className="space-y-2">
                <Label htmlFor="technician_count">Number of Technicians</Label>
                <Select
                  value={formData.technician_count.toString()}
                  onValueChange={(value) => handleInputChange("technician_count", Number.parseInt(value))}
                >
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    {[1, 2, 3, 4, 5, 6, 7, 8, 9, 10].map((num) => (
                      <SelectItem key={num} value={num.toString()}>
                        {num} {num === 1 ? "Technician" : "Technicians"}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
            )}

            <div className="flex justify-between gap-4">
              <Button variant="outline" onClick={() => setStep(1)}>
                Back
              </Button>
              <Button onClick={handleStep2Submit}>Continue to Payment</Button>
            </div>
          </CardContent>
        </Card>
      )}

      {/* Step 3: Payment */}
      {step === 3 && (
        <Card>
          <CardHeader>
            <CardTitle>Complete Your Subscription</CardTitle>
            <CardDescription>Start your 14-day free trial. No credit card required.</CardDescription>
          </CardHeader>
          <CardContent className="space-y-6">
            <div className="rounded-lg border p-6 bg-muted/50">
              <h3 className="font-semibold mb-4">Order Summary</h3>
              <div className="space-y-2">
                <div className="flex justify-between">
                  <span>Plan:</span>
                  <span className="font-medium">
                    {formData.subscription_tier === "solo" ? "Solo Mechanic" : "Business"}
                  </span>
                </div>
                {formData.subscription_tier === "business" && (
                  <div className="flex justify-between">
                    <span>Technicians:</span>
                    <span className="font-medium">{formData.technician_count}</span>
                  </div>
                )}
                <div className="flex justify-between text-sm text-muted-foreground">
                  <span>Trial Period:</span>
                  <span>14 days free</span>
                </div>
                <div className="border-t pt-2 mt-2">
                  <div className="flex justify-between font-semibold">
                    <span>After Trial:</span>
                    <span>
                      ${formData.subscription_tier === "solo" ? "99" : 299 + (formData.technician_count - 1) * 49}
                      /month
                    </span>
                  </div>
                </div>
              </div>
            </div>

            <div className="text-center text-sm text-muted-foreground">
              <p>You won't be charged during your 14-day trial.</p>
              <p>Cancel anytime before the trial ends to avoid charges.</p>
            </div>

            <div className="flex justify-between gap-4">
              <Button variant="outline" onClick={() => setStep(2)}>
                Back
              </Button>
              <Button onClick={() => router.push("/shop/subscription/checkout")}>Start Free Trial</Button>
            </div>
          </CardContent>
        </Card>
      )}
    </div>
  )
}
