export type TaskStatus = "TODO" | "IN_PROGRESS" | "DONE"

export interface User {
  id: number
  email: string
  fullName: string
}

export interface Task {
  id: number
  title: string
  description: string | null
  status: TaskStatus
  createdAt: string
  updatedAt: string
}

export interface AuthResponse {
  token: string
  user: User
}

export interface ApiErrorShape {
  timestamp: string
  status: number
  error: string
  message: string
  path: string
}

export interface LoginPayload {
  email: string
  password: string
}

export interface RegisterPayload {
  email: string
  password: string
  fullName: string
}

export interface TaskPayload {
  title: string
  description?: string
  status?: TaskStatus
}

export interface TaskListParams {
  status?: TaskStatus
  search?: string
}
