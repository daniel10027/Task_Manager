import { apiClient } from "@/api/client"
import type { AuthResponse, LoginPayload, RegisterPayload } from "@/types"

export async function login(payload: LoginPayload): Promise<AuthResponse> {
  const { data } = await apiClient.post<AuthResponse>("/api/auth/login", payload)
  return data
}

export async function register(payload: RegisterPayload): Promise<AuthResponse> {
  const { data } = await apiClient.post<AuthResponse>("/api/auth/register", payload)
  return data
}
