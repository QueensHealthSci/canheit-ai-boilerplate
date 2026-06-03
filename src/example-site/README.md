# Example Site — TaskFlow

A small, intentionally simple **task tracker** that demonstrates the project-level conventions
of this boilerplate: a repo-level agent file (`CLAUDE.md`), a `.docs/` folder for project
memory, and source code that follows the shared coding standards.

It is a Flask + SQLite REST API with a minimal HTML dashboard. There is no frontend build step.

## Domain

| Entity | Description |
|--------|-------------|
| **User** | A person who can be assigned tasks and write comments. |
| **Project** | A container for tasks. |
| **Task** | A unit of work in a project — has a status (`todo`/`in_progress`/`done`) and priority. |
| **Comment** | A note attached to a task. |

Tasks are **soft-deleted** via a nullable `deleted_date` integer column.

## Running locally (no Docker)

```bash
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# Initialize the database and start the dev server
flask --app app init-db
flask --app app run
# Visit http://127.0.0.1:5000
```

## Running with Docker

```bash
cp .env.example .env
docker compose up -d --build
# Visit http://localhost:8000
```

## Running the tests

```bash
pytest --cov=app
# or inside the container:
docker compose exec app pytest --cov=app
```

The suite covers services (unit) and routes (feature), with coverage above the 80% threshold
required by the boilerplate.

## API

| Method | Path | Description |
|--------|------|-------------|
| GET    | `/` | HTML dashboard (projects with their tasks) |
| GET    | `/api/projects` | List projects |
| POST   | `/api/projects` | Create a project |
| GET    | `/api/tasks` | List tasks (optionally `?project_id=` / `?status=`) |
| POST   | `/api/tasks` | Create a task |
| GET    | `/api/tasks/<id>` | Get a single task |
| PATCH  | `/api/tasks/<id>` | Update a task |
| DELETE | `/api/tasks/<id>` | Soft-delete a task |
| POST   | `/api/tasks/<id>/comments` | Add a comment to a task |

Invalid input returns `400` with a JSON error body.

## Configuration

| Variable | Default | Purpose |
|----------|---------|---------|
| `TASKFLOW_DB` | `taskflow.db` | Path to the SQLite database file |
| `APP_PORT` | `8000` | Host port mapped to the container |

## Project documentation

- `CLAUDE.md` — repo-level agent configuration (inherits `../../AGENT.md`)
- `.docs/CHANGELOG.md` — change history
- `.docs/LEARNINGS.md` — technical lessons and gotchas
- `.docs/project-plans/` — per-feature plans
