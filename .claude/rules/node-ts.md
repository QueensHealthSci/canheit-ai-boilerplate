---
# `**/*.spec.ts` is a load-trigger shared with e2e.md; on its own it would install NestJS
# rules into every Laravel repo that has Playwright specs.
applies:
  - "apps/**"
  - "packages/**"
  - "prisma/**"
paths:
  - "apps/**"
  - "packages/**"
  - "prisma/**"
  - "**/*.spec.ts"
---
# NestJS, Next.js, Prisma — house rules

The shared subset any NestJS/Next.js/Prisma repo here should follow. A repo that needs more
detail adds its own path-scoped rules beside this one (see `README.md`, "Add to it").

## Multi-tenancy is the first rule

Every model carries `tenantId`. Every query filters on it. Every business unique constraint
includes it — `@@unique([tenantId, slug])`, not `@@unique([slug])`. Every table is indexed
on it at minimum.

A query that forgets `tenantId` leaks across tenants and will not fail any test that uses a
single tenant. Write the two-tenant test.

## Prisma conventions

- Multi-file schema in `prisma/schema/`, numbered to match the feature spec
  (`013-users.prisma` → spec `013-user-management`). All enums in `001-enums.prisma`.
- Fields camelCase, columns snake_case via `@map()`, tables snake_case plural via `@@map()`.
- UUIDs `@db.Uuid`; timestamps `@db.Timestamptz(6)`; strings `@db.VarChar(N)` with an
  explicit length.
- Soft delete is `deletedAt` + `deletedBy`; audit is `createdAt`/`updatedAt` +
  `createdBy`/`updatedBy`. Every model has all six.

## Services

Tenant scoping and soft-delete filtering happen in the service, not the controller.
Controllers stay thin and delegate. Cursor pagination, not offset, for anything that grows.
Transactions for multi-step writes; race-safe updates where two requests can collide.

## Validation

Zod schemas in `packages/shared/src/schemas/`, one file per resource, re-exported from the
barrel. `CreateXSchema`, `UpdateXSchema`, `XListQuerySchema`, with the type inferred rather
than written twice.

## Tests

Unit tests mock Prisma entirely — no database. Controller tests mock the service and verify
delegation only. Guard tests exercise the access decision. Do not test DTOs, modules or the
schema itself.

## Where a Prisma repo differs from the rest

Its soft delete is `deletedAt` rather than `deleted_date` or `deleted_at` (the `prisma`
lineage in `shared.md`). Branching, backup, coverage and documentation rules in `AGENTS.md`
apply unchanged; nothing Laravel-shaped does.
