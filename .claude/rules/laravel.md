---
# When to LOAD: any of these files. When to INSTALL: `applies` below — `tests/**` is a fair
# load-trigger in a Laravel repo and a poor install signal anywhere, since every language has one.
applies:
  - "artisan"
paths:
  - "app/**"
  - "Modules/**"
  - "database/**"
  - "routes/**"
  - "config/**"
  - "tests/**"
---
# Laravel — house deviations from framework defaults

Only what differs from stock Laravel, or has cost real time. Framework idioms
you already know are not repeated.

## Custom soft deletes (legacy-lineage repos)

These repos use an integer `deleted_date` and a house `HasSoftDeletes` trait, **never**
Illuminate's `SoftDeletes`. The trait adds a `notDeleted` global scope and a
`softDelete()` method — named that deliberately, so it does not override Eloquent's
`delete()`.

Four traps, each found the hard way in more than one repo:

- **Query-builder `->delete()` hard-deletes.** `Model::where(...)->delete()` bypasses the
  trait entirely. Load the model and call `->softDelete()`.
- **`withoutGlobalScopes()` silently drops the `notDeleted` scope.** This was found as a
  security hole *after* the module reported 100% line coverage. If you must drop other
  scopes, re-add `notDeleted` explicitly and add a test that a deleted row stays hidden.
- **`deleted_date` must be in `$fillable`** where a flow restores rows through
  `updateOrCreate`, or the restore is a silent no-op.
- **Every listing endpoint gets a test** asserting a soft-deleted row is absent.

A repo that mixes both — some models on `deleted_date`, some on the Illuminate trait — has
a defect to report, not a pattern to copy.

## Modules

`nwidart/laravel-modules`, but at the non-default path `app/Modules/<Name>`, namespace
`App\Modules\<Name>\<Layer>`. Cross-module calls go through the other module's **Service**,
never its models or tables.

## Controllers, requests, services

- Validation only in FormRequest classes. `$request->validated()`, never `$request->all()`.
- Authorization in Policies, wired with `authorizeResource` in the constructor. A check in
  a Blade or Vue template is not a guard.
- Business logic in Services or Actions, constructor-injected, stateless between calls.
- Route model binding rather than a manual `find()`.

## Imports and jobs

Recurring imports are **idempotent**: "already present" is the normal case, not an error.
This is relearned in repo after repo. Long-running work goes to a queued job; an Artisan
command delegates to a service and holds no logic.

## Tests

The test database is the production engine — for a MySQL app, `phpunit.xml` sets
`DB_CONNECTION=mysql`. SQLite standing in produces a steady stream of surprises: NULLs in
unique indexes, JSON stored as text, ENUM and column-width behaviour.

Every public feature needs a happy path, a validation failure, and **both** an allowed and a
denied authorization test.

## Versions

Repos drift apart — one on Laravel 10, another on 13. Write for the version in the repo you
are in; its `CLAUDE.md` STACK section records it. Check `composer.json` rather than assuming.
