import { apiClient } from "@/api/client"
import type { Task, TaskListParams, TaskPayload } from "@/types"

export async function listTasks(params: TaskListParams = {}): Promise<Task[]> {
  const { data } = await apiClient.get<Task[]>("/api/tasks", {
    params: {
      status: params.status || undefined,
      search: params.search || undefined,
    },
  })
  return data
}

export async function createTask(payload: TaskPayload): Promise<Task> {
  const { data } = await apiClient.post<Task>("/api/tasks", payload)
  return data
}

export async function updateTask(id: number, payload: TaskPayload): Promise<Task> {
  const { data } = await apiClient.put<Task>(`/api/tasks/${id}`, payload)
  return data
}

export async function deleteTask(id: number): Promise<void> {
  await apiClient.delete(`/api/tasks/${id}`)
}
