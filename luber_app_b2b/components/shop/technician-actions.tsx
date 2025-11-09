"use client"

import { useState } from "react"
import { useRouter } from "next/navigation"
import { Trash2 } from "lucide-react"
import { Button } from "@/components/ui/button"
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
import { removeTechnician } from "@/app/actions/technicians"
import { useToast } from "@/components/ui/use-toast"

interface TechnicianActionsProps {
  technicianId: string
  technicianName: string
}

export default function TechnicianActions({ technicianId, technicianName }: TechnicianActionsProps) {
  const router = useRouter()
  const { toast } = useToast()
  const [isRemoving, setIsRemoving] = useState(false)
  const [isOpen, setIsOpen] = useState(false)

  const handleRemove = async () => {
    setIsRemoving(true)
    const result = await removeTechnician(technicianId)

    if (result.success) {
      toast({
        title: "Success",
        description: "Technician removed from your shop",
      })
      setIsOpen(false)
      router.refresh()
    } else {
      toast({
        title: "Error",
        description: result.error || "Failed to remove technician",
        variant: "destructive",
      })
      setIsRemoving(false)
    }
  }

  return (
    <AlertDialog open={isOpen} onOpenChange={setIsOpen}>
      <AlertDialogTrigger asChild>
        <Button variant="ghost" size="sm" disabled={isRemoving}>
          <Trash2 className="h-3 w-3 text-destructive" />
        </Button>
      </AlertDialogTrigger>
      <AlertDialogContent>
        <AlertDialogHeader>
          <AlertDialogTitle>Remove Technician</AlertDialogTitle>
          <AlertDialogDescription>
            Are you sure you want to remove <strong>{technicianName}</strong> from your shop? They will no longer be
            able to receive job assignments.
            <br />
            <br />
            This action cannot be undone.
          </AlertDialogDescription>
        </AlertDialogHeader>
        <AlertDialogFooter>
          <AlertDialogCancel disabled={isRemoving}>Cancel</AlertDialogCancel>
          <AlertDialogAction
            onClick={handleRemove}
            disabled={isRemoving}
            className="bg-destructive text-destructive-foreground hover:bg-destructive/90"
          >
            {isRemoving ? "Removing..." : "Remove"}
          </AlertDialogAction>
        </AlertDialogFooter>
      </AlertDialogContent>
    </AlertDialog>
  )
}
