# Learnings

Technical patterns, gotchas, and lessons learned while building the Example Site (TaskFlow).
This is the **project-specific** memory referenced by `AGENT.md` (Section 0, item 4). 

## SQLite WAL Mode
- WAL (`PRAGMA journal_mode=WAL`) allows the dashboard to read while a write is in progress.
- Set it on every new connection in the app factory / connection helper.
- Run a **single** Gunicorn worker so one process owns the database file; use `--threads 2`
  for concurrent dashboard requests.

## Soft Deletes
- Tasks use a nullable `deleted_date` integer (Unix timestamp). Never hard-delete a task.
- Every read query must add `AND deleted_date IS NULL` (or filter in the service layer).
- `DELETE /api/tasks/<id>` returns `200` with the (now soft-deleted) task body, because the
  row still exists — it is just hidden from default queries.

## Validation Lives in Services
- `app/services.py` raises `ValidationError` for bad input; routes catch it and return `400`
  with a JSON error. Keeping validation out of the route handlers makes it unit-testable
  without spinning up the HTTP layer.

## Parameterized SQL Only
- Always use `?` placeholders with a values tuple — never f-strings or `%` formatting in SQL.
- For dynamic `UPDATE` statements, build the `SET` clause from a fixed whitelist of column
  names and still bind the **values** as parameters.

## Testing
- `conftest.py` points `TASKFLOW_DB` at a temporary file per test and seeds a known dataset.
- Cover the happy path, a validation failure, and the soft-delete behavior for each resource.
