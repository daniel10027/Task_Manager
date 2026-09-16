import { Badge } from "@/components/ui/badge"
import { cn } from "@/lib/utils"
import type { TaskStatus } from "@/types"

const STATUS_CONFIG: Record<TaskStatus, { label: string; className: string }> = {
  TODO: {
    label: "To do",
    className:
      "bg-muted text-muted-foreground border-border dark:bg-muted/60",
  },
  IN_PROGRESS: {
    label: "In progress",
    className: "bg-warning/15 text-warning border-warning/30 dark:bg-warning/20",
  },
  DONE: {
    label: "Done",
    className:
      "bg-success/15 text-success border-success/30 dark:bg-success/20",
  },
}

export function StatusBadge({ status, className }: { status: TaskStatus; className?: string }) {
  const config = STATUS_CONFIG[status]
  return (
    <Badge
      variant="outline"
      className={cn("font-medium", config.className, className)}
      data-status={status}
    >
      {config.label}
    </Badge>
  )
}

export const STATUS_LABELS: Record<TaskStatus, string> = {
  TODO: "To do",
  IN_PROGRESS: "In progress",
  DONE: "Done",
}
