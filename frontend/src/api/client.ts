import axios, { AxiosError } from "axios"
import type { ApiErrorShape } from "@/types"

export const TOKEN_STORAGE_KEY = "taskmanager.token"
export const USER_STORAGE_KEY = "taskmanager.user"

// Resolution order for the API base URL:
//  1. `VITE_API_URL` if set — used for local `npm run dev` (defaults to
//     http://localhost:8080 via .env/.env.example) and for a Docker image
//     built with `--build-arg VITE_API_URL=...` (e.g. for Cloud Run, where
//     frontend and backend are separate origins and the value is baked into
//     the static bundle at build time, since Vite env vars don't exist at
//     container runtime).
//  2. In dev without an explicit VITE_API_URL, fall back to localhost:8080.
//  3. Otherwise (a production build with no VITE_API_URL baked in — the
//     docker-compose case), use a relative baseURL so requests hit the same
//     origin the app is served from; nginx.conf proxies `/api/` to the
//     `backend` service in that setup.
const configuredApiUrl = import.meta.env.VITE_API_URL
const baseURL = configuredApiUrl || (import.meta.env.DEV ? "http://localhost:8080" : "")

export const apiClient = axios.create({
  baseURL,
  headers: {
    "Content-Type": "application/json",
  },
})

apiClient.interceptors.request.use((config) => {
  const token = localStorage.getItem(TOKEN_STORAGE_KEY)
  if (token) {
    config.headers.Authorization = `Bearer ${token}`
  }
  return config
})

/**
 * Normalized error thrown for every failed request so callers can toast a
 * single, predictable `message` regardless of what the backend sent.
 */
export class ApiError extends Error {
  status?: number

  constructor(message: string, status?: number) {
    super(message)
    this.name = "ApiError"
    this.status = status
  }
}

apiClient.interceptors.response.use(
  (response) => response,
  (error: AxiosError<Partial<ApiErrorShape>>) => {
    const status = error.response?.status
    const message =
      error.response?.data?.message ||
      error.message ||
      "Something went wrong. Please try again."

    if (status === 401) {
      localStorage.removeItem(TOKEN_STORAGE_KEY)
      localStorage.removeItem(USER_STORAGE_KEY)
      if (typeof window !== "undefined" && window.location.pathname !== "/login") {
        window.location.assign("/login")
      }
    }

    return Promise.reject(new ApiError(message, status))
  }
)
