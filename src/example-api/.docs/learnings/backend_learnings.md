# Backend learnings — Example API (TaskFlow)

Services, routes, types, business logic. Newest first. Format and promotion rule:
`README.md` in this directory.

## 2026-06-02 — Validation lives in services; the error handler maps it to 400 (#1)

**Context:** deciding where input checks go for the task and project endpoints.
**What happened:** validation inside route handlers can only be tested through HTTP.
**Rule:** `src/services.ts` raises `ValidationError`; the error handler in `src/app.ts` turns it
into a `400` JSON response. Route handlers stay thin, and services are unit-tested without HTTP.
**Applies to:** all repos

## 2026-06-02 — `noUncheckedIndexedAccess` makes params possibly undefined (#1)

**Context:** strict TypeScript with `noUncheckedIndexedAccess` enabled.
**What happened:** `arr[0]` and `req.params.id` are typed `string | undefined`, and the quick
fixes (`!`, `any`) defeat the flag.
**Rule:** narrow with a guard, or destructure with a default. Validate and parse route params
in the handler before passing them to a service.
**Applies to:** all TypeScript repos

## 2026-06-02 — NodeNext needs `.js` on relative imports, even in `.ts` (#1)

**Context:** `"module": "NodeNext"` in `tsconfig.json`.
**What happened:** `import { getDb } from './db'` compiles, then fails at runtime — the
extension refers to the compiled output, and TypeScript rewrites nothing.
**Rule:** write `import { getDb } from './db.js'` in `.ts` source.
**Applies to:** all TypeScript repos
