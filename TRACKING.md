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
- [ ] Scaffold Vite + React + TypeScript + Tailwind + shadcn/ui
- [ ] Formulaire inscription / connexion
- [ ] Stockage du token JWT (localStorage) + route protégée
- [ ] Liste de tâches (fetch API dynamique)
- [ ] Ajout / édition / suppression de tâches
- [ ] Filtrage par statut + champ de recherche
- [ ] Gestion des erreurs API (toasts)
- [ ] Tests (Vitest + React Testing Library + MSW)
- [ ] Dockerfile frontend (nginx)

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
- [ ] Pipeline CI backend (build + tests, service MySQL)
- [ ] Pipeline CI frontend (lint + tests + build)
- [ ] Pipeline CI mobile (analyze + tests)
- [ ] Build des images Docker (backend + frontend)
- [ ] Pipeline CD déploiement GCP Cloud Run (prêt à l'emploi, activé par secrets GitHub)
- [ ] `docker-compose.yml` pour lancer tout en local
- [ ] Script / commande unique pour lancer le projet en local

## Documentation
- [ ] `CONTRACT.md` — contrat d'API partagé
- [ ] `README.md` complet (installation, architecture, choix techniques, captures d'écran, lien déployé)
- [ ] `TRACKING.md` (ce fichier) tenu à jour

## Bonus / déploiement réel
- [ ] Lien Cloud Run / Firebase Hosting déployé (nécessite un projet GCP réel — non exécutable depuis cet environnement, voir README pour les étapes)
