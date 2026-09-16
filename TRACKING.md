# Suivi du projet — Task Manager

Checklist vivante, cochée au fur et à mesure de l'avancement. Basée sur `TEST DE RECRUTEMENT.pdf`.
Dernière mise à jour : voir dernier commit.

## Backend — Spring Boot (Java + Spring Data JPA + MySQL)
- [x] Entités `User`, `Task` (title, description, status, createdAt, updatedAt)
- [x] `POST /api/auth/register`
- [x] `POST /api/auth/login` (JWT)
- [x] `GET /api/tasks` (liste des tâches de l'utilisateur connecté)
- [x] `POST /api/tasks`
- [x] `PUT /api/tasks/{id}`
- [x] `DELETE /api/tasks/{id}`
- [x] Filtrage par statut + recherche texte
- [x] Authentification JWT (Spring Security)
- [x] Base MySQL + config Docker Compose
- [x] Gestion des erreurs centralisée (`@RestControllerAdvice`)
- [x] Tests unitaires (services — Mockito)
- [x] Tests d'intégration (contrôleurs MockMvc, repository @DataJpaTest) — 39 tests, tous verts
- [x] Dockerfile backend (multi-stage, vérifié avec `docker build`)

## Frontend — React + Vite + TSX + Tailwind/shadcn
- [x] Scaffold Vite + React + TypeScript + Tailwind + shadcn/ui
- [x] Formulaire inscription / connexion
- [x] Stockage du token JWT (localStorage) + route protégée
- [x] Liste de tâches (fetch API dynamique)
- [x] Ajout / édition / suppression de tâches
- [x] Filtrage par statut + champ de recherche
- [x] Gestion des erreurs API (toasts — sonner)
- [x] Tests (Vitest + React Testing Library + MSW) — 13 tests, tous verts
- [x] Dockerfile frontend (nginx, vérifié avec `docker build` + `docker compose up`)

## Mobile — Flutter (bonus)
- [x] Scaffold Flutter + thème Material 3
- [x] Écran d'onboarding liquid-swipe (première ouverture)
- [x] Connexion / inscription via l'API (même JWT, `flutter_secure_storage`)
- [x] Liste des tâches + création / édition / suppression
- [x] Filtrage par statut + recherche
- [x] Mode hors-ligne : cache local (Hive) + file d'attente de synchronisation (coalescing + retry)
- [x] Bannière animée en ligne / hors-ligne (pastille de statut live)
- [x] Animations (liste échelonnée, transitions, shimmer loading, pull-to-refresh, FAB)
- [x] Tests widgets + tests unitaires (27 tests, `flutter analyze` clean)

## CI/CD & Déploiement (bonus)
- [x] Pipeline CI backend (build + tests) — `.github/workflows/backend-ci.yml`
- [x] Pipeline CI frontend (lint + tests + build) — `.github/workflows/frontend-ci.yml`
- [x] Pipeline CI mobile (analyze + tests) — `.github/workflows/mobile-ci.yml`
- [x] Build des images Docker (backend + frontend) — vérifié en local ET dans `cd.yml`
- [x] Pipeline CD déploiement GCP Cloud Run (prêt à l'emploi, activé par secrets GitHub) — `.github/workflows/cd.yml`
- [x] `docker-compose.yml` pour lancer tout en local — vérifié avec un flux complet (inscription → CRUD → filtres) en conditions réelles
- [x] Script / commande unique pour lancer le projet en local — `make up` / `./scripts/dev.sh`
- [x] Les 4 pipelines confirmés verts sur GitHub Actions (pas seulement en local) — 2 bugs d'environnement CI réels trouvés et corrigés en observant les runs réels (Node 20 incompatible avec vitest 5/jsdom 30 → Node 24 ; `dart format` jamais appliqué → tout le module `mobile/` reformaté)

## Documentation
- [x] `CONTRACT.md` — contrat d'API partagé
- [x] `README.md` complet (installation, architecture, choix techniques, captures d'écran, lien déployé)
- [x] `TRACKING.md` (ce fichier) tenu à jour

## Qualité / revue
- [x] Audit manuel sécurité/correction (JWT, scoping des tâches par utilisateur, gestion d'erreurs, validation, logique de synchronisation hors-ligne mobile) — aucun problème trouvé au-delà de ceux déjà corrigés
- [x] Bug réel trouvé et corrigé via test end-to-end navigateur : le proxy nginx du frontend tronquait tous les chemins d'API vers `/api/` (voir commit `fix(frontend): nginx API proxy...`)

## Bonus / déploiement réel
- [ ] Lien Cloud Run / Firebase Hosting déployé (nécessite un projet GCP réel — non exécutable depuis cet environnement, voir README pour les étapes)
