# Database learnings — Example Site (TaskFlow)

Migrations, queries, encoding, data integrity. Newest first. Format and promotion rule:
`README.md` in this directory.

## 2026-06-01 — Build dynamic `UPDATE`s from a column whitelist; bind every value (#1)

**Context:** writing `PATCH /api/tasks/<id>`, which updates only the fields the client sends.
**What happened:** the obvious shortcut — an f-string over the request keys — puts
client-controlled column names and values into SQL.
**Rule:** always use `?` placeholders with a values tuple, never f-strings or `%` formatting.
For a dynamic `SET` clause, take the column names from a fixed whitelist and still bind the
values as parameters.
**Applies to:** all repos

## 2026-06-01 — Every read filters `deleted_date IS NULL` (#1)

**Context:** tasks are soft-deleted through a nullable integer `deleted_date` (legacy lineage).
**What happened:** `DELETE /api/tasks/<id>` returns `200` with the task body, because the row
still exists — it is only hidden from default queries. A read that forgets the filter shows it
again.
**Rule:** never hard-delete a task. Every read query adds `AND deleted_date IS NULL`, and every
listing has a test asserting a soft-deleted row is absent.
**Applies to:** legacy-lineage repos

## 2026-06-01 — SQLite in WAL mode needs one process owning the file (#1)

**Context:** serving the dashboard while the API writes.
**What happened:** without WAL, readers block behind a write; with several Gunicorn workers,
several processes contend for one database file.
**Rule:** set `PRAGMA journal_mode=WAL` on every new connection in the connection helper. Run
a single Gunicorn worker with `--threads 2` so one process owns the file.
**Applies to:** this repo
