"use client"

import { useState } from "react"
import { useRouter } from "next/navigation"
import Link from "next/link"
import { Edit, Trash2, Check, X } from "lucide-react"

import { Button } from "@/components/ui/button"
import { Card, CardContent, CardFooter, CardHeader, CardTitle } from "@/components/ui/card"
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
import { deletePackage } from "@/app/actions/packages"
import { ShopServicePackage } from "@/lib/types/shop"

interface PackageCardProps {
  packageData: ShopServicePackage
}

export default function PackageCard({ packageData }: PackageCardProps) {
  const router = useRouter()
  const [isDeleting, setIsDeleting] = useState(false)
  const [deleteError, setDeleteError] = useState<string | null>(null)
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false)

  async function handleDelete() {
    setIsDeleting(true)
    setDeleteError(null)

    try {
      const result = await deletePackage(packageData.id)

      if (result.success) {
        router.refresh()
        setDeleteDialogOpen(false)
      } else {
        setDeleteError(result.error || "Failed to delete package")
      }
    } catch (err: any) {
      console.error("Error deleting package:", err)
      setDeleteError(err.message || "An unexpected error occurred")
    } finally {
      setIsDeleting(false)
    }
  }

  // Format oil type for display
  const formatOilType = (type: string | null) => {
    if (!type) return null
    return type
      .split("_")
      .map((word) => word.charAt(0).toUpperCase() + word.slice(1))
      .join(" ")
  }

  return (
    <Card className="flex flex-col">
      <CardHeader>
        <CardTitle className="flex items-center justify-between">
          <span className="line-clamp-1">{packageData.package_name}</span>
          <span
            className={`inline-flex items-center rounded-full px-2 py-1 text-xs font-medium whitespace-nowrap ${
              packageData.is_active
                ? "bg-green-50 text-green-700 dark:bg-green-900/30 dark:text-green-400"
                : "bg-gray-50 text-gray-700 dark:bg-gray-900/30 dark:text-gray-400"
            }`}
          >
            {packageData.is_active ? "Active" : "Inactive"}
          </span>
        </CardTitle>
      </CardHeader>
      <CardContent className="flex-1">
        <div className="space-y-4">
          <div>
            <div className="text-3xl font-bold text-primary">${packageData.price.toFixed(2)}</div>
            <p className="text-sm text-muted-foreground">{packageData.estimated_duration_minutes} minutes</p>
          </div>

          {packageData.description && (
            <p className="text-sm text-muted-foreground line-clamp-2">{packageData.description}</p>
          )}

          <div className="space-y-2 text-sm">
            {packageData.oil_type && (
              <div className="flex items-start gap-2">
                <span className="text-muted-foreground min-w-[80px]">Oil Type:</span>
                <span className="font-medium">{formatOilType(packageData.oil_type)}</span>
              </div>
            )}
            {packageData.oil_brand && (
              <div className="flex items-start gap-2">
                <span className="text-muted-foreground min-w-[80px]">Oil Brand:</span>
                <span className="font-medium">{packageData.oil_brand}</span>
              </div>
            )}

            <div className="pt-2 border-t space-y-1.5">
              <div className="flex items-center gap-2">
                {packageData.includes_filter ? (
                  <Check className="h-4 w-4 text-green-600" />
                ) : (
                  <X className="h-4 w-4 text-gray-400" />
                )}
                <span className={packageData.includes_filter ? "font-medium" : "text-muted-foreground"}>
                  Oil Filter Replacement
                </span>
              </div>
              <div className="flex items-center gap-2">
                {packageData.includes_inspection ? (
                  <Check className="h-4 w-4 text-green-600" />
                ) : (
                  <X className="h-4 w-4 text-gray-400" />
                )}
                <span className={packageData.includes_inspection ? "font-medium" : "text-muted-foreground"}>
                  Multi-Point Inspection
                </span>
              </div>
            </div>
          </div>
        </div>
      </CardContent>
      <CardFooter className="flex gap-2 pt-4 border-t">
        <Link href={`/shop/packages/${packageData.id}/edit`} className="flex-1">
          <Button variant="outline" size="sm" className="w-full">
            <Edit className="h-4 w-4 mr-2" />
            Edit
          </Button>
        </Link>

        <AlertDialog open={deleteDialogOpen} onOpenChange={setDeleteDialogOpen}>
          <AlertDialogTrigger asChild>
            <Button variant="outline" size="sm" className="flex-1" disabled={isDeleting}>
              <Trash2 className="h-4 w-4 mr-2" />
              Delete
            </Button>
          </AlertDialogTrigger>
          <AlertDialogContent>
            <AlertDialogHeader>
              <AlertDialogTitle>Delete Package?</AlertDialogTitle>
              <AlertDialogDescription className="space-y-2">
                <p>
                  This will delete the service package "{packageData.package_name}".
                </p>
                {packageData.is_active && (
                  <p className="text-sm">
                    If this package is in use by existing bookings, it will be deactivated instead of deleted.
                  </p>
                )}
                {deleteError && (
                  <p className="text-destructive text-sm font-medium">{deleteError}</p>
                )}
              </AlertDialogDescription>
            </AlertDialogHeader>
            <AlertDialogFooter>
              <AlertDialogCancel disabled={isDeleting}>Cancel</AlertDialogCancel>
              <AlertDialogAction
                onClick={handleDelete}
                disabled={isDeleting}
                className="bg-destructive hover:bg-destructive/90"
              >
                {isDeleting ? "Deleting..." : "Delete"}
              </AlertDialogAction>
            </AlertDialogFooter>
          </AlertDialogContent>
        </AlertDialog>
      </CardFooter>
    </Card>
  )
}
