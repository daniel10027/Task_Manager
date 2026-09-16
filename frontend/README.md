# Task Manager — Frontend (React + Vite + TypeScript)

Interface web de l'application Task Manager, consommant l'API Spring Boot décrite dans
[`../CONTRACT.md`](../CONTRACT.md).

## Stack

React 19 + Vite + TypeScript + Tailwind CSS v4 + shadcn/ui + react-router-dom + axios.

## Lancer le projet

```bash
npm install
cp .env.example .env   # VITE_API_URL=http://localhost:8080
npm run dev
```

## Scripts

| Commande | Description |
|---|---|
| `npm run dev` | Serveur de développement (Vite) |
| `npm run build` | Build de production (`tsc -b && vite build`) |
| `npm run lint` | Lint (oxlint) |
| `npm run test` | Tests (Vitest, single run) |
| `npm run test:watch` | Tests en mode watch |

13 tests (Testing Library + MSW), tous verts.

## Structure

```
src/
  api/          Client axios (JWT interceptor) + appels auth/tasks
  components/   Navbar, TaskList, TaskFormDialog, FilterBar, composants shadcn/ui
  context/      AuthContext (JWT + utilisateur, persistés en localStorage)
  pages/        LoginPage, RegisterPage, DashboardPage
  test/         handlers MSW, setup, helpers de rendu
  types/        types partagés (User, Task, TaskStatus)
```

## Docker

`Dockerfile` multi-stage (build Node → service nginx). Deux modes :

- **docker-compose** (par défaut) : `VITE_API_URL` non défini, l'app appelle `/api/*`
  en relatif, proxifié par nginx vers le service `backend` (voir `nginx.conf`).
- **Déploiement autonome** (ex. Cloud Run) : passer l'URL du backend au build —
  `docker build --build-arg VITE_API_URL=https://api.example.com .`
