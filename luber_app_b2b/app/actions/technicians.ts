"use server"

import { createServerClient } from "@/lib/supabase/server"
import { revalidatePath } from "next/cache"
import { z } from "zod"
import { SUBSCRIPTION_PLANS } from "@/lib/stripe"

// Validation schemas
const inviteTechnicianSchema = z.object({
  email: z.string().email("Invalid email address"),
  full_name: z.string().optional(),
  license_number: z.string().min(1, "License number is required"),
  years_experience: z.coerce.number().min(0, "Experience must be 0 or greater"),
  certifications: z.array(z.string()).default([]),
  phone: z.string().optional(),
  bio: z.string().optional(),
})

const updateTechnicianSchema = z.object({
  license_number: z.string().min(1, "License number is required"),
  years_experience: z.coerce.number().min(0, "Experience must be 0 or greater"),
  certifications: z.array(z.string()).default([]),
  bio: z.string().optional(),
  is_available: z.boolean().default(true),
})

type ActionResponse<T = void> = {
  success: boolean
  error?: string
  data?: T
}

/**
 * Invite a new technician to the shop
 * Creates a shop_technicians entry and optionally creates a profile if email doesn't exist
 */
export async function inviteTechnician(formData: FormData): Promise<ActionResponse<{ id: string }>> {
  try {
    const supabase = await createServerClient()

    // Get authenticated user
    const {
      data: { user },
    } = await supabase.auth.getUser()

    if (!user) {
      return { success: false, error: "Not authenticated" }
    }

    // Get user's profile to verify they're a shop owner
    const { data: profile, error: profileError } = await supabase
      .from("profiles")
      .select("role, shop_id")
      .eq("id", user.id)
      .single()

    if (profileError || !profile) {
      return { success: false, error: "Profile not found" }
    }

    if (profile.role !== "shop_owner") {
      return { success: false, error: "Only shop owners can invite technicians" }
    }

    // Get the shop owned by this user
    const { data: shop, error: shopError } = await supabase
      .from("shops")
      .select("id, subscription_tier, total_technicians")
      .eq("owner_id", user.id)
      .single()

    if (shopError || !shop) {
      return { success: false, error: "Shop not found" }
    }

    // Check subscription limits
    const planConfig = SUBSCRIPTION_PLANS.find((p) => p.tier === shop.subscription_tier)
    if (!planConfig) {
      return { success: false, error: "Invalid subscription tier" }
    }

    // Solo tier: max 1 technician (the owner themselves)
    // Business tier: max 10 technicians
    const maxTechnicians = shop.subscription_tier === "solo" ? 1 : 10

    if (shop.total_technicians >= maxTechnicians) {
      return {
        success: false,
        error: `Your ${shop.subscription_tier} plan allows a maximum of ${maxTechnicians} technician(s). Please upgrade to add more.`,
      }
    }

    // Parse and validate form data
    const rawData = {
      email: formData.get("email") as string,
      full_name: formData.get("full_name") as string,
      license_number: formData.get("license_number") as string,
      years_experience: formData.get("years_experience"),
      certifications: formData.getAll("certifications") as string[],
      phone: formData.get("phone") as string,
      bio: formData.get("bio") as string,
    }

    const validated = inviteTechnicianSchema.parse(rawData)

    // Check if a profile already exists with this email
    const { data: existingProfile } = await supabase
      .from("profiles")
      .select("id, role, shop_id")
      .eq("email", validated.email)
      .single()

    let profileId: string

    if (existingProfile) {
      // User exists - verify they're not already assigned to another shop
      if (existingProfile.role === "shop_mechanic" && existingProfile.shop_id) {
        return { success: false, error: "This user is already assigned to another shop" }
      }

      // Check if they're already a technician for this shop
      const { data: existingTech } = await supabase
        .from("shop_technicians")
        .select("id")
        .eq("shop_id", shop.id)
        .eq("profile_id", existingProfile.id)
        .single()

      if (existingTech) {
        return { success: false, error: "This technician is already part of your shop" }
      }

      profileId = existingProfile.id

      // Update their role to shop_mechanic and link to shop
      await supabase
        .from("profiles")
        .update({
          role: "shop_mechanic",
          shop_id: shop.id,
          full_name: validated.full_name || existingProfile.full_name,
          phone: validated.phone || existingProfile.phone,
        })
        .eq("id", profileId)
    } else {
      // Create a new profile for the invited technician
      // Note: This creates a "pending" profile. They'll need to sign up to activate it.
      const { data: newProfile, error: createProfileError } = await supabase
        .from("profiles")
        .insert({
          email: validated.email,
          full_name: validated.full_name || "",
          phone: validated.phone,
          role: "shop_mechanic",
          shop_id: shop.id,
        })
        .select("id")
        .single()

      if (createProfileError || !newProfile) {
        return { success: false, error: "Failed to create profile" }
      }

      profileId = newProfile.id
    }

    // Create shop_technicians entry
    const { data: technician, error: techError } = await supabase
      .from("shop_technicians")
      .insert({
        shop_id: shop.id,
        profile_id: profileId,
        license_number: validated.license_number,
        years_experience: validated.years_experience,
        certifications: validated.certifications,
        bio: validated.bio,
        is_available: true,
      })
      .select("id")
      .single()

    if (techError || !technician) {
      return { success: false, error: "Failed to create technician record" }
    }

    // TODO: Send invitation email
    // For MVP: This would integrate with an email service (Resend, SendGrid, etc.)
    // For now, we'll just create a notification placeholder

    revalidatePath("/shop/technicians")
    return { success: true, data: { id: technician.id } }
  } catch (error) {
    console.error("Error inviting technician:", error)
    if (error instanceof z.ZodError) {
      return { success: false, error: error.errors[0].message }
    }
    return { success: false, error: "An unexpected error occurred" }
  }
}

/**
 * Update an existing technician's details
 */
export async function updateTechnician(
  technicianId: string,
  formData: FormData
): Promise<ActionResponse> {
  try {
    const supabase = await createServerClient()

    // Get authenticated user
    const {
      data: { user },
    } = await supabase.auth.getUser()

    if (!user) {
      return { success: false, error: "Not authenticated" }
    }

    // Verify user is shop owner and technician belongs to their shop
    const { data: shop, error: shopError } = await supabase
      .from("shops")
      .select("id")
      .eq("owner_id", user.id)
      .single()

    if (shopError || !shop) {
      return { success: false, error: "Shop not found" }
    }

    const { data: technician, error: techError } = await supabase
      .from("shop_technicians")
      .select("id, shop_id")
      .eq("id", technicianId)
      .single()

    if (techError || !technician) {
      return { success: false, error: "Technician not found" }
    }

    if (technician.shop_id !== shop.id) {
      return { success: false, error: "Technician does not belong to your shop" }
    }

    // Parse and validate form data
    const rawData = {
      license_number: formData.get("license_number") as string,
      years_experience: formData.get("years_experience"),
      certifications: formData.getAll("certifications") as string[],
      bio: formData.get("bio") as string,
      is_available: formData.get("is_available") === "true",
    }

    const validated = updateTechnicianSchema.parse(rawData)

    // Update technician
    const { error: updateError } = await supabase
      .from("shop_technicians")
      .update({
        license_number: validated.license_number,
        years_experience: validated.years_experience,
        certifications: validated.certifications,
        bio: validated.bio,
        is_available: validated.is_available,
      })
      .eq("id", technicianId)

    if (updateError) {
      return { success: false, error: "Failed to update technician" }
    }

    revalidatePath("/shop/technicians")
    revalidatePath(`/shop/technicians/${technicianId}/edit`)
    return { success: true }
  } catch (error) {
    console.error("Error updating technician:", error)
    if (error instanceof z.ZodError) {
      return { success: false, error: error.errors[0].message }
    }
    return { success: false, error: "An unexpected error occurred" }
  }
}

/**
 * Remove a technician from the shop
 * This deletes the shop_technicians entry and updates the profile
 */
export async function removeTechnician(technicianId: string): Promise<ActionResponse> {
  try {
    const supabase = await createServerClient()

    // Get authenticated user
    const {
      data: { user },
    } = await supabase.auth.getUser()

    if (!user) {
      return { success: false, error: "Not authenticated" }
    }

    // Verify user is shop owner and technician belongs to their shop
    const { data: shop, error: shopError } = await supabase
      .from("shops")
      .select("id")
      .eq("owner_id", user.id)
      .single()

    if (shopError || !shop) {
      return { success: false, error: "Shop not found" }
    }

    const { data: technician, error: techError } = await supabase
      .from("shop_technicians")
      .select("id, shop_id, profile_id")
      .eq("id", technicianId)
      .single()

    if (techError || !technician) {
      return { success: false, error: "Technician not found" }
    }

    if (technician.shop_id !== shop.id) {
      return { success: false, error: "Technician does not belong to your shop" }
    }

    // Remove shop_technicians entry
    const { error: deleteError } = await supabase.from("shop_technicians").delete().eq("id", technicianId)

    if (deleteError) {
      return { success: false, error: "Failed to remove technician" }
    }

    // Update profile to remove shop association
    // Change role to 'customer' or 'solo_mechanic' depending on their preference
    // For now, we'll just clear the shop_id
    await supabase
      .from("profiles")
      .update({
        shop_id: null,
        role: "customer", // Default to customer when removed from shop
      })
      .eq("id", technician.profile_id)

    revalidatePath("/shop/technicians")
    return { success: true }
  } catch (error) {
    console.error("Error removing technician:", error)
    return { success: false, error: "An unexpected error occurred" }
  }
}

/**
 * Resend invitation email to a technician
 * For MVP: Creates a notification. In production: sends email via service
 */
export async function resendInvite(technicianId: string): Promise<ActionResponse> {
  try {
    const supabase = await createServerClient()

    // Get authenticated user
    const {
      data: { user },
    } = await supabase.auth.getUser()

    if (!user) {
      return { success: false, error: "Not authenticated" }
    }

    // Verify user is shop owner and technician belongs to their shop
    const { data: shop, error: shopError } = await supabase
      .from("shops")
      .select("id, shop_name")
      .eq("owner_id", user.id)
      .single()

    if (shopError || !shop) {
      return { success: false, error: "Shop not found" }
    }

    const { data: technician, error: techError } = await supabase
      .from("shop_technicians")
      .select("id, shop_id, profile_id, profiles(email, full_name)")
      .eq("id", technicianId)
      .single()

    if (techError || !technician) {
      return { success: false, error: "Technician not found" }
    }

    if (technician.shop_id !== shop.id) {
      return { success: false, error: "Technician does not belong to your shop" }
    }

    // TODO: Send invitation email via email service
    // For MVP: Log the invitation
    console.log("Resending invitation to:", {
      email: (technician.profiles as any)?.email,
      shopName: shop.shop_name,
      technicianId,
    })

    return { success: true }
  } catch (error) {
    console.error("Error resending invite:", error)
    return { success: false, error: "An unexpected error occurred" }
  }
}
