# Example API — TaskFlow (Node + TypeScript)

The **TypeScript twin** of `../example-site`. It implements the exact same **task tracker**
domain — so you can compare how the boilerplate's standards map from Python to a strict
TypeScript / Node stack.

It is an Express REST API backed by SQLite (via better-sqlite3), with a minimal server-rendered
HTML dashboard. Tests use Vitest + supertest.

## Domain

| Entity | Description |
|--------|-------------|
| **User** | A person who can be assigned tasks and write comments. |
| **Project** | A container for tasks. |
| **Task** | A unit of work in a project — has a status (`todo`/`in_progress`/`done`) and priority. |
| **Comment** | A note attached to a task. |

Tasks are **soft-deleted** via a nullable `deleted_date` integer column.

## Running locally

```bash
npm install
npm run dev          # tsx watch — http://localhost:8000
```

Build and run the compiled output:

```bash
npm run build        # tsc → dist/
npm start            # node dist/server.js
```

## Running with Docker

```bash
cp .env.example .env
docker compose up -d --build
# Visit http://localhost:8010
```

## Running the tests

```bash
npm test             # vitest run --coverage
npm run test:watch   # watch mode
```

The suite covers services (unit) and routes (feature, via supertest), targeting the 80%
coverage bar the boilerplate requires.

## API

| Method | Path | Description |
|--------|------|-------------|
| GET    | `/` | HTML dashboard (projects with their tasks) |
| GET    | `/api/projects` | List projects |
| POST   | `/api/projects` | Create a project |
| GET    | `/api/tasks` | List tasks (optionally `?project_id=` / `?status=`) |
| POST   | `/api/tasks` | Create a task |
| GET    | `/api/tasks/:id` | Get a single task |
| PATCH  | `/api/tasks/:id` | Update a task |
| DELETE | `/api/tasks/:id` | Soft-delete a task |
| POST   | `/api/tasks/:id/comments` | Add a comment to a task |

Invalid input returns `400` with a JSON error body.

## Configuration

| Variable | Default | Purpose |
|----------|---------|---------|
| `TASKFLOW_DB` | `taskflow.db` | Path to the SQLite database file |
| `PORT` | `8000` | Port the server listens on |
| `APP_PORT` | `8010` | Host port published by docker-compose (8010 so it runs beside `example-site`) |

## Project layout

```
src/
├── types.ts      # Domain interfaces + status/priority union types (no `any`)
├── db.ts         # better-sqlite3 connection, WAL mode, initDb() + seed
├── services.ts   # Business logic + validation (throws ValidationError)
├── routes.ts     # Express router + HTML dashboard
├── app.ts        # createApp() factory (middleware, routes, error handler)
└── server.ts     # Process entrypoint (reads env, listens)
tests/
├── services.test.ts
└── routes.test.ts
```

## Project documentation

- `CLAUDE.md` — repo configuration: commands, ports, traps, locked decisions. The protocol
  itself (`../../AGENTS.md`) loads through the framework root's `CLAUDE.md`, never by import.
- `.claude/` — hooks, rules, skills and reviewer subagents, symlinked to the framework root
  by `../../scripts/sync-repo.sh`
- `bin/check`, `bin/doctor` — the test command and the `CLAUDE.md` health check
- `.docs/CHANGELOG.md` — change history (append under `## [Unreleased]`)
- `.docs/learnings/` — lessons that will recur, split by domain
- `.docs/plans/` — `<issue>-<slug>.md` plans
- `.docs/TEST_LEDGER.md` — pre-existing test failures
