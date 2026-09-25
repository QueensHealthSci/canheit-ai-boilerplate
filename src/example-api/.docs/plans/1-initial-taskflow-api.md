# Task: Initial TaskFlow API (TypeScript) — Issue #1
**Status:** Complete
**Issue:** #1
**Tier:** Standard
**Module:** Example API (TaskFlow)

## 1. Goal
Provide a strict-TypeScript / Node twin of the Python `example-site`, implementing the same
task-tracker domain so readers can compare the boilerplate's standards across two stacks.

## 2. Architecture & Design
- **Pattern:** Express app factory + service layer + thin route handlers
- **Data Flow:** request → route → service (validation + parameterized SQL) → SQLite → JSON / HTML
- **New Files:**
    - [x] `src/types.ts`, `src/db.ts`
    - [x] `src/services.ts`, `src/routes.ts`
    - [x] `src/app.ts`, `src/server.ts`
    - [x] `tests/services.test.ts`, `tests/routes.test.ts`
    - [x] `package.json`, `tsconfig.json`, `vitest.config.ts`
    - [x] `Dockerfile`, `docker-compose.yml`

## 3. Security Analysis (Critical)
- [x] **Auth:** Out of scope for the example (no login). Documented as a deliberate omission.
- [x] **Validation:** All request bodies validated in the service layer.
- [x] **Data:** No PII beyond sample names/emails in seed data.
- [x] **Risk:** Parameterized SQL throughout; HTML dashboard output escaped to prevent XSS.

## 4. Implementation Steps
1. [x] **Schema:** Create the four tables (in `db.ts`) with indexes and seed rows.
2. [x] **Types:** Interfaces + union types, strict mode, no `any`.
3. [x] **Backend:** Service logic with `ValidationError`.
4. [x] **API:** REST routes + HTML dashboard.
5. [x] **Tests:** Vitest unit + supertest feature tests above 80% coverage.

## 5. Verification Strategy
- [x] **Unit Test:** Services — happy path, validation failure, soft delete, comments.
- [x] **Feature Test:** Routes — create/list/patch/delete, 404, 400 on invalid/malformed input.
- [x] **Coverage Check:**
    - Does this touch Auth, Payments, or Security? **NO**
    - Minimum 80% coverage targeted.

> **Note:** Run `npm install && npm test` to confirm the suite passes in your environment
> (better-sqlite3 installs a prebuilt binary on common platforms).
