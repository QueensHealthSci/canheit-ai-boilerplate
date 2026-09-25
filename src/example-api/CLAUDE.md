# Example API (TaskFlow)

**Verified:** [YYYY-MM-DD — set the first time every command below has been run and worked. The
application source is not bundled yet, so none has.]

## IMPORTS
@../../.agents/architect.md
@../../.agents/security.md

## ROLE
Senior TypeScript / Node.js developer — Express service with a server-rendered dashboard.

## STACK
Node, TypeScript (strict, `noUncheckedIndexedAccess`, NodeNext modules), Express,
better-sqlite3 (synchronous) in WAL mode, Vitest + supertest.

**Schema lineage:** legacy (integer `deleted_date`, `created_date`, `updated_date`) — never mixed.
**Test database:** SQLite `:memory:` — the production engine, so an in-memory database is legitimate here.

## COMMANDS

| Purpose | Command |
| --- | --- |
| Exec prefix `{EXEC_RAW}` | `docker compose exec app` |
| Node service `{EXEC_NODE}` | `docker compose exec app` |
| Tests for one file or filter | `npm test -- tests/routes.test.ts` (filter: `-t "soft delete"`) |
| Full suite with coverage | `bin/check` (resolves to `npm test`, i.e. `vitest run --coverage`) |
| Static analysis / types | `npm run build` (`tsc` → `dist/`) |
| Lint | none configured yet |
| Dev server | `npm run dev` (tsx watch, http://localhost:8000) |
| Database dump (before destructive migrations) | `sqlite3 "$TASKFLOW_DB" .dump > database/backups/taskflow-$(date +%s).sql` |

## PORTS
App `PORT` 8000 inside the container; host `APP_PORT` 8010, so it can run beside
`example-site`. Registry: `../../.context/reference/docker.md`.

## MAP

| What | Where |
| --- | --- |
| Application code | `src/` (`app.ts`, `server.ts`, `db.ts`, `services.ts`, `routes.ts`) |
| Types | `src/types.ts` — every entity has an interface |
| Tests | `tests/` (unit for services, supertest for routes) |
| Plans | `.docs/plans/<issue>-<slug>.md` |
| Design docs | `.docs/design/<issue>-<slug>.md` |
| Changelog | `.docs/CHANGELOG.md` — append under `## [Unreleased]`; never read whole |
| Learnings | `.docs/learnings/<domain>_learnings.md` |
| Failure ledger | `.docs/TEST_LEDGER.md` |

## TRAPS
- Relative imports need `.js` even in `.ts` source (NodeNext); omitting it fails at runtime.
- `req.params.id` is `string | undefined` under `noUncheckedIndexedAccess` — parse, don't `!`.
- A read without `deleted_date IS NULL` shows soft-deleted tasks again.

## BLAST RADIUS
- The dashboard renders stored values: anything not passed through `escapeHtml` is XSS.

## LOCKED DECISIONS

| Decision | Date | Reasoning |
| --- | --- | --- |
| better-sqlite3 (synchronous), no ORM | 2026-06-02 | `.docs/learnings/database_learnings.md` |
| Soft delete through integer `deleted_date`; never hard-delete | 2026-06-02 | `.docs/learnings/database_learnings.md` |

## DEBUG PATTERNS
`console.log` `console.debug` `debugger`

## REPO RULES
- No `any`. Every data structure has an interface in `src/types.ts`.
- All SQL uses prepared statements with `?` placeholders — never string interpolation.
- Business logic and validation live in `src/services.ts` and raise `ValidationError`; the error
  handler in `src/app.ts` maps it to `400`. Route handlers stay thin.
- Configuration comes from environment variables (`TASKFLOW_DB`, `PORT`) — no secrets in code.
