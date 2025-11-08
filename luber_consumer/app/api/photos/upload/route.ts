import { type NextRequest, NextResponse } from "next/server"
import { createClient } from "@/lib/supabase/server"
import { put } from "@vercel/blob"

export async function POST(request: NextRequest) {
  try {
    const supabase = await createClient()

    const {
      data: { user },
      error: authError,
    } = await supabase.auth.getUser()
    if (authError || !user) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 })
    }

    const formData = await request.formData()
    const file = formData.get("file") as File
    const job_id = formData.get("job_id") as string
    const photo_type = formData.get("photo_type") as string

    if (!file || !job_id || !photo_type) {
      return NextResponse.json({ error: "Missing required fields" }, { status: 400 })
    }

    // Verify job belongs to technician
    const { data: job } = await supabase.from("jobs").select("technician_id").eq("id", job_id).single()

    if (job?.technician_id !== user.id) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 403 })
    }

    // Upload to Vercel Blob
    const blob = await put(`job-photos/${job_id}/${Date.now()}-${file.name}`, file, {
      access: "public",
    })

    // Save to database
    const { data: photo, error: photoError } = await supabase
      .from("job_photos")
      .insert({
        job_id,
        photo_url: blob.url,
        photo_type,
      })
      .select()
      .single()

    if (photoError) {
      console.error("[v0] Photo save error:", photoError)
      return NextResponse.json({ error: "Failed to save photo" }, { status: 500 })
    }

    return NextResponse.json({ photo })
  } catch (error) {
    console.error("[v0] Error uploading photo:", error)
    return NextResponse.json({ error: "Internal server error" }, { status: 500 })
  }
}
