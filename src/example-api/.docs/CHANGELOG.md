# Changelog

All notable changes to the Example API (TaskFlow) project are documented in this file.

## [Unreleased]

### Changed
- Adopted the framework layout: repo `CLAUDE.md` from `TEMPLATE_AGENT.md`, `.claude/` and `bin/` linked by `scripts/sync-repo.sh`, learnings split by domain under `.docs/learnings/`, plans moved to `.docs/plans/`, `TEST_LEDGER.md` added.

### 2026-06-02 - Initial Example

#### Added
- **App factory:** `createApp(db?)` wiring JSON middleware, routes, and an error handler that maps `ValidationError` → `400`.
- **Database:** better-sqlite3 connection in WAL mode with env-based path (`TASKFLOW_DB`); `initDb()` creates `users`, `projects`, `tasks`, `comments` with foreign keys, indexes, and idempotent seed data. In-memory (`:memory:`) support for tests.
- **Types:** `src/types.ts` with interfaces for every entity and `TaskStatus`/`TaskPriority` union types — strict mode, no `any`.
- **Services:** task and project business logic with input validation (`ValidationError`), parameterized SQL, and soft delete via `deleted_date`.
- **Routes:** REST API for projects, tasks, and comments plus a server-rendered HTML dashboard (XSS-escaped).
- **Tests:** Vitest unit tests for services and supertest feature tests for routes.
- **Docker:** multi-stage `Dockerfile` (non-root user) and `docker-compose.yml` (named volume).
- **Documentation:** README, repo-level `CLAUDE.md`, this changelog, and `LEARNINGS.md`.
