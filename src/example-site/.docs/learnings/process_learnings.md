# Process learnings — Example Site (TaskFlow)

Workflow, testing, review, release. Newest first. Format and promotion rule: `README.md` in
this directory.

## 2026-06-01 — One temporary database per test, seeded with a known dataset (#1)

**Context:** setting up the pytest suite.
**What happened:** tests sharing one database file depend on the order they run in.
**Rule:** `conftest.py` points `TASKFLOW_DB` at a temporary file per test and seeds a known
dataset. Cover the happy path, a validation failure and the soft-delete behaviour for each
resource.
**Applies to:** this repo
