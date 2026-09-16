import { describe, expect, it } from "vitest"
import { screen } from "@testing-library/react"
import userEvent from "@testing-library/user-event"
import { MemoryRouter, Route, Routes } from "react-router-dom"
import { render } from "@testing-library/react"
import { AuthProvider } from "@/context/AuthContext"
import { Toaster } from "@/components/ui/sonner"
import { LoginPage } from "@/pages/LoginPage"
import { TOKEN_STORAGE_KEY, USER_STORAGE_KEY } from "@/api/client"

function renderLoginFlow() {
  return render(
    <MemoryRouter initialEntries={["/login"]}>
      <AuthProvider>
        <Routes>
          <Route path="/login" element={<LoginPage />} />
          <Route path="/" element={<div>Dashboard Home</div>} />
        </Routes>
        <Toaster />
      </AuthProvider>
    </MemoryRouter>
  )
}

describe("LoginPage", () => {
  it("logs in successfully, stores the token, and navigates to the dashboard", async () => {
    const user = userEvent.setup()
    renderLoginFlow()

    await user.type(screen.getByLabelText(/email/i), "jane@doe.com")
    await user.type(screen.getByLabelText(/password/i), "Sup3rSecret!")
    await user.click(screen.getByRole("button", { name: /sign in/i }))

    expect(await screen.findByText("Dashboard Home")).toBeInTheDocument()
    expect(localStorage.getItem(TOKEN_STORAGE_KEY)).toBe("mock-jwt-token-for-user-1")
    const storedUser = JSON.parse(localStorage.getItem(USER_STORAGE_KEY) ?? "{}")
    expect(storedUser.email).toBe("jane@doe.com")
  })

  it("shows an error toast on invalid credentials and stays on the login page", async () => {
    const user = userEvent.setup()
    renderLoginFlow()

    await user.type(screen.getByLabelText(/email/i), "jane@doe.com")
    await user.type(screen.getByLabelText(/password/i), "WrongPassword1")
    await user.click(screen.getByRole("button", { name: /sign in/i }))

    expect(await screen.findByText(/invalid email or password/i)).toBeInTheDocument()
    expect(screen.queryByText("Dashboard Home")).not.toBeInTheDocument()
    expect(localStorage.getItem(TOKEN_STORAGE_KEY)).toBeNull()
  })

  it("shows client-side validation errors without calling the API", async () => {
    const user = userEvent.setup()
    renderLoginFlow()

    await user.type(screen.getByLabelText(/email/i), "not-an-email")
    await user.click(screen.getByRole("button", { name: /sign in/i }))

    expect(await screen.findByText(/enter a valid email address/i)).toBeInTheDocument()
    expect(screen.queryByText("Dashboard Home")).not.toBeInTheDocument()
  })
})
