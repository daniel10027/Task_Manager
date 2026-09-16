import { http, HttpResponse } from "msw"
import type { Task, TaskStatus, User } from "@/types"

const API_URL = "http://localhost:8080"

interface StoredUser extends User {
  password: string
}

function apiError(status: number, error: string, message: string, path: string) {
  return HttpResponse.json(
    { timestamp: new Date().toISOString(), status, error, message, path },
    { status }
  )
}

// ---- In-memory mock backend state (reset between tests via resetMockDb) ----
let users: StoredUser[] = [
  { id: 1, email: "jane@doe.com", password: "Sup3rSecret!", fullName: "Jane Doe" },
]
let nextUserId = 2

let tasks: Task[] = [
  {
    id: 1,
    title: "Write quarterly report",
    description: "Summarize Q3 performance for stakeholders",
    status: "TODO",
    createdAt: "2026-09-10T10:00:00Z",
    updatedAt: "2026-09-10T10:00:00Z",
  },
  {
    id: 2,
    title: "Review pull requests",
    description: "Check open PRs from the team",
    status: "IN_PROGRESS",
    createdAt: "2026-09-12T10:00:00Z",
    updatedAt: "2026-09-12T10:00:00Z",
  },
  {
    id: 3,
    title: "Deploy staging environment",
    description: null,
    status: "DONE",
    createdAt: "2026-09-14T10:00:00Z",
    updatedAt: "2026-09-14T10:00:00Z",
  },
]
let nextTaskId = 4

export function resetMockDb() {
  users = [{ id: 1, email: "jane@doe.com", password: "Sup3rSecret!", fullName: "Jane Doe" }]
  nextUserId = 2
  tasks = [
    {
      id: 1,
      title: "Write quarterly report",
      description: "Summarize Q3 performance for stakeholders",
      status: "TODO",
      createdAt: "2026-09-10T10:00:00Z",
      updatedAt: "2026-09-10T10:00:00Z",
    },
    {
      id: 2,
      title: "Review pull requests",
      description: "Check open PRs from the team",
      status: "IN_PROGRESS",
      createdAt: "2026-09-12T10:00:00Z",
      updatedAt: "2026-09-12T10:00:00Z",
    },
    {
      id: 3,
      title: "Deploy staging environment",
      description: null,
      status: "DONE",
      createdAt: "2026-09-14T10:00:00Z",
      updatedAt: "2026-09-14T10:00:00Z",
    },
  ]
  nextTaskId = 4
}

function tokenFor(user: User) {
  return `mock-jwt-token-for-user-${user.id}`
}

function requireAuth(request: Request): User | null {
  const authHeader = request.headers.get("Authorization")
  if (!authHeader?.startsWith("Bearer ")) return null
  const token = authHeader.slice("Bearer ".length)
  const match = token.match(/^mock-jwt-token-for-user-(\d+)$/)
  if (!match) return null
  const userId = Number(match[1])
  const user = users.find((u) => u.id === userId)
  if (!user) return null
  const { password: _password, ...publicUser } = user
  return publicUser
}

export const handlers = [
  http.post(`${API_URL}/api/auth/register`, async ({ request }) => {
    const body = (await request.json()) as { email: string; password: string; fullName: string }

    if (users.some((u) => u.email === body.email)) {
      return apiError(409, "Conflict", "Email is already registered", "/api/auth/register")
    }
    if (!body.password || body.password.length < 8) {
      return apiError(400, "Bad Request", "Password must be at least 8 characters", "/api/auth/register")
    }

    const newUser: StoredUser = {
      id: nextUserId++,
      email: body.email,
      password: body.password,
      fullName: body.fullName,
    }
    users.push(newUser)
    const { password: _password, ...publicUser } = newUser
    return HttpResponse.json({ token: tokenFor(publicUser), user: publicUser }, { status: 201 })
  }),

  http.post(`${API_URL}/api/auth/login`, async ({ request }) => {
    const body = (await request.json()) as { email: string; password: string }
    const user = users.find((u) => u.email === body.email && u.password === body.password)
    if (!user) {
      return apiError(401, "Unauthorized", "Invalid email or password", "/api/auth/login")
    }
    const { password: _password, ...publicUser } = user
    return HttpResponse.json({ token: tokenFor(publicUser), user: publicUser }, { status: 200 })
  }),

  http.get(`${API_URL}/api/tasks`, ({ request }) => {
    const user = requireAuth(request)
    if (!user) {
      return apiError(401, "Unauthorized", "Missing or invalid token", "/api/tasks")
    }

    const url = new URL(request.url)
    const statusFilter = url.searchParams.get("status") as TaskStatus | null
    const search = url.searchParams.get("search")?.toLowerCase()

    let result = [...tasks]
    if (statusFilter) {
      result = result.filter((t) => t.status === statusFilter)
    }
    if (search) {
      result = result.filter(
        (t) =>
          t.title.toLowerCase().includes(search) ||
          (t.description ?? "").toLowerCase().includes(search)
      )
    }
    result.sort((a, b) => (a.createdAt < b.createdAt ? 1 : -1))

    return HttpResponse.json(result, { status: 200 })
  }),

  http.post(`${API_URL}/api/tasks`, async ({ request }) => {
    const user = requireAuth(request)
    if (!user) {
      return apiError(401, "Unauthorized", "Missing or invalid token", "/api/tasks")
    }
    const body = (await request.json()) as { title: string; description?: string; status?: TaskStatus }
    if (!body.title || body.title.length > 200) {
      return apiError(400, "Bad Request", "Title must be 1-200 characters", "/api/tasks")
    }
    const now = new Date().toISOString()
    const newTask: Task = {
      id: nextTaskId++,
      title: body.title,
      description: body.description ?? null,
      status: body.status ?? "TODO",
      createdAt: now,
      updatedAt: now,
    }
    tasks.push(newTask)
    return HttpResponse.json(newTask, { status: 201 })
  }),

  http.put(`${API_URL}/api/tasks/:id`, async ({ request, params }) => {
    const user = requireAuth(request)
    if (!user) {
      return apiError(401, "Unauthorized", "Missing or invalid token", `/api/tasks/${params.id}`)
    }
    const id = Number(params.id)
    const task = tasks.find((t) => t.id === id)
    if (!task) {
      return apiError(404, "Not Found", "Task not found", `/api/tasks/${id}`)
    }
    const body = (await request.json()) as { title: string; description?: string; status?: TaskStatus }
    task.title = body.title
    task.description = body.description ?? null
    task.status = body.status ?? task.status
    task.updatedAt = new Date().toISOString()
    return HttpResponse.json(task, { status: 200 })
  }),

  http.delete(`${API_URL}/api/tasks/:id`, ({ request, params }) => {
    const user = requireAuth(request)
    if (!user) {
      return apiError(401, "Unauthorized", "Missing or invalid token", `/api/tasks/${params.id}`)
    }
    const id = Number(params.id)
    const index = tasks.findIndex((t) => t.id === id)
    if (index === -1) {
      return apiError(404, "Not Found", "Task not found", `/api/tasks/${id}`)
    }
    tasks.splice(index, 1)
    return new HttpResponse(null, { status: 204 })
  }),
]
