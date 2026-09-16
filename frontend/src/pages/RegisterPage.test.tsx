import { describe, expect, it } from "vitest"
import { render, screen } from "@testing-library/react"
import userEvent from "@testing-library/user-event"
import { MemoryRouter, Route, Routes } from "react-router-dom"
import { AuthProvider } from "@/context/AuthContext"
import { Toaster } from "@/components/ui/sonner"
import { RegisterPage } from "@/pages/RegisterPage"
import { TOKEN_STORAGE_KEY } from "@/api/client"

function renderRegisterFlow() {
  return render(
    <MemoryRouter initialEntries={["/register"]}>
      <AuthProvider>
        <Routes>
          <Route path="/register" element={<RegisterPage />} />
          <Route path="/" element={<div>Dashboard Home</div>} />
        </Routes>
        <Toaster />
      </AuthProvider>
    </MemoryRouter>
  )
}

describe("RegisterPage", () => {
  it("registers successfully and navigates to the dashboard", async () => {
    const user = userEvent.setup()
    renderRegisterFlow()

    await user.type(screen.getByLabelText(/full name/i), "New Person")
    await user.type(screen.getByLabelText(/email/i), "newperson@example.com")
    await user.type(screen.getByLabelText(/password/i), "AGoodPassword1")
    await user.click(screen.getByRole("button", { name: /create account/i }))

    expect(await screen.findByText("Dashboard Home")).toBeInTheDocument()
    expect(localStorage.getItem(TOKEN_STORAGE_KEY)).toBeTruthy()
  })

  it("shows a toast error when the email is already registered", async () => {
    const user = userEvent.setup()
    renderRegisterFlow()

    await user.type(screen.getByLabelText(/full name/i), "Jane Doe")
    await user.type(screen.getByLabelText(/email/i), "jane@doe.com")
    await user.type(screen.getByLabelText(/password/i), "AnotherPassword1")
    await user.click(screen.getByRole("button", { name: /create account/i }))

    expect(await screen.findByText(/email is already registered/i)).toBeInTheDocument()
    expect(screen.queryByText("Dashboard Home")).not.toBeInTheDocument()
  })

  it("validates password length client-side", async () => {
    const user = userEvent.setup()
    renderRegisterFlow()

    await user.type(screen.getByLabelText(/full name/i), "Jane Doe")
    await user.type(screen.getByLabelText(/email/i), "someone@example.com")
    await user.type(screen.getByLabelText(/password/i), "short")
    await user.click(screen.getByRole("button", { name: /create account/i }))

    expect(await screen.findByText(/at least 8 characters/i)).toBeInTheDocument()
  })
})
