#!/usr/bin/env bash
# One-command local dev launcher for Task Manager.
#   ./scripts/dev.sh docker    -> everything via docker compose (db + backend + frontend)
#   ./scripts/dev.sh native    -> backend (mvn) + frontend (vite dev server) natively, MySQL via docker
#   ./scripts/dev.sh stop      -> stop docker compose stack
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

mode="${1:-docker}"

case "$mode" in
  docker)
    echo "==> Starting full stack with Docker Compose (db + backend + frontend)"
    docker compose up --build
    ;;
  native)
    echo "==> Starting MySQL via Docker Compose"
    docker compose up -d db
    echo "==> Waiting for MySQL to be healthy..."
    until [ "$(docker inspect -f '{{.State.Health.Status}}' taskmanager-db 2>/dev/null)" = "healthy" ]; do
      sleep 2
    done
    echo "==> MySQL ready. Starting backend (Spring Boot) in background on :8080"
    (cd backend && mvn spring-boot:run) &
    BACKEND_PID=$!
    echo "==> Starting frontend (Vite) on :5173"
    (cd frontend && npm install && npm run dev) &
    FRONTEND_PID=$!
    trap 'kill $BACKEND_PID $FRONTEND_PID 2>/dev/null || true' EXIT
    wait
    ;;
  stop)
    docker compose down
    ;;
  *)
    echo "Usage: $0 [docker|native|stop]" >&2
    exit 1
    ;;
esac
