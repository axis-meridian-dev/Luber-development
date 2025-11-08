"use client"

import { useEffect, useState } from "react"
import { createClient } from "@/lib/supabase/client"
import type { Job } from "@/lib/types/database"

export function useJobUpdates(jobId: string | null) {
  const [job, setJob] = useState<Job | null>(null)
  const supabase = createClient()

  useEffect(() => {
    if (!jobId) return

    // Get initial job data
    supabase
      .from("jobs")
      .select("*")
      .eq("id", jobId)
      .single()
      .then(({ data }) => {
        if (data) setJob(data)
      })

    // Subscribe to realtime updates
    const channel = supabase
      .channel(`job:${jobId}`)
      .on(
        "postgres_changes",
        {
          event: "UPDATE",
          schema: "public",
          table: "jobs",
          filter: `id=eq.${jobId}`,
        },
        (payload) => {
          setJob(payload.new as Job)
        },
      )
      .subscribe()

    return () => {
      supabase.removeChannel(channel)
    }
  }, [jobId, supabase])

  return job
}
