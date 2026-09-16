import { ClipboardList, SearchX } from "lucide-react"
import { Skeleton } from "@/components/ui/skeleton"
import { TaskCard } from "@/components/TaskCard"
import { Button } from "@/components/ui/button"
import type { Task } from "@/types"

interface TaskListProps {
  tasks: Task[]
  isLoading: boolean
  hasActiveFilters: boolean
  onEdit: (task: Task) => void
  onDelete: (task: Task) => void
  onCreate: () => void
  onClearFilters: () => void
}

function TaskListSkeleton() {
  return (
    <div className="flex flex-col gap-3" aria-hidden="true">
      {Array.from({ length: 4 }).map((_, i) => (
        <div key={i} className="rounded-xl border border-border p-4 sm:p-5">
          <div className="flex items-start justify-between gap-3">
            <div className="flex-1 space-y-2.5">
              <div className="flex items-center gap-2">
                <Skeleton className="h-4 w-40" />
                <Skeleton className="h-5 w-16 rounded-full" />
              </div>
              <Skeleton className="h-3.5 w-3/4" />
              <Skeleton className="h-3 w-24" />
            </div>
            <Skeleton className="size-7 rounded-md" />
          </div>
        </div>
      ))}
    </div>
  )
}

export function TaskList({
  tasks,
  isLoading,
  hasActiveFilters,
  onEdit,
  onDelete,
  onCreate,
  onClearFilters,
}: TaskListProps) {
  if (isLoading) {
    return <TaskListSkeleton />
  }

  if (tasks.length === 0 && hasActiveFilters) {
    return (
      <div className="flex flex-col items-center justify-center gap-3 rounded-xl border border-dashed border-border py-16 text-center animate-in fade-in-0">
        <div className="flex size-12 items-center justify-center rounded-full bg-muted">
          <SearchX className="size-5 text-muted-foreground" />
        </div>
        <div>
          <p className="text-sm font-medium text-foreground">No tasks match your filters</p>
          <p className="mt-1 text-sm text-muted-foreground">
            Try a different search term or status.
          </p>
        </div>
        <Button variant="outline" size="sm" onClick={onClearFilters}>
          Clear filters
        </Button>
      </div>
    )
  }

  if (tasks.length === 0) {
    return (
      <div className="flex flex-col items-center justify-center gap-3 rounded-xl border border-dashed border-border py-16 text-center animate-in fade-in-0">
        <div className="flex size-12 items-center justify-center rounded-full bg-muted">
          <ClipboardList className="size-5 text-muted-foreground" />
        </div>
        <div>
          <p className="text-sm font-medium text-foreground">No tasks yet</p>
          <p className="mt-1 text-sm text-muted-foreground">
            Create your first task to get started.
          </p>
        </div>
        <Button size="sm" onClick={onCreate}>
          New task
        </Button>
      </div>
    )
  }

  return (
    <div className="flex flex-col gap-3">
      {tasks.map((task) => (
        <div key={task.id} className="animate-in fade-in-0 slide-in-from-bottom-1 duration-300">
          <TaskCard task={task} onEdit={onEdit} onDelete={onDelete} />
        </div>
      ))}
    </div>
  )
}
