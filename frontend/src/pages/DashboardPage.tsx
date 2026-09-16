import { useCallback, useEffect, useMemo, useState } from "react"
import { Plus } from "lucide-react"
import { toast } from "sonner"
import { Button } from "@/components/ui/button"
import { Navbar } from "@/components/Navbar"
import { FilterBar } from "@/components/FilterBar"
import type { StatusFilter } from "@/components/FilterBar"
import { TaskList } from "@/components/TaskList"
import { TaskFormDialog } from "@/components/TaskFormDialog"
import { DeleteTaskDialog } from "@/components/DeleteTaskDialog"
import { useDebounce } from "@/hooks/useDebounce"
import * as tasksApi from "@/api/tasks"
import { ApiError } from "@/api/client"
import type { Task, TaskPayload } from "@/types"

export function DashboardPage() {
  const [tasks, setTasks] = useState<Task[]>([])
  const [isLoading, setIsLoading] = useState(true)
  const [status, setStatus] = useState<StatusFilter>("ALL")
  const [search, setSearch] = useState("")
  const debouncedSearch = useDebounce(search, 300)

  const [formOpen, setFormOpen] = useState(false)
  const [editingTask, setEditingTask] = useState<Task | null>(null)
  const [deletingTask, setDeletingTask] = useState<Task | null>(null)
  const [isDeleting, setIsDeleting] = useState(false)

  const fetchTasks = useCallback(async () => {
    setIsLoading(true)
    try {
      const data = await tasksApi.listTasks({
        status: status === "ALL" ? undefined : status,
        search: debouncedSearch || undefined,
      })
      setTasks(data)
    } catch (error) {
      const message = error instanceof ApiError ? error.message : "Failed to load tasks."
      toast.error(message)
    } finally {
      setIsLoading(false)
    }
  }, [status, debouncedSearch])

  useEffect(() => {
    void fetchTasks()
  }, [fetchTasks])

  const hasActiveFilters = status !== "ALL" || debouncedSearch.trim().length > 0

  function openCreateDialog() {
    setEditingTask(null)
    setFormOpen(true)
  }

  function openEditDialog(task: Task) {
    setEditingTask(task)
    setFormOpen(true)
  }

  async function handleFormSubmit(payload: TaskPayload) {
    try {
      if (editingTask) {
        const updated = await tasksApi.updateTask(editingTask.id, payload)
        setTasks((prev) => prev.map((t) => (t.id === updated.id ? updated : t)))
        toast.success("Task updated.")
      } else {
        const created = await tasksApi.createTask(payload)
        setTasks((prev) => {
          // Keep newest-first ordering consistent with the API contract.
          const next = [created, ...prev]
          if (status !== "ALL" && created.status !== status) {
            return prev
          }
          return next
        })
        toast.success("Task created.")
      }
    } catch (error) {
      const message = error instanceof ApiError ? error.message : "Something went wrong."
      toast.error(message)
      throw error
    }
  }

  async function handleDeleteConfirm() {
    if (!deletingTask) return
    setIsDeleting(true)
    try {
      await tasksApi.deleteTask(deletingTask.id)
      setTasks((prev) => prev.filter((t) => t.id !== deletingTask.id))
      toast.success("Task deleted.")
      setDeletingTask(null)
    } catch (error) {
      const message = error instanceof ApiError ? error.message : "Failed to delete task."
      toast.error(message)
    } finally {
      setIsDeleting(false)
    }
  }

  const taskCountLabel = useMemo(() => {
    if (isLoading) return ""
    const count = tasks.length
    return `${count} task${count === 1 ? "" : "s"}`
  }, [tasks.length, isLoading])

  return (
    <div className="min-h-screen bg-background">
      <Navbar />

      <main className="mx-auto max-w-5xl px-4 py-8 sm:px-6">
        <div className="mb-6 flex flex-col gap-1 sm:flex-row sm:items-end sm:justify-between">
          <div>
            <h1 className="text-2xl font-semibold tracking-tight text-foreground">Your tasks</h1>
            <p className="text-sm text-muted-foreground">
              {taskCountLabel || "Loading your tasks…"}
            </p>
          </div>
          <Button onClick={openCreateDialog} className="gap-1.5 sm:w-auto">
            <Plus className="size-4" />
            New task
          </Button>
        </div>

        <div className="mb-6">
          <FilterBar
            status={status}
            onStatusChange={setStatus}
            search={search}
            onSearchChange={setSearch}
          />
        </div>

        <TaskList
          tasks={tasks}
          isLoading={isLoading}
          hasActiveFilters={hasActiveFilters}
          onEdit={openEditDialog}
          onDelete={setDeletingTask}
          onCreate={openCreateDialog}
          onClearFilters={() => {
            setStatus("ALL")
            setSearch("")
          }}
        />
      </main>

      <TaskFormDialog
        open={formOpen}
        onOpenChange={setFormOpen}
        task={editingTask}
        onSubmit={handleFormSubmit}
      />

      <DeleteTaskDialog
        task={deletingTask}
        onOpenChange={(open) => !open && setDeletingTask(null)}
        onConfirm={handleDeleteConfirm}
        isDeleting={isDeleting}
      />
    </div>
  )
}
