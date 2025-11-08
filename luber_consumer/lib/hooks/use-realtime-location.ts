"use client"

import { useEffect, useState } from "react"
import { createClient } from "@/lib/supabase/client"
import type { TechnicianLocation } from "@/lib/types/database"

export function useRealtimeLocation(technicianId: string | null) {
  const [location, setLocation] = useState<TechnicianLocation | null>(null)
  const supabase = createClient()

  useEffect(() => {
    if (!technicianId) return

    // Get initial location
    supabase
      .from("technician_locations")
      .select("*")
      .eq("technician_id", technicianId)
      .single()
      .then(({ data }) => {
        if (data) setLocation(data)
      })

    // Subscribe to realtime updates
    const channel = supabase
      .channel(`location:${technicianId}`)
      .on(
        "postgres_changes",
        {
          event: "*",
          schema: "public",
          table: "technician_locations",
          filter: `technician_id=eq.${technicianId}`,
        },
        (payload) => {
          setLocation(payload.new as TechnicianLocation)
        },
      )
      .subscribe()

    return () => {
      supabase.removeChannel(channel)
    }
  }, [technicianId, supabase])

  return location
}
