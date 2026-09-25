# Example Site (TaskFlow)

**Verified:** [YYYY-MM-DD — set the first time every command below has been run and worked. The
application source is not bundled yet, so none has.]

## ROLE
Senior Python developer — Flask service with a minimal server-rendered dashboard.

## STACK
Python 3, Flask (app factory), SQLite in WAL mode, Jinja2 templates (no frontend build),
pytest + pytest-cov, Gunicorn in the container.

**Schema lineage:** legacy (integer `deleted_date`, `created_date`, `updated_date`) — never mixed.
**Test database:** SQLite — the production engine, so a temporary SQLite file per test is legitimate.

## COMMANDS

| Purpose | Command |
| --- | --- |
| Exec prefix `{EXEC_RAW}` | `docker compose exec app` |
| Tests for one file or filter | `docker compose exec app pytest tests/test_routes.py --cov=app` (filter: `-k`) |
| Full suite with coverage | `bin/check` (resolves to `pytest --cov --cov-fail-under=80`) |
| Lint | none configured yet |
| Frontend build | none — Jinja2 templates |
| Dev server | `flask --app app run` (http://127.0.0.1:5000) |
| Database init | `flask --app app init-db` |
| Database dump (before destructive migrations) | `sqlite3 "$TASKFLOW_DB" .dump > database/backups/taskflow-$(date +%s).sql` |

## PORTS
App `APP_PORT` 8000 (container), 5000 (native Flask). Registry: `../../.context/reference/docker.md`.

## MAP

| What | Where |
| --- | --- |
| Application code | `app/` (`__init__.py`, `db.py`, `services.py`, `routes.py`) |
| Schema | `app/schema.sql` |
| Templates | `app/templates/`, `app/static/` |
| Tests | `tests/` (`conftest.py`, unit + feature) |
| Plans | `.docs/plans/<issue>-<slug>.md` |
| Design docs | `.docs/design/<issue>-<slug>.md` |
| Changelog | `.docs/CHANGELOG.md` — append under `## [Unreleased]`; never read whole |
| Learnings | `.docs/learnings/<domain>_learnings.md` |
| Failure ledger | `.docs/TEST_LEDGER.md` |

## TRAPS
- A read without `deleted_date IS NULL` shows soft-deleted tasks again.
- More than one Gunicorn worker means several processes contending for one SQLite file.

## BLAST RADIUS
- `taskflow.db` is shared by the API and the dashboard in the same process.

## LOCKED DECISIONS

| Decision | Date | Reasoning |
| --- | --- | --- |
| SQLite, single Gunicorn worker with `--threads 2` | 2026-06-01 | `.docs/learnings/database_learnings.md` |
| Soft delete through integer `deleted_date`; never hard-delete | 2026-06-01 | `.docs/learnings/database_learnings.md` |

## DEBUG PATTERNS
`print()` `breakpoint()` `pdb.set_trace()` `import pdb`

## REPO RULES
- All SQL uses `?` placeholders — never string interpolation.
- Validation lives in `app/services.py` and raises `ValidationError`; routes turn it into a 400 JSON response.
- Configuration comes from environment variables (`TASKFLOW_DB`, `APP_PORT`) — no secrets in code.
