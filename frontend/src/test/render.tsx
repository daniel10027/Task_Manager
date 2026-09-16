import type { ReactElement } from "react"
import { render } from "@testing-library/react"
import { MemoryRouter } from "react-router-dom"
import { AuthProvider } from "@/context/AuthContext"
import { Toaster } from "@/components/ui/sonner"
import { TOKEN_STORAGE_KEY, USER_STORAGE_KEY } from "@/api/client"
import type { User } from "@/types"

export function renderWithProviders(ui: ReactElement, { route = "/" }: { route?: string } = {}) {
  return render(
    <MemoryRouter initialEntries={[route]}>
      <AuthProvider>
        {ui}
        <Toaster />
      </AuthProvider>
    </MemoryRouter>
  )
}

/** Seed localStorage as if the given user already logged in, before rendering. */
export function seedAuthedSession(user: User, token = `mock-jwt-token-for-user-${user.id}`) {
  localStorage.setItem(TOKEN_STORAGE_KEY, token)
  localStorage.setItem(USER_STORAGE_KEY, JSON.stringify(user))
}

export const TEST_USER: User = { id: 1, email: "jane@doe.com", fullName: "Jane Doe" }
