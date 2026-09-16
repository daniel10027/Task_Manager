# Suivi du projet — Task Manager

Checklist vivante, cochée au fur et à mesure de l'avancement. Basée sur `TEST DE RECRUTEMENT.pdf`.
Dernière mise à jour : voir dernier commit.

## Backend — Spring Boot (Java + Spring Data JPA + MySQL)
- [ ] Entités `User`, `Task` (title, description, status, createdAt, updatedAt)
- [ ] `POST /api/auth/register`
- [ ] `POST /api/auth/login` (JWT)
- [ ] `GET /api/tasks` (liste des tâches de l'utilisateur connecté)
- [ ] `POST /api/tasks`
- [ ] `PUT /api/tasks/{id}`
- [ ] `DELETE /api/tasks/{id}`
- [ ] Filtrage par statut + recherche texte
- [ ] Authentification JWT (Spring Security)
- [ ] Base MySQL + config Docker Compose
- [ ] Gestion des erreurs centralisée (`@ControllerAdvice`)
- [ ] Tests unitaires (services)
- [ ] Tests d'intégration (contrôleurs, sécurité, repository)
- [ ] Dockerfile backend

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
- [ ] Scaffold Flutter + thème Material 3
- [ ] Écran d'onboarding liquid-swipe (première ouverture)
- [ ] Connexion / inscription via l'API (même JWT)
- [ ] Liste des tâches + création / édition / suppression
- [ ] Filtrage par statut + recherche
- [ ] Mode hors-ligne : cache local + file d'attente de synchronisation
- [ ] Bannière animée en ligne / hors-ligne
- [ ] Animations (liste, transitions, shimmer loading, pull-to-refresh)
- [ ] Tests widgets + tests unitaires (service de sync)

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
