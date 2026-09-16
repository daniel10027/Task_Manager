.PHONY: up down native stop logs test-backend test-frontend test-mobile test

up: ## Launch everything with Docker Compose (db + backend + frontend)
	./scripts/dev.sh docker

native: ## Run MySQL in Docker, backend + frontend natively
	./scripts/dev.sh native

down stop: ## Stop the Docker Compose stack
	./scripts/dev.sh stop

logs: ## Tail docker compose logs
	docker compose logs -f

test-backend:
	cd backend && mvn test

test-frontend:
	cd frontend && npm run test

test-mobile:
	cd mobile && flutter test

test: test-backend test-frontend test-mobile ## Run all test suites
