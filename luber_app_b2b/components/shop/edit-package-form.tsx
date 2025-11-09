"use client"

import { useRouter } from "next/navigation"
import { useState } from "react"
import { useForm } from "react-hook-form"
import { zodResolver } from "@hookform/resolvers/zod"
import { z } from "zod"
import { ArrowLeft, Trash2 } from "lucide-react"
import Link from "next/link"

import { Button } from "@/components/ui/button"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Form, FormControl, FormDescription, FormField, FormItem, FormLabel, FormMessage } from "@/components/ui/form"
import { Input } from "@/components/ui/input"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { Textarea } from "@/components/ui/textarea"
import { Checkbox } from "@/components/ui/checkbox"
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
import { updatePackage, deletePackage } from "@/app/actions/packages"
import { ShopServicePackage } from "@/lib/types/shop"

const formSchema = z.object({
  package_name: z.string().min(1, "Package name is required").max(100),
  description: z.string().optional(),
  price: z.string().min(1, "Price is required"),
  estimated_duration_minutes: z.string().min(1, "Duration is required"),
  oil_brand: z.string().optional(),
  oil_type: z.enum(["conventional", "synthetic_blend", "full_synthetic", "high_mileage", "diesel"]).optional(),
  includes_filter: z.boolean().default(true),
  includes_inspection: z.boolean().default(false),
})

type FormValues = z.infer<typeof formSchema>

interface EditPackageFormProps {
  packageData: ShopServicePackage
  shopId: string
}

export default function EditPackageForm({ packageData, shopId }: EditPackageFormProps) {
  const router = useRouter()
  const [isSubmitting, setIsSubmitting] = useState(false)
  const [isDeleting, setIsDeleting] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false)

  const form = useForm<FormValues>({
    resolver: zodResolver(formSchema),
    defaultValues: {
      package_name: packageData.package_name,
      description: packageData.description || "",
      price: packageData.price.toString(),
      estimated_duration_minutes: packageData.estimated_duration_minutes.toString(),
      oil_brand: packageData.oil_brand || "",
      oil_type: (packageData.oil_type as any) || undefined,
      includes_filter: packageData.includes_filter,
      includes_inspection: packageData.includes_inspection,
    },
  })

  async function onSubmit(values: FormValues) {
    setIsSubmitting(true)
    setError(null)

    try {
      // Convert string values to numbers
      const updateData = {
        package_name: values.package_name,
        description: values.description || "",
        price: parseFloat(values.price),
        estimated_duration_minutes: parseInt(values.estimated_duration_minutes, 10),
        oil_brand: values.oil_brand || "",
        oil_type: values.oil_type,
        includes_filter: values.includes_filter,
        includes_inspection: values.includes_inspection,
      }

      const result = await updatePackage(packageData.id, updateData)

      if (result.success) {
        router.push("/shop/packages")
        router.refresh()
      } else {
        setError(result.error || "Failed to update package")
      }
    } catch (err: any) {
      console.error("Error updating package:", err)
      setError(err.message || "An unexpected error occurred")
    } finally {
      setIsSubmitting(false)
    }
  }

  async function handleDelete() {
    setIsDeleting(true)
    setError(null)

    try {
      const result = await deletePackage(packageData.id)

      if (result.success) {
        router.push("/shop/packages")
        router.refresh()
      } else {
        setError(result.error || "Failed to delete package")
        setDeleteDialogOpen(false)
      }
    } catch (err: any) {
      console.error("Error deleting package:", err)
      setError(err.message || "An unexpected error occurred")
      setDeleteDialogOpen(false)
    } finally {
      setIsDeleting(false)
    }
  }

  return (
    <div className="container max-w-3xl py-8">
      <div className="mb-6 flex items-center justify-between">
        <Link href="/shop/packages" className="inline-flex items-center text-sm text-muted-foreground hover:text-foreground transition-colors">
          <ArrowLeft className="h-4 w-4 mr-2" />
          Back to Packages
        </Link>

        <AlertDialog open={deleteDialogOpen} onOpenChange={setDeleteDialogOpen}>
          <AlertDialogTrigger asChild>
            <Button variant="destructive" size="sm" disabled={isDeleting}>
              <Trash2 className="h-4 w-4 mr-2" />
              Delete Package
            </Button>
          </AlertDialogTrigger>
          <AlertDialogContent>
            <AlertDialogHeader>
              <AlertDialogTitle>Are you sure?</AlertDialogTitle>
              <AlertDialogDescription>
                This will delete the service package "{packageData.package_name}".
                {packageData.is_active && " If this package is in use by existing bookings, it will be deactivated instead of deleted."}
              </AlertDialogDescription>
            </AlertDialogHeader>
            <AlertDialogFooter>
              <AlertDialogCancel disabled={isDeleting}>Cancel</AlertDialogCancel>
              <AlertDialogAction onClick={handleDelete} disabled={isDeleting} className="bg-destructive hover:bg-destructive/90">
                {isDeleting ? "Deleting..." : "Delete"}
              </AlertDialogAction>
            </AlertDialogFooter>
          </AlertDialogContent>
        </AlertDialog>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>Edit Service Package</CardTitle>
          <CardDescription>
            Update the details of this service package
          </CardDescription>
        </CardHeader>
        <CardContent>
          {error && (
            <div className="mb-6 p-4 bg-destructive/10 border border-destructive/20 text-destructive rounded-md text-sm">
              {error}
            </div>
          )}

          <Form {...form}>
            <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-6">
              <FormField
                control={form.control}
                name="package_name"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Package Name</FormLabel>
                    <FormControl>
                      <Input placeholder="e.g., Conventional Oil Change" {...field} />
                    </FormControl>
                    <FormDescription>
                      A descriptive name for this service package
                    </FormDescription>
                    <FormMessage />
                  </FormItem>
                )}
              />

              <FormField
                control={form.control}
                name="description"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Description (Optional)</FormLabel>
                    <FormControl>
                      <Textarea
                        placeholder="Describe what's included in this package..."
                        className="min-h-24"
                        {...field}
                      />
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />

              <div className="grid gap-6 md:grid-cols-2">
                <FormField
                  control={form.control}
                  name="price"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>Price ($)</FormLabel>
                      <FormControl>
                        <Input
                          type="number"
                          step="0.01"
                          min="0"
                          placeholder="49.99"
                          {...field}
                        />
                      </FormControl>
                      <FormDescription>
                        Customer price before fees
                      </FormDescription>
                      <FormMessage />
                    </FormItem>
                  )}
                />

                <FormField
                  control={form.control}
                  name="estimated_duration_minutes"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>Duration (minutes)</FormLabel>
                      <FormControl>
                        <Input
                          type="number"
                          min="1"
                          max="1440"
                          placeholder="30"
                          {...field}
                        />
                      </FormControl>
                      <FormDescription>
                        Estimated service time
                      </FormDescription>
                      <FormMessage />
                    </FormItem>
                  )}
                />
              </div>

              <div className="grid gap-6 md:grid-cols-2">
                <FormField
                  control={form.control}
                  name="oil_type"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>Oil Type (Optional)</FormLabel>
                      <Select onValueChange={field.onChange} value={field.value}>
                        <FormControl>
                          <SelectTrigger>
                            <SelectValue placeholder="Select oil type" />
                          </SelectTrigger>
                        </FormControl>
                        <SelectContent>
                          <SelectItem value="conventional">Conventional</SelectItem>
                          <SelectItem value="synthetic_blend">Synthetic Blend</SelectItem>
                          <SelectItem value="full_synthetic">Full Synthetic</SelectItem>
                          <SelectItem value="high_mileage">High Mileage</SelectItem>
                          <SelectItem value="diesel">Diesel</SelectItem>
                        </SelectContent>
                      </Select>
                      <FormMessage />
                    </FormItem>
                  )}
                />

                <FormField
                  control={form.control}
                  name="oil_brand"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>Oil Brand (Optional)</FormLabel>
                      <FormControl>
                        <Input placeholder="e.g., Castrol, Mobil 1" {...field} />
                      </FormControl>
                      <FormMessage />
                    </FormItem>
                  )}
                />
              </div>

              <div className="space-y-4">
                <h3 className="text-sm font-medium">Included Services</h3>

                <FormField
                  control={form.control}
                  name="includes_filter"
                  render={({ field }) => (
                    <FormItem className="flex flex-row items-start space-x-3 space-y-0">
                      <FormControl>
                        <Checkbox
                          checked={field.value}
                          onCheckedChange={field.onChange}
                        />
                      </FormControl>
                      <div className="space-y-1 leading-none">
                        <FormLabel className="font-normal">
                          Oil Filter Replacement
                        </FormLabel>
                        <FormDescription>
                          Includes new oil filter
                        </FormDescription>
                      </div>
                    </FormItem>
                  )}
                />

                <FormField
                  control={form.control}
                  name="includes_inspection"
                  render={({ field }) => (
                    <FormItem className="flex flex-row items-start space-x-3 space-y-0">
                      <FormControl>
                        <Checkbox
                          checked={field.value}
                          onCheckedChange={field.onChange}
                        />
                      </FormControl>
                      <div className="space-y-1 leading-none">
                        <FormLabel className="font-normal">
                          Multi-Point Inspection
                        </FormLabel>
                        <FormDescription>
                          Includes basic vehicle inspection
                        </FormDescription>
                      </div>
                    </FormItem>
                  )}
                />
              </div>

              <div className="flex gap-4 pt-4">
                <Button type="submit" disabled={isSubmitting}>
                  {isSubmitting ? "Saving..." : "Save Changes"}
                </Button>
                <Button
                  type="button"
                  variant="outline"
                  onClick={() => router.push("/shop/packages")}
                  disabled={isSubmitting}
                >
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
