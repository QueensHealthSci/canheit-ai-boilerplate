# Example API (TaskFlow) — Agent Configuration

## INHERITANCE
Global Protocol: ../../AGENT.md
This file extends the CLI Development Protocol. All global rules and workflow
steps apply. Do not deviate from AGENT.md unless explicitly noted below.

## ROLE OVERRIDE
Role: Senior TypeScript / Node.js Developer

## CONTAINER ENVIRONMENT
Type: Docker Compose
Exec Prefix: docker compose exec app
Example: docker compose exec app npm test

## FRONTEND BUILD
Source Directory: N/A (server-rendered HTML dashboard, no separate frontend build)
Build Command: npm run build   (compiles TypeScript → dist/ via tsc)
Dev Server: npm run dev         (tsx watch, http://localhost:8000)

## TESTING
Framework: Vitest (+ supertest for HTTP feature tests)
Feature Test Command: npm test -- tests/routes.test.ts
Full Suite Command: npm test            (runs `vitest run --coverage`)
Filter Flag: -t   (e.g. `npm test -- -t "soft delete"`)

## DEBUG STATEMENTS TO CHECK
Patterns: console.log | console.debug | debugger

## CODING STANDARDS
Reference: ../../.context/rules/coding_standards.md (Vue/TypeScript + Python sections;
the TypeScript strictness rules apply directly to this Node service)
Additional Standards: See the `.agents/architect.md` and `.agents/security.md` specialists.

## REPO-SPECIFIC RULES
- TypeScript strict mode — **no `any`**. Every data structure has an interface in `src/types.ts`.
- All SQL uses better-sqlite3 prepared statements with `?` placeholders — never string interpolation.
- Tasks are soft-deleted via a nullable `deleted_date` integer column — never hard-delete.
- SQLite runs in WAL mode (`PRAGMA journal_mode = WAL`).
- Config comes from environment variables (`TASKFLOW_DB`, `PORT`) — no secrets in code.
- Business logic and validation live in `src/services.ts` and raise `ValidationError`; the
  Express error handler in `src/app.ts` maps that to a `400` JSON response.
- Route handlers stay thin: parse input, call a service, return the result.
- NodeNext module resolution requires `.js` extensions on relative imports (even from `.ts`).
- Any value interpolated into the HTML dashboard must be passed through `escapeHtml`.
