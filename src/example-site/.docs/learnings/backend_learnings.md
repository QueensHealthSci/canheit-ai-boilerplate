# Backend learnings — Example Site (TaskFlow)

Services, routes, models, business logic. Newest first. Format and promotion rule:
`README.md` in this directory.

## 2026-06-01 — Validation lives in services, not routes (#1)

**Context:** deciding where input checks go for the task and project endpoints.
**What happened:** validation inside route handlers can only be tested through HTTP.
**Rule:** `app/services.py` raises `ValidationError` for bad input; routes catch it and return
`400` with a JSON error. Services stay unit-testable without the HTTP layer.
**Applies to:** all repos
