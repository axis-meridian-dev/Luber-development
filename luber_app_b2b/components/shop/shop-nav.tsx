"use client"

import Link from "next/link"
import { usePathname, useRouter } from "next/navigation"
import { Button } from "@/components/ui/button"
import { Wrench, LayoutDashboard, Users, Package, Settings, LogOut, Calendar, Radio } from "lucide-react"
import { createBrowserClient } from "@/lib/supabase/client"

interface ShopNavProps {
  shop: any
}

export default function ShopNav({ shop }: ShopNavProps) {
  const pathname = usePathname()
  const router = useRouter()

  const handleLogout = async () => {
    const supabase = createBrowserClient()
    await supabase.auth.signOut()
    router.push("/")
    router.refresh()
  }

  const navItems = [
    { href: "/shop/dashboard", label: "Dashboard", icon: LayoutDashboard },
    { href: "/shop/dispatch", label: "Dispatch", icon: Radio },
    { href: "/shop/bookings", label: "Bookings", icon: Calendar },
    { href: "/shop/technicians", label: "Technicians", icon: Users },
    { href: "/shop/packages", label: "Service Packages", icon: Package },
    { href: "/shop/settings", label: "Settings", icon: Settings },
  ]

  return (
    <header className="sticky top-0 z-50 w-full border-b bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/60">
      <div className="container flex h-16 items-center justify-between">
        <div className="flex items-center gap-8">
          <Link href="/shop/dashboard" className="flex items-center gap-2">
            <Wrench className="h-6 w-6 text-primary" />
            <span className="text-xl font-bold">{shop.shop_name}</span>
          </Link>
          <nav className="hidden md:flex items-center gap-6">
            {navItems.map((item) => {
              const Icon = item.icon
              const isActive = pathname === item.href
              return (
                <Link
                  key={item.href}
                  href={item.href}
                  className={`flex items-center gap-2 text-sm font-medium transition-colors hover:text-primary ${
                    isActive ? "text-primary" : "text-muted-foreground"
                  }`}
                >
                  <Icon className="h-4 w-4" />
                  {item.label}
                </Link>
              )
            })}
          </nav>
        </div>
        <Button variant="ghost" size="sm" onClick={handleLogout}>
          <LogOut className="h-4 w-4 mr-2" />
          Logout
        </Button>
      </div>
    </header>
  )
}
