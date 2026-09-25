# Database learnings — Example API (TaskFlow)

Migrations, queries, encoding, data integrity. Newest first. Format and promotion rule:
`README.md` in this directory.

## 2026-06-02 — Every read filters `deleted_date IS NULL` (#1)

**Context:** tasks are soft-deleted through a nullable integer `deleted_date` (legacy lineage).
**What happened:** `DELETE /api/tasks/:id` sets the timestamp and returns the now-hidden task
body, because the row still exists. A read that forgets the filter shows it again.
**Rule:** never hard-delete a task. Default list and get queries add `deleted_date IS NULL`,
and every listing has a test asserting a soft-deleted row is absent.
**Applies to:** legacy-lineage repos

## 2026-06-02 — better-sqlite3 is synchronous; WAL is set once per connection (#1)

**Context:** choosing the SQLite driver and connection setup.
**What happened:** queries block and return directly — there is nothing to `await`.
**Rule:** use prepared statements (`db.prepare(...)`) with `?` placeholders and no `await`.
Set `PRAGMA journal_mode = WAL` once when the connection opens, so the dashboard can read
during a write. Tests open `:memory:` — the same engine as production, so it is legitimate.
**Applies to:** this repo
