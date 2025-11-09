"use client"

import { useState, useTransition } from "react"
import { useRouter } from "next/navigation"
import { zodResolver } from "@hookform/resolvers/zod"
import { useForm } from "react-hook-form"
import { z } from "zod"
import { ArrowLeft, Plus, X } from "lucide-react"
import Link from "next/link"

import { Button } from "@/components/ui/button"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Form, FormControl, FormDescription, FormField, FormItem, FormLabel, FormMessage } from "@/components/ui/form"
import { Input } from "@/components/ui/input"
import { Textarea } from "@/components/ui/textarea"
import { inviteTechnician } from "@/app/actions/technicians"
import { useToast } from "@/components/ui/use-toast"

const formSchema = z.object({
  email: z.string().email("Invalid email address"),
  full_name: z.string().optional(),
  license_number: z.string().min(1, "License number is required"),
  years_experience: z.coerce.number().min(0, "Experience must be 0 or greater").default(0),
  certifications: z.array(z.string()).default([]),
  phone: z.string().optional(),
  bio: z.string().optional(),
})

type FormValues = z.infer<typeof formSchema>

export default function AddTechnicianPage() {
  const router = useRouter()
  const { toast } = useToast()
  const [isPending, startTransition] = useTransition()
  const [certificationInput, setCertificationInput] = useState("")

  const form = useForm<FormValues>({
    resolver: zodResolver(formSchema),
    defaultValues: {
      email: "",
      full_name: "",
      license_number: "",
      years_experience: 0,
      certifications: [],
      phone: "",
      bio: "",
    },
  })

  const certifications = form.watch("certifications")

  const addCertification = () => {
    if (certificationInput.trim()) {
      const current = form.getValues("certifications")
      if (!current.includes(certificationInput.trim())) {
        form.setValue("certifications", [...current, certificationInput.trim()])
        setCertificationInput("")
      }
    }
  }

  const removeCertification = (cert: string) => {
    const current = form.getValues("certifications")
    form.setValue(
      "certifications",
      current.filter((c) => c !== cert)
    )
  }

  const onSubmit = async (values: FormValues) => {
    startTransition(async () => {
      const formData = new FormData()
      formData.append("email", values.email)
      if (values.full_name) formData.append("full_name", values.full_name)
      formData.append("license_number", values.license_number)
      formData.append("years_experience", values.years_experience.toString())
      values.certifications.forEach((cert) => formData.append("certifications", cert))
      if (values.phone) formData.append("phone", values.phone)
      if (values.bio) formData.append("bio", values.bio)

      const result = await inviteTechnician(formData)

      if (result.success) {
        toast({
          title: "Success",
          description: "Technician invited successfully",
        })
        router.push("/shop/technicians")
      } else {
        toast({
          title: "Error",
          description: result.error || "Failed to invite technician",
          variant: "destructive",
        })
      }
    })
  }

  return (
    <div className="container max-w-3xl py-8">
      <div className="mb-6">
        <Link href="/shop/technicians">
          <Button variant="ghost" size="sm">
            <ArrowLeft className="h-4 w-4 mr-2" />
            Back to Technicians
          </Button>
        </Link>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>Invite Technician</CardTitle>
          <CardDescription>
            Send an invitation to a technician to join your shop. They will receive an email with instructions to
            complete their profile.
          </CardDescription>
        </CardHeader>
        <CardContent>
          <Form {...form}>
            <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-6">
              <FormField
                control={form.control}
                name="email"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Email *</FormLabel>
                    <FormControl>
                      <Input placeholder="technician@example.com" type="email" {...field} />
                    </FormControl>
                    <FormDescription>The email address where the invitation will be sent</FormDescription>
                    <FormMessage />
                  </FormItem>
                )}
              />

              <FormField
                control={form.control}
                name="full_name"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Full Name</FormLabel>
                    <FormControl>
                      <Input placeholder="John Smith" {...field} />
                    </FormControl>
                    <FormDescription>Technician can update this later when they accept the invite</FormDescription>
                    <FormMessage />
                  </FormItem>
                )}
              />

              <FormField
                control={form.control}
                name="phone"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Phone Number</FormLabel>
                    <FormControl>
                      <Input placeholder="(555) 123-4567" {...field} />
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />

              <FormField
                control={form.control}
                name="license_number"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>License Number *</FormLabel>
                    <FormControl>
                      <Input placeholder="LIC123456" {...field} />
                    </FormControl>
                    <FormDescription>Technician's professional license number</FormDescription>
                    <FormMessage />
                  </FormItem>
                )}
              />

              <FormField
                control={form.control}
                name="years_experience"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Years of Experience</FormLabel>
                    <FormControl>
                      <Input type="number" min="0" placeholder="5" {...field} />
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />

              <FormField
                control={form.control}
                name="certifications"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Certifications</FormLabel>
                    <div className="space-y-3">
                      <div className="flex gap-2">
                        <Input
                          placeholder="e.g., ASE Certified"
                          value={certificationInput}
                          onChange={(e) => setCertificationInput(e.target.value)}
                          onKeyDown={(e) => {
                            if (e.key === "Enter") {
                              e.preventDefault()
                              addCertification()
                            }
                          }}
                        />
                        <Button type="button" variant="secondary" size="sm" onClick={addCertification}>
                          <Plus className="h-4 w-4" />
                        </Button>
                      </div>
                      {certifications.length > 0 && (
                        <div className="flex flex-wrap gap-2">
                          {certifications.map((cert) => (
                            <div
                              key={cert}
                              className="inline-flex items-center gap-1 rounded-full bg-primary/10 px-3 py-1 text-sm font-medium text-primary"
                            >
                              {cert}
                              <button
                                type="button"
                                onClick={() => removeCertification(cert)}
                                className="ml-1 hover:text-primary/70"
                              >
                                <X className="h-3 w-3" />
                              </button>
                            </div>
                          ))}
                        </div>
                      )}
                    </div>
                    <FormDescription>Add professional certifications (press Enter or click + to add)</FormDescription>
                    <FormMessage />
                  </FormItem>
                )}
              />

              <FormField
                control={form.control}
                name="bio"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Bio</FormLabel>
                    <FormControl>
                      <Textarea
                        placeholder="Tell us about this technician's expertise and specializations..."
                        className="min-h-[100px]"
                        {...field}
                      />
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />

              <div className="flex gap-3 pt-4">
                <Button type="submit" disabled={isPending}>
                  {isPending ? "Sending Invitation..." : "Send Invitation"}
                </Button>
                <Button type="button" variant="outline" onClick={() => router.push("/shop/technicians")}>
                  Cancel
                </Button>
              </div>
            </form>
          </Form>
        </CardContent>
      </Card>
    </div>
  )
}
