# Task Manager — Backend (Spring Boot)

API REST de l'application Task Manager. Contrat exact dans [`../CONTRACT.md`](../CONTRACT.md).

## Stack

Java 21 + Spring Boot 3.3 + Spring Data JPA + Spring Security (JWT) + MySQL (H2 en tests).

## Lancer le projet

```bash
mvn spring-boot:run
```

Variables d'environnement (toutes optionnelles, valeurs par défaut adaptées au dev local) :

| Variable | Défaut | Description |
|---|---|---|
| `DB_HOST` | `localhost` | Hôte MySQL |
| `DB_PORT` | `3306` | Port MySQL |
| `DB_NAME` | `taskmanager` | Nom de la base |
| `DB_USER` / `DB_PASSWORD` | `taskmanager` / `taskmanager` | Identifiants MySQL |
| `JWT_SECRET` | secret de dev intégré | Secret de signature JWT (à changer en prod) |
| `JWT_EXPIRATION_MS` | `86400000` (24h) | Durée de validité du token |
| `SERVER_PORT` | `8080` | Port HTTP |

Profil `docker` (`application-docker.yml`) : mêmes variables, `DB_HOST` par défaut sur `db`
(nom du service docker-compose). Profil `test` (`application-test.yml`) : H2 en mémoire,
utilisé automatiquement par les tests.

## Tests

```bash
mvn test
```

39 tests : unitaires (Mockito) sur `AuthService`/`TaskService`, contrôleurs (`MockMvc`),
et repository (`@DataJpaTest`) — tous verts.

> Sur certains builds Homebrew d'`openjdk@21`, une incompatibilité connue avec Lombok peut
> faire échouer la compilation native (`mvn compile`). Utilisez alors `docker build .` ou
> un JDK Eclipse Temurin — voir le README racine, section "Problèmes connus".

## Structure

```
src/main/java/com/taskmanager/
  entity/       User, Task, TaskStatus
  repository/   UserRepository, TaskRepository (filtrage/recherche)
  security/     JWT (génération, filtre, UserDetailsService)
  service/      AuthService, TaskService
  controller/   AuthController, TaskController
  dto/          Requêtes/réponses de l'API
  exception/    Exceptions métier + @RestControllerAdvice
```

## Docker

```bash
docker build -t taskmanager-backend .
```

Multi-stage : build Maven (`maven:3.9-eclipse-temurin-21`) → image d'exécution
(`eclipse-temurin:21-jre-alpine`), utilisateur non-root, healthcheck sur
`/actuator/health`.
