import { LogOut, ListChecks } from "lucide-react"
import { Button } from "@/components/ui/button"
import { useAuth } from "@/context/AuthContext"

function getInitials(fullName: string): string {
  const parts = fullName.trim().split(/\s+/)
  const initials = parts.slice(0, 2).map((p) => p[0]?.toUpperCase() ?? "")
  return initials.join("") || "?"
}

export function Navbar() {
  const { user, logout } = useAuth()

  return (
    <header className="sticky top-0 z-10 border-b border-border bg-background/80 backdrop-blur supports-[backdrop-filter]:bg-background/60">
      <div className="mx-auto flex max-w-5xl items-center justify-between px-4 py-3 sm:px-6">
        <div className="flex items-center gap-2">
          <div className="flex size-8 items-center justify-center rounded-lg bg-primary text-primary-foreground">
            <ListChecks className="size-4.5" />
          </div>
          <span className="text-sm font-semibold tracking-tight sm:text-base">Task Manager</span>
        </div>

        {user && (
          <div className="flex items-center gap-3">
            <div className="hidden items-center gap-2 sm:flex">
              <div className="flex size-8 items-center justify-center rounded-full bg-secondary text-xs font-medium text-secondary-foreground">
                {getInitials(user.fullName)}
              </div>
              <div className="flex flex-col leading-tight">
                <span className="text-sm font-medium text-foreground">{user.fullName}</span>
                <span className="text-xs text-muted-foreground">{user.email}</span>
              </div>
            </div>
            <Button
              variant="outline"
              size="sm"
              onClick={logout}
              className="gap-1.5"
              aria-label="Log out"
            >
              <LogOut className="size-3.5" />
              <span className="hidden sm:inline">Log out</span>
            </Button>
          </div>
        )}
      </div>
    </header>
  )
}
