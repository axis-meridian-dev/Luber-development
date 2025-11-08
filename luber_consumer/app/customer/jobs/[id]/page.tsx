import { createClient } from "@/lib/supabase/server"
import { notFound, redirect } from "next/navigation"
import { JobTracker } from "@/components/customer/job-tracker"

interface JobDetailsPageProps {
  params: Promise<{ id: string }>
}

export default async function JobDetailsPage({ params }: JobDetailsPageProps) {
  const { id } = await params
  const supabase = await createClient()

  const {
    data: { user },
  } = await supabase.auth.getUser()

  if (!user) {
    redirect("/auth/login")
  }

  const { data: job } = await supabase
    .from("jobs")
    .select(
      `
      *,
      vehicles (*),
      addresses (*),
      technician:profiles!jobs_technician_id_fkey (
        id,
        full_name,
        profile_photo_url,
        phone
      ),
      technician_profiles!inner (
        average_rating,
        total_jobs_completed
      ),
      job_photos (*),
      reviews (*)
    `,
    )
    .eq("id", id)
    .eq("customer_id", user.id)
    .single()

  if (!job) {
    notFound()
  }

  return <JobTracker job={job} />
}
