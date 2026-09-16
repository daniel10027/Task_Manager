# Task Manager — Mobile (Flutter)

Client Flutter de l'application Task Manager, consommant la même API Spring Boot que le
frontend web (voir [`../CONTRACT.md`](../CONTRACT.md)).

## Fonctionnalités

- **Onboarding liquid-swipe** (première ouverture uniquement, via `liquid_swipe`)
- **Authentification JWT** — token stocké dans `flutter_secure_storage`
- **Tâches** : liste, création, édition, suppression, filtrage par statut, recherche
- **Mode hors-ligne** : cache local (Hive) + file d'attente de synchronisation. Les
  créations/modifications/suppressions faites hors-ligne sont mises en file, coalescées
  intelligemment (éditer deux fois hors-ligne ne garde qu'une seule opération), et
  synchronisées automatiquement au retour du réseau, avec réconciliation des identifiants
  client ↔ serveur.
- **UI animée** : liste à apparition échelonnée (`flutter_animate`), shimmer de
  chargement, pull-to-refresh, swipe-to-delete avec annulation, pastille de statut
  en ligne/hors-ligne animée.

## Lancer le projet

```bash
flutter pub get
flutter run --dart-define=API_BASE_URL=http://localhost:8080
```

- Simulateur iOS / desktop : `http://localhost:8080` par défaut.
- Émulateur Android : `http://10.0.2.2:8080` par défaut (alias réseau vers l'hôte).
- Contre la stack Docker Compose locale (`docker compose up` à la racine du repo) ou un
  backend déployé, passez son URL via `--dart-define=API_BASE_URL=...`.

## Tests

```bash
flutter analyze
flutter test
```

27 tests (widgets + unitaires sur la file de synchronisation hors-ligne), tous verts ;
`flutter analyze` sans avertissement.

## Structure

```
lib/
  core/api/       Client Dio + gestion des erreurs API
  core/storage/   JWT (secure storage) + boîtes Hive
  core/sync/      Cache local, file d'opérations, service de synchronisation
  models/         Task, User
  screens/        onboarding, auth, tasks
  state/          providers (package `provider`)
  theme/          thème Material 3
test/
  unit/           file d'attente + synchronisation
  widget/         écrans (login, liste de tâches)
```
