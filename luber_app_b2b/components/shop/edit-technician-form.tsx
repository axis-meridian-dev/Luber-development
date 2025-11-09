"use client"

import { useState, useTransition } from "react"
import { useRouter } from "next/navigation"
import { zodResolver } from "@hookform/resolvers/zod"
import { useForm } from "react-hook-form"
import { z } from "zod"
import { Plus, X, Trash2 } from "lucide-react"

import { Button } from "@/components/ui/button"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Form, FormControl, FormDescription, FormField, FormItem, FormLabel, FormMessage } from "@/components/ui/form"
import { Input } from "@/components/ui/input"
import { Textarea } from "@/components/ui/textarea"
import { Switch } from "@/components/ui/switch"
import { Badge } from "@/components/ui/badge"
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
  AlertDialogTrigger,
} from "@/components/ui/alert-dialog"
import { updateTechnician, removeTechnician } from "@/app/actions/technicians"
import { useToast } from "@/components/ui/use-toast"

const formSchema = z.object({
  license_number: z.string().min(1, "License number is required"),
  years_experience: z.coerce.number().min(0, "Experience must be 0 or greater"),
  certifications: z.array(z.string()).default([]),
  bio: z.string().optional(),
  is_available: z.boolean().default(true),
})

type FormValues = z.infer<typeof formSchema>

interface EditTechnicianFormProps {
  technician: any
  shop: any
}

export default function EditTechnicianForm({ technician, shop }: EditTechnicianFormProps) {
  const router = useRouter()
  const { toast } = useToast()
  const [isPending, startTransition] = useTransition()
  const [isRemoving, setIsRemoving] = useState(false)
  const [certificationInput, setCertificationInput] = useState("")

  const profile = technician.profiles as any

  const form = useForm<FormValues>({
    resolver: zodResolver(formSchema),
    defaultValues: {
      license_number: technician.license_number || "",
      years_experience: technician.years_experience || 0,
      certifications: technician.certifications || [],
      bio: technician.bio || "",
      is_available: technician.is_available ?? true,
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
      formData.append("license_number", values.license_number)
      formData.append("years_experience", values.years_experience.toString())
      values.certifications.forEach((cert) => formData.append("certifications", cert))
      if (values.bio) formData.append("bio", values.bio)
      formData.append("is_available", values.is_available.toString())

      const result = await updateTechnician(technician.id, formData)

      if (result.success) {
        toast({
          title: "Success",
          description: "Technician updated successfully",
        })
        router.push("/shop/technicians")
      } else {
        toast({
          title: "Error",
          description: result.error || "Failed to update technician",
          variant: "destructive",
        })
      }
    })
  }

  const handleRemove = async () => {
    setIsRemoving(true)
    const result = await removeTechnician(technician.id)

    if (result.success) {
      toast({
        title: "Success",
        description: "Technician removed from your shop",
      })
      router.push("/shop/technicians")
    } else {
      toast({
        title: "Error",
        description: result.error || "Failed to remove technician",
        variant: "destructive",
      })
      setIsRemoving(false)
    }
  }

  return (
    <div className="space-y-6">
      <Card>
        <CardHeader>
          <CardTitle>Edit Technician</CardTitle>
          <CardDescription>Update technician details and manage their status</CardDescription>
        </CardHeader>
        <CardContent>
          <div className="mb-6 space-y-3 rounded-lg border bg-muted/50 p-4">
            <div className="flex items-start justify-between">
              <div>
                <h3 className="font-semibold">{profile?.full_name || "No name set"}</h3>
                <p className="text-sm text-muted-foreground">{profile?.email}</p>
                {profile?.phone && <p className="text-sm text-muted-foreground">{profile.phone}</p>}
              </div>
              <Badge variant={technician.is_available ? "default" : "secondary"}>
                {technician.is_available ? "Available" : "Offline"}
              </Badge>
            </div>

            <div className="grid grid-cols-2 gap-4 text-sm">
              <div>
                <span className="text-muted-foreground">Rating:</span>
                <span className="ml-2 font-medium">{technician.rating?.toFixed(1) || "5.0"}/5.0</span>
              </div>
              <div>
                <span className="text-muted-foreground">Jobs Completed:</span>
                <span className="ml-2 font-medium">{technician.total_jobs || 0}</span>
              </div>
            </div>
          </div>

          <Form {...form}>
            <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-6">
              <FormField
                control={form.control}
                name="is_available"
                render={({ field }) => (
                  <FormItem className="flex flex-row items-center justify-between rounded-lg border p-4">
                    <div className="space-y-0.5">
                      <FormLabel className="text-base">Available for Jobs</FormLabel>
                      <FormDescription>
                        Toggle whether this technician can receive new job assignments
                      </FormDescription>
                    </div>
                    <FormControl>
                      <Switch checked={field.value} onCheckedChange={field.onChange} />
                    </FormControl>
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
                  {isPending ? "Saving..." : "Save Changes"}
                </Button>
                <Button type="button" variant="outline" onClick={() => router.push("/shop/technicians")}>
                  Cancel
                </Button>
              </div>
            </form>
          </Form>
        </CardContent>
      </Card>

      <Card className="border-destructive">
        <CardHeader>
          <CardTitle className="text-destructive">Danger Zone</CardTitle>
          <CardDescription>Remove this technician from your shop</CardDescription>
        </CardHeader>
        <CardContent>
          <AlertDialog>
            <AlertDialogTrigger asChild>
              <Button variant="destructive" disabled={isRemoving}>
                <Trash2 className="h-4 w-4 mr-2" />
                {isRemoving ? "Removing..." : "Remove Technician"}
              </Button>
            </AlertDialogTrigger>
            <AlertDialogContent>
              <AlertDialogHeader>
                <AlertDialogTitle>Are you sure?</AlertDialogTitle>
                <AlertDialogDescription>
                  This will remove {profile?.full_name || "this technician"} from your shop. They will no longer be able
                  to receive job assignments from your shop.
                  <br />
                  <br />
                  This action cannot be undone.
                </AlertDialogDescription>
              </AlertDialogHeader>
              <AlertDialogFooter>
                <AlertDialogCancel>Cancel</AlertDialogCancel>
                <AlertDialogAction onClick={handleRemove} className="bg-destructive text-destructive-foreground">
                  Remove Technician
                </AlertDialogAction>
              </AlertDialogFooter>
            </AlertDialogContent>
          </AlertDialog>
        </CardContent>
      </Card>
    </div>
  )
}
