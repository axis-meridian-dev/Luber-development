"use client"

import { useEffect, useState } from "react"
import { createClient } from "@/lib/supabase/client"
import { useRouter } from "next/navigation"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { ArrowLeft, Plus, CreditCard, Trash2, CheckCircle2 } from "lucide-react"
import Link from "next/link"
import { toast } from "sonner"
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
} from "@/components/ui/alert-dialog"

interface PaymentMethod {
  id: string
  stripe_payment_method_id: string
  card_brand: string | null
  card_last4: string | null
  exp_month: number | null
  exp_year: number | null
  is_default: boolean
  created_at: string
}

export default function PaymentMethodsPage() {
  const router = useRouter()
  const supabase = createClient()

  const [paymentMethods, setPaymentMethods] = useState<PaymentMethod[]>([])
  const [loading, setLoading] = useState(true)
  const [deletingId, setDeletingId] = useState<string | null>(null)
  const [settingDefaultId, setSettingDefaultId] = useState<string | null>(null)
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false)
  const [selectedPaymentMethod, setSelectedPaymentMethod] = useState<PaymentMethod | null>(null)

  useEffect(() => {
    const checkAuth = async () => {
      const {
        data: { user },
      } = await supabase.auth.getUser()

      if (!user) {
        router.push("/auth/login")
        return
      }

      fetchPaymentMethods()
    }

    checkAuth()
  }, [])

  const fetchPaymentMethods = async () => {
    setLoading(true)
    const { data, error } = await supabase
      .from("payment_methods")
      .select("*")
      .order("is_default", { ascending: false })
      .order("created_at", { ascending: false })

    if (error) {
      console.error("Error fetching payment methods:", error)
      toast.error("Failed to load payment methods")
    } else {
      setPaymentMethods(data || [])
    }

    setLoading(false)
  }

  const handleSetDefault = async (paymentMethodId: string) => {
    setSettingDefaultId(paymentMethodId)

    try {
      const response = await fetch("/api/payment-methods/set-default", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({ paymentMethodId }),
      })

      const data = await response.json()

      if (!response.ok) {
        toast.error(data.error || "Failed to set default payment method")
        return
      }

      toast.success("Default payment method updated")
      fetchPaymentMethods()
    } catch (error: any) {
      console.error("Error setting default payment method:", error)
      toast.error(error.message || "An unexpected error occurred")
    } finally {
      setSettingDefaultId(null)
    }
  }

  const handleDeleteClick = (paymentMethod: PaymentMethod) => {
    setSelectedPaymentMethod(paymentMethod)
    setDeleteDialogOpen(true)
  }

  const handleDeleteConfirm = async () => {
    if (!selectedPaymentMethod) return

    setDeletingId(selectedPaymentMethod.id)
    setDeleteDialogOpen(false)

    try {
      const response = await fetch("/api/payment-methods/delete", {
        method: "DELETE",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({ paymentMethodId: selectedPaymentMethod.id }),
      })

      const data = await response.json()

      if (!response.ok) {
        toast.error(data.error || "Failed to delete payment method")
        return
      }

      toast.success("Payment method deleted")
      fetchPaymentMethods()
    } catch (error: any) {
      console.error("Error deleting payment method:", error)
      toast.error(error.message || "An unexpected error occurred")
    } finally {
      setDeletingId(null)
      setSelectedPaymentMethod(null)
    }
  }

  const formatCardBrand = (brand: string | null) => {
    if (!brand) return "CARD"
    return brand.toUpperCase()
  }

  const formatExpiry = (month: number | null, year: number | null) => {
    if (!month || !year) return ""
    return `${String(month).padStart(2, "0")}/${String(year).slice(-2)}`
  }

  if (loading) {
    return (
      <div className="min-h-screen bg-background">
        <header className="border-b border-border bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/60">
          <div className="container mx-auto flex h-16 items-center justify-between px-4">
            <Button variant="ghost" size="sm" asChild>
              <Link href="/">
                <ArrowLeft className="mr-2 h-4 w-4" />
                Back
              </Link>
            </Button>
          </div>
        </header>

        <main className="container mx-auto max-w-4xl p-4 py-6">
          <div className="flex items-center justify-center py-12">
            <div className="text-muted-foreground">Loading payment methods...</div>
          </div>
        </main>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-background">
      <header className="border-b border-border bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/60">
        <div className="container mx-auto flex h-16 items-center justify-between px-4">
          <Button variant="ghost" size="sm" asChild>
            <Link href="/">
              <ArrowLeft className="mr-2 h-4 w-4" />
              Back
            </Link>
          </Button>
          <Button asChild>
            <Link href="/customer/payment-methods/new">
              <Plus className="mr-2 h-4 w-4" />
              Add Card
            </Link>
          </Button>
        </div>
      </header>

      <main className="container mx-auto max-w-4xl p-4 py-6">
        <div className="mb-6">
          <h1 className="text-3xl font-bold">Payment Methods</h1>
          <p className="text-muted-foreground">Manage your saved payment methods</p>
        </div>

        {paymentMethods && paymentMethods.length > 0 ? (
          <div className="grid gap-4 md:grid-cols-2">
            {paymentMethods.map((pm) => (
              <Card key={pm.id} className="relative">
                <CardHeader>
                  <div className="flex items-start justify-between">
                    <div className="flex items-center gap-2">
                      <CreditCard className="h-5 w-5 text-muted-foreground" />
                      <div>
                        <CardTitle className="text-lg">
                          {formatCardBrand(pm.card_brand)} •••• {pm.card_last4}
                        </CardTitle>
                        {pm.exp_month && pm.exp_year && (
                          <p className="text-sm text-muted-foreground">Expires {formatExpiry(pm.exp_month, pm.exp_year)}</p>
                        )}
                      </div>
                    </div>
                    {pm.is_default && <Badge>Default</Badge>}
                  </div>
                </CardHeader>
                <CardContent>
                  <div className="flex gap-2">
                    {!pm.is_default && (
                      <Button
                        size="sm"
                        variant="outline"
                        onClick={() => handleSetDefault(pm.id)}
                        disabled={settingDefaultId === pm.id || deletingId === pm.id}
                      >
                        {settingDefaultId === pm.id ? (
                          <>
                            <div className="mr-2 h-3 w-3 animate-spin rounded-full border-2 border-primary border-t-transparent" />
                            Setting...
                          </>
                        ) : (
                          <>
                            <CheckCircle2 className="mr-2 h-3 w-3" />
                            Set as Default
                          </>
                        )}
                      </Button>
                    )}
                    <Button
                      size="sm"
                      variant="destructive"
                      onClick={() => handleDeleteClick(pm)}
                      disabled={deletingId === pm.id || settingDefaultId === pm.id}
                    >
                      {deletingId === pm.id ? (
                        <>
                          <div className="mr-2 h-3 w-3 animate-spin rounded-full border-2 border-background border-t-transparent" />
                          Deleting...
                        </>
                      ) : (
                        <>
                          <Trash2 className="mr-2 h-3 w-3" />
                          Delete
                        </>
                      )}
                    </Button>
                  </div>
                </CardContent>
              </Card>
            ))}
          </div>
        ) : (
          <Card>
            <CardContent className="flex flex-col items-center justify-center py-12">
              <CreditCard className="mb-4 h-12 w-12 text-muted-foreground" />
              <h3 className="mb-2 text-lg font-semibold">No payment methods yet</h3>
              <p className="mb-4 text-sm text-muted-foreground">Add a payment method to book services</p>
              <Button asChild>
                <Link href="/customer/payment-methods/new">
                  <Plus className="mr-2 h-4 w-4" />
                  Add Card
                </Link>
              </Button>
            </CardContent>
          </Card>
        )}
      </main>

      {/* Delete Confirmation Dialog */}
      <AlertDialog open={deleteDialogOpen} onOpenChange={setDeleteDialogOpen}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Delete Payment Method</AlertDialogTitle>
            <AlertDialogDescription>
              Are you sure you want to delete this payment method?
              {selectedPaymentMethod && (
                <div className="mt-2 rounded-lg border border-border bg-muted/50 p-2">
                  <p className="font-semibold">
                    {formatCardBrand(selectedPaymentMethod.card_brand)} •••• {selectedPaymentMethod.card_last4}
                  </p>
                </div>
              )}
              This action cannot be undone.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>Cancel</AlertDialogCancel>
            <AlertDialogAction onClick={handleDeleteConfirm} className="bg-destructive text-destructive-foreground hover:bg-destructive/90">
              Delete
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </div>
  )
}
