# Task: Initial TaskFlow example — Issue #1
**Status:** Complete
**Issue:** #1
**Tier:** Standard
**Module:** Example Site (TaskFlow)

## 1. Goal
Build a small, fully-runnable task tracker that demonstrates the project-level conventions of
the boilerplate (repo-level agent file, `.docs/` memory, standards-compliant source).

## 2. Architecture & Design
- **Pattern:** Flask app factory + service layer + thin route handlers
- **Data Flow:** request → route → service (validation + SQL) → SQLite → JSON / HTML response
- **New Files:**
    - [x] `app/__init__.py`, `app/db.py`, `app/schema.sql`
    - [x] `app/services.py`, `app/routes.py`
    - [x] `app/templates/dashboard.html`, `app/static/style.css`
    - [x] `tests/conftest.py`, `tests/test_services.py`, `tests/test_routes.py`
    - [x] `Dockerfile`, `docker-compose.yml`, `entrypoint.sh`

## 3. Security Analysis (Critical)
- [x] **Auth:** Out of scope for the example (no login). Documented as a deliberate omission.
- [x] **Validation:** All request bodies validated in the service layer.
- [x] **Data:** No PII beyond a sample name/email in seed data.
- [x] **Risk:** Parameterized SQL throughout; no IDOR-sensitive ownership model in scope.

## 4. Implementation Steps
1. [x] **Schema:** Create the four tables with indexes and seed rows.
2. [x] **Backend:** Service logic with `ValidationError`.
3. [x] **API:** REST routes + HTML dashboard.
4. [x] **Tests:** Unit + feature tests above 80% coverage.

## 5. Verification Strategy
- [x] **Unit Test:** Services — happy path, validation failure, soft delete.
- [x] **Feature Test:** Routes — create/list/patch/delete, 400 on invalid input.
- [x] **Coverage Check:**
    - Does this touch Auth, Payments, or Security? **NO**
    - Minimum 80% coverage met (95% achieved).
