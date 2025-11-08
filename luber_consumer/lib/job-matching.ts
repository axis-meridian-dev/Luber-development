import { createClient } from "./supabase/server"

interface JobMatchingParams {
  latitude: number
  longitude: number
  scheduled_time: string
}

// Calculate distance between two coordinates using Haversine formula
function calculateDistance(lat1: number, lon1: number, lat2: number, lon2: number): number {
  const R = 3959 // Earth's radius in miles
  const dLat = ((lat2 - lat1) * Math.PI) / 180
  const dLon = ((lon2 - lon1) * Math.PI) / 180
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos((lat1 * Math.PI) / 180) * Math.cos((lat2 * Math.PI) / 180) * Math.sin(dLon / 2) * Math.sin(dLon / 2)
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))
  return R * c
}

export async function findAvailableTechnicians(params: JobMatchingParams) {
  const supabase = await createClient()
  const MAX_DISTANCE_MILES = 25

  // Get all available technicians with their last known locations
  const { data: technicians, error } = await supabase
    .from("technician_profiles")
    .select(`
      id,
      average_rating,
      total_jobs_completed,
      technician_locations (
        latitude,
        longitude,
        updated_at
      ),
      profiles (
        full_name,
        profile_photo_url
      )
    `)
    .eq("is_available", true)
    .eq("application_status", "approved")

  if (error || !technicians) {
    console.error("[v0] Error fetching technicians:", error)
    return []
  }

  // Filter and sort technicians by distance and rating
  const availableTechnicians = technicians
    .filter((tech) => {
      const location = tech.technician_locations?.[0]
      if (!location) return false

      const distance = calculateDistance(params.latitude, params.longitude, location.latitude, location.longitude)

      return distance <= MAX_DISTANCE_MILES
    })
    .map((tech) => {
      const location = tech.technician_locations![0]
      const distance = calculateDistance(params.latitude, params.longitude, location.latitude, location.longitude)

      return {
        id: tech.id,
        full_name: tech.profiles?.full_name || "Unknown",
        profile_photo_url: tech.profiles?.profile_photo_url,
        average_rating: tech.average_rating,
        total_jobs_completed: tech.total_jobs_completed,
        distance_miles: Math.round(distance * 10) / 10,
      }
    })
    .sort((a, b) => {
      // Sort by rating first, then by distance
      if (Math.abs(a.average_rating - b.average_rating) > 0.5) {
        return b.average_rating - a.average_rating
      }
      return a.distance_miles - b.distance_miles
    })

  return availableTechnicians
}
