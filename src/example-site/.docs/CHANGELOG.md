# Changelog

All notable changes to the Example Site (TaskFlow) project are documented in this file.

## [Unreleased]

### 2026-06-01 - Initial Example

#### Added
- **App factory:** `create_app()` with SQLite in WAL mode and env-based DB path (`TASKFLOW_DB`).
- **Schema:** `users`, `projects`, `tasks`, `comments` tables with foreign keys, indexes, and seed data.
- **Services:** task and project business logic with input validation (`ValidationError`), parameterized SQL, and soft delete via `deleted_date`.
- **Routes:** REST API for projects, tasks, and comments plus a minimal HTML dashboard.
- **Tests:** pytest unit tests for services and feature tests for routes (coverage above 80%).
- **Docker:** `Dockerfile` (gunicorn, non-root user) and `docker-compose.yml` (single service, named volume).
- **Documentation:** README, repo-level `CLAUDE.md`, this changelog, and `LEARNINGS.md`.
