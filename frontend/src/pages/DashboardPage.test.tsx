import { beforeEach, describe, expect, it } from "vitest"
import { screen, waitFor, within } from "@testing-library/react"
import userEvent from "@testing-library/user-event"
import { DashboardPage } from "@/pages/DashboardPage"
import { renderWithProviders, seedAuthedSession, TEST_USER } from "@/test/render"

beforeEach(() => {
  seedAuthedSession(TEST_USER)
})

describe("DashboardPage", () => {
  it("renders the fetched tasks", async () => {
    renderWithProviders(<DashboardPage />)

    expect(await screen.findByText("Write quarterly report")).toBeInTheDocument()
    expect(screen.getByText("Review pull requests")).toBeInTheDocument()
    expect(screen.getByText("Deploy staging environment")).toBeInTheDocument()
  })

  it("creates a task and adds it to the list", async () => {
    const user = userEvent.setup()
    renderWithProviders(<DashboardPage />)
    await screen.findByText("Write quarterly report")

    await user.click(screen.getByRole("button", { name: /new task/i }))
    const dialog = await screen.findByRole("dialog")
    await user.type(within(dialog).getByLabelText(/title/i), "Buy office supplies")
    await user.type(within(dialog).getByLabelText(/description/i), "Pens, paper, coffee")
    await user.click(within(dialog).getByRole("button", { name: /create task/i }))

    expect(await screen.findByText("Buy office supplies")).toBeInTheDocument()
    expect(screen.getByText("Pens, paper, coffee")).toBeInTheDocument()
  })

  it("edits a task and reflects the update in the list", async () => {
    const user = userEvent.setup()
    renderWithProviders(<DashboardPage />)
    await screen.findByText("Write quarterly report")

    await user.click(screen.getByLabelText("Edit Write quarterly report"))
    const dialog = await screen.findByRole("dialog")
    const titleInput = within(dialog).getByLabelText(/title/i)
    await user.clear(titleInput)
    await user.type(titleInput, "Write annual report")
    await user.click(within(dialog).getByRole("button", { name: /save changes/i }))

    expect(await screen.findByText("Write annual report")).toBeInTheDocument()
    expect(screen.queryByText("Write quarterly report")).not.toBeInTheDocument()
  })

  it("deletes a task after confirmation and removes it from the list", async () => {
    const user = userEvent.setup()
    renderWithProviders(<DashboardPage />)
    await screen.findByText("Review pull requests")

    await user.click(screen.getByLabelText("Delete Review pull requests"))
    const confirmDialog = await screen.findByRole("alertdialog")
    await user.click(within(confirmDialog).getByRole("button", { name: "Delete" }))

    expect(screen.queryByText("Review pull requests")).not.toBeInTheDocument()
    // Other tasks remain untouched.
    expect(screen.getByText("Write quarterly report")).toBeInTheDocument()
  })

  it("filters tasks by status", async () => {
    const user = userEvent.setup()
    renderWithProviders(<DashboardPage />)
    await screen.findByText("Write quarterly report")

    await user.click(screen.getByLabelText(/filter by status/i))
    const listbox = await screen.findByRole("listbox")
    await user.click(within(listbox).getByText("Done"))

    await waitFor(() => {
      expect(screen.queryByText("Write quarterly report")).not.toBeInTheDocument()
    })
    expect(screen.getByText("Deploy staging environment")).toBeInTheDocument()
    expect(screen.queryByText("Review pull requests")).not.toBeInTheDocument()
  })

  it("filters tasks by search text against title or description", async () => {
    const user = userEvent.setup()
    renderWithProviders(<DashboardPage />)
    await screen.findByText("Write quarterly report")

    await user.type(screen.getByLabelText(/search tasks/i), "pull requests")

    await waitFor(() => {
      expect(screen.queryByText("Write quarterly report")).not.toBeInTheDocument()
    })
    expect(screen.getByText("Review pull requests")).toBeInTheDocument()
    expect(screen.queryByText("Deploy staging environment")).not.toBeInTheDocument()
  })

  it("shows an empty state when no tasks match the filters", async () => {
    const user = userEvent.setup()
    renderWithProviders(<DashboardPage />)
    await screen.findByText("Write quarterly report")

    await user.type(screen.getByLabelText(/search tasks/i), "nonexistent task xyz")

    expect(await screen.findByText(/no tasks match your filters/i)).toBeInTheDocument()
  })
})
