# House rules — every file, every stack

<!-- No `paths:`, so this loads in every session. Keep it under 50 lines: it is always-on
     context. Anything stack-specific belongs in a sibling rule file that loads by path. -->

## Schema lineage

Every repo declares one lineage in its `CLAUDE.md`, and never mixes them.

| Lineage | Soft delete | Timestamps | Primary key | Typical of |
| --- | --- | --- | --- | --- |
| **legacy** | integer Unix `deleted_date` | `created_date`, `updated_date` | `{table_singular}_id` | older in-house PHP apps and the schemas that grew from them; `example-site` |
| **framework-default** | `deleted_at` via Illuminate `SoftDeletes` | `created_at`, `updated_at` | `id` | a greenfield Laravel app |
| **prisma** | `deletedAt` + `deletedBy` | `createdAt`, `updatedAt` | `id` uuid | a NestJS/Prisma app |

Framework-owned tables (sessions, cache, jobs, migrations) keep their own schema in every
lineage — do not "correct" them.

## Naming (all stacks)

Tables plural snake_case · columns snake_case · foreign key `{referenced_table_singular}_id`
· pivot tables alphabetical singular (`hospital_user`) · booleans prefixed `is_`/`has_`.

## Non-negotiable in code

- No secret, credential or connection string in code, config or a log line.
- No unbounded query: paginate or chunk anything that can grow.
- Filter user-owned data in the query, never in the view or the client.
- Tests run on the same database engine as production. Never an in-memory substitute.

## Memory

Repo-specific lessons go in that repo's `.docs/learnings/<domain>_learnings.md` — there is
no single `LEARNINGS.md`, so a session reads one domain. A lesson learned in **two**
repos is promoted to `../../.context/LEARNINGS.md` and both local copies deleted — read
that file before assuming a problem is new to this repo. It ships with five: custom
soft-delete traps, SQLite-versus-MySQL, idempotent imports, unmeasured gate claims, and
pre-existing failures needing an exit.

## What is enforced elsewhere, and not repeated here

Formatting, strict types, import order, `any`, debug statements, `env()` outside config,
N+1 and mass assignment are all caught by the linters and hooks — see
`../../.context/enforcement.md`. This file carries only what needs judgement.
