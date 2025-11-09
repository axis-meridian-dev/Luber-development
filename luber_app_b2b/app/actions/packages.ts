"use server"

import { createServerClient } from "@/lib/supabase/server"
import { revalidatePath } from "next/cache"
import { z } from "zod"

// Validation schemas
const packageSchema = z.object({
  package_name: z.string().min(1, "Package name is required").max(100),
  description: z.string().optional(),
  price: z.number().min(0.01, "Price must be greater than 0"),
  estimated_duration_minutes: z.number().min(1, "Duration must be at least 1 minute").max(1440),
  oil_brand: z.string().optional(),
  oil_type: z.enum(["conventional", "synthetic_blend", "full_synthetic", "high_mileage", "diesel"]).optional(),
  includes_filter: z.boolean().default(true),
  includes_inspection: z.boolean().default(false),
})

type PackageInput = z.infer<typeof packageSchema>

export async function createPackage(input: PackageInput) {
  try {
    const supabase = await createServerClient()

    // Get authenticated user
    const {
      data: { user },
    } = await supabase.auth.getUser()

    if (!user) {
      return { success: false, error: "Not authenticated" }
    }

    // Get shop owned by user
    const { data: shop, error: shopError } = await supabase
      .from("shops")
      .select("id")
      .eq("owner_id", user.id)
      .single()

    if (shopError || !shop) {
      return { success: false, error: "Shop not found. Please complete onboarding first." }
    }

    // Validate input
    const validatedInput = packageSchema.parse(input)

    // Insert package
    const { data, error } = await supabase
      .from("shop_service_packages")
      .insert({
        shop_id: shop.id,
        ...validatedInput,
        is_active: true,
      })
      .select()
      .single()

    if (error) {
      console.error("[packages] Error creating package:", error)

      // Handle unique constraint violation
      if (error.code === "23505") {
        return { success: false, error: "A package with this name already exists" }
      }

      return { success: false, error: error.message }
    }

    revalidatePath("/shop/packages")
    return { success: true, data }
  } catch (error: any) {
    console.error("[packages] Error in createPackage:", error)

    if (error instanceof z.ZodError) {
      return { success: false, error: error.errors[0].message }
    }

    return { success: false, error: error.message || "Failed to create package" }
  }
}

export async function updatePackage(id: string, input: PackageInput) {
  try {
    const supabase = await createServerClient()

    // Get authenticated user
    const {
      data: { user },
    } = await supabase.auth.getUser()

    if (!user) {
      return { success: false, error: "Not authenticated" }
    }

    // Get shop owned by user
    const { data: shop, error: shopError } = await supabase
      .from("shops")
      .select("id")
      .eq("owner_id", user.id)
      .single()

    if (shopError || !shop) {
      return { success: false, error: "Shop not found" }
    }

    // Verify package belongs to shop
    const { data: existingPackage, error: packageError } = await supabase
      .from("shop_service_packages")
      .select("id")
      .eq("id", id)
      .eq("shop_id", shop.id)
      .single()

    if (packageError || !existingPackage) {
      return { success: false, error: "Package not found or unauthorized" }
    }

    // Validate input
    const validatedInput = packageSchema.parse(input)

    // Update package
    const { data, error } = await supabase
      .from("shop_service_packages")
      .update(validatedInput)
      .eq("id", id)
      .select()
      .single()

    if (error) {
      console.error("[packages] Error updating package:", error)

      // Handle unique constraint violation
      if (error.code === "23505") {
        return { success: false, error: "A package with this name already exists" }
      }

      return { success: false, error: error.message }
    }

    revalidatePath("/shop/packages")
    revalidatePath(`/shop/packages/${id}/edit`)
    return { success: true, data }
  } catch (error: any) {
    console.error("[packages] Error in updatePackage:", error)

    if (error instanceof z.ZodError) {
      return { success: false, error: error.errors[0].message }
    }

    return { success: false, error: error.message || "Failed to update package" }
  }
}

export async function deletePackage(id: string) {
  try {
    const supabase = await createServerClient()

    // Get authenticated user
    const {
      data: { user },
    } = await supabase.auth.getUser()

    if (!user) {
      return { success: false, error: "Not authenticated" }
    }

    // Get shop owned by user
    const { data: shop, error: shopError } = await supabase
      .from("shops")
      .select("id")
      .eq("owner_id", user.id)
      .single()

    if (shopError || !shop) {
      return { success: false, error: "Shop not found" }
    }

    // Verify package belongs to shop
    const { data: existingPackage, error: packageError } = await supabase
      .from("shop_service_packages")
      .select("id")
      .eq("id", id)
      .eq("shop_id", shop.id)
      .single()

    if (packageError || !existingPackage) {
      return { success: false, error: "Package not found or unauthorized" }
    }

    // Check if package is in use by any bookings
    const { data: bookings, error: bookingsError } = await supabase
      .from("bookings")
      .select("id")
      .eq("service_package_id", id)
      .limit(1)

    if (bookingsError) {
      console.error("[packages] Error checking bookings:", bookingsError)
      return { success: false, error: "Failed to verify package usage" }
    }

    // If package is in use, soft delete by marking inactive
    if (bookings && bookings.length > 0) {
      const { error } = await supabase
        .from("shop_service_packages")
        .update({ is_active: false })
        .eq("id", id)

      if (error) {
        console.error("[packages] Error deactivating package:", error)
        return { success: false, error: error.message }
      }

      revalidatePath("/shop/packages")
      return {
        success: true,
        message: "Package deactivated (cannot delete because it's used in bookings)"
      }
    }

    // Hard delete if not in use
    const { error } = await supabase
      .from("shop_service_packages")
      .delete()
      .eq("id", id)

    if (error) {
      console.error("[packages] Error deleting package:", error)
      return { success: false, error: error.message }
    }

    revalidatePath("/shop/packages")
    return { success: true, message: "Package deleted successfully" }
  } catch (error: any) {
    console.error("[packages] Error in deletePackage:", error)
    return { success: false, error: error.message || "Failed to delete package" }
  }
}

export async function togglePackageActive(id: string, isActive: boolean) {
  try {
    const supabase = await createServerClient()

    // Get authenticated user
    const {
      data: { user },
    } = await supabase.auth.getUser()

    if (!user) {
      return { success: false, error: "Not authenticated" }
    }

    // Get shop owned by user
    const { data: shop, error: shopError } = await supabase
      .from("shops")
      .select("id")
      .eq("owner_id", user.id)
      .single()

    if (shopError || !shop) {
      return { success: false, error: "Shop not found" }
    }

    // Verify package belongs to shop
    const { data: existingPackage, error: packageError } = await supabase
      .from("shop_service_packages")
      .select("id")
      .eq("id", id)
      .eq("shop_id", shop.id)
      .single()

    if (packageError || !existingPackage) {
      return { success: false, error: "Package not found or unauthorized" }
    }

    // Update active status
    const { error } = await supabase
      .from("shop_service_packages")
      .update({ is_active: isActive })
      .eq("id", id)

    if (error) {
      console.error("[packages] Error toggling package active status:", error)
      return { success: false, error: error.message }
    }

    revalidatePath("/shop/packages")
    return { success: true }
  } catch (error: any) {
    console.error("[packages] Error in togglePackageActive:", error)
    return { success: false, error: error.message || "Failed to toggle package status" }
  }
}
