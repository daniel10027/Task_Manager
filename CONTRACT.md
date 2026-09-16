# API Contract — Task Manager

This is the single source of truth for the REST API. The backend implements it exactly;
the web frontend and the Flutter mobile app consume it exactly. Any change here must be
reflected in all three at once.

Base URL (local): `http://localhost:8080`
All request/response bodies are JSON. All authenticated endpoints require:

```
Authorization: Bearer <jwt>
```

## Error shape (all 4xx/5xx)

```json
{
  "timestamp": "2026-09-16T10:00:00Z",
  "status": 400,
  "error": "Bad Request",
  "message": "Email is already registered",
  "path": "/api/auth/register"
}
```

## Auth

### `POST /api/auth/register`
Request:
```json
{ "email": "jane@doe.com", "password": "Sup3rSecret!", "fullName": "Jane Doe" }
```
- `email`: valid email, unique, required
- `password`: min 8 chars, required
- `fullName`: 2–100 chars, required

Response `201`:
```json
{
  "token": "eyJhbGciOi...",
  "user": { "id": 1, "email": "jane@doe.com", "fullName": "Jane Doe" }
}
```
Errors: `409` email already registered, `400` validation.

### `POST /api/auth/login`
Request: `{ "email": "jane@doe.com", "password": "Sup3rSecret!" }`
Response `200`: same shape as register.
Errors: `401` invalid credentials.

## Tasks
All task endpoints require a valid JWT and only ever operate on the authenticated user's own tasks.

### `Task` object
```json
{
  "id": 10,
  "title": "Write report",
  "description": "Quarterly summary",
  "status": "TODO",
  "createdAt": "2026-09-16T10:00:00Z",
  "updatedAt": "2026-09-16T10:00:00Z"
}
```
`status` enum: `TODO` | `IN_PROGRESS` | `DONE`

### `GET /api/tasks?status={status}&search={text}`
Both query params optional. `status` filters exact match. `search` matches (case-insensitive,
substring) against `title` OR `description`. Combinable. No params → all tasks for the user,
newest first (`createdAt DESC`).
Response `200`: `Task[]`

### `POST /api/tasks`
Request: `{ "title": "...", "description": "...", "status": "TODO" }`
- `title`: 1–200 chars, required
- `description`: 0–2000 chars, optional
- `status`: optional, defaults to `TODO`
Response `201`: `Task`

### `PUT /api/tasks/{id}`
Request: same shape as POST (full replace of title/description/status).
Response `200`: `Task`
Errors: `404` if task doesn't exist or doesn't belong to the caller.

### `DELETE /api/tasks/{id}`
Response `204` no body.
Errors: `404` if task doesn't exist or doesn't belong to the caller.

## Health
### `GET /actuator/health` → `{ "status": "UP" }` (used by Docker healthcheck / Cloud Run)
