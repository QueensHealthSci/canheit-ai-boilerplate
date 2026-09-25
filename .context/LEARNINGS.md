# Cross-repo learnings

Lessons that have been learned **in more than one repo**. A rule here applies everywhere: it
is not repeated in any repo's own `.docs/learnings/`, and when one is added here the local
copies are deleted.

Without a shared file, every repo relearns the same lessons alone. The five entries below are
seeded examples of lessons seen repeatedly across repos — the kind worth writing down once
rather than waiting to be rediscovered.

## Promotion rule

When the same `Rule:` appears in a second repo's `.docs/learnings/`, move it here and delete both
local copies. If it can be made mechanical instead, prefer that: a linter rule, a hook or a
`.claude/rules/` entry costs nothing at plan time and cannot be forgotten. Every entry below
names where it is now enforced, and "nowhere yet" is an honest answer.

---

## 2026-09-21 — Custom soft deletes hard-delete through the query builder

**Context:** Seen repeatedly across repos that use a custom soft-delete trait. The most
expensive recurring lesson of the five.

**What happened:** Three distinct failures, all from the same root cause — the house
`HasSoftDeletes` trait attaches behaviour to the *model*, and the query builder does not go
through it.

- `Model::where(...)->delete()` **hard-deletes**. It looks identical to a soft delete at the
  call site and there is no error.
- `withoutGlobalScopes()` silently removes the `notDeleted` scope along with whatever you
  meant to drop. In one repo this surfaced as a security hole — deleted records visible to
  users — **after the module reported 100% line coverage**.
- `deleted_date` missing from `$fillable` makes an `updateOrCreate` restore a silent no-op.

**Rule:** Load the model and call `->softDelete()`. Never `->delete()` on a builder. If you
must use `withoutGlobalScopes()`, re-add `notDeleted` explicitly and write a test that a
deleted row stays hidden. Give every listing endpoint a test asserting a soft-deleted row is
absent.

**Applies to:** legacy-lineage repos (integer `created_date`/`updated_date`/`deleted_date`,
`{table_singular}_id` keys).

**Enforced:** `.claude/rules/laravel.md`. Previously covered by seven words in the
retired `.agents/dba.md` persona, which is why it kept recurring.

---

## 2026-09-21 — A test suite on SQLite does not verify a MySQL migration

**Context:** Seen repeatedly in repos that run tests on SQLite `:memory:` and ship on MySQL.

**What happened:** Differences that only appear in production — NULLs behave differently in
unique indexes, JSON columns are stored as text, ENUM and column-width constraints are not
enforced, and index and constraint migrations pass against a schema SQLite silently accepted.
One repo's own learnings put it best: "an index or constraint migration verified only on
SQLite is not verified."

**Rule:** Tests run on the same database engine as production. Repos that already do have
none of these entries.

**Applies to:** all repos.

**Enforced:** `AGENTS.md` repo-file contract and `.claude/rules/laravel.md`.

---

## 2026-09-21 — "Already present" is the normal case for a recurring import

**Context:** Seen repeatedly across repos with scheduled imports and ETL jobs.

**What happened:** Imports written to treat an existing row as an error. Re-running a job
then fails, or duplicates, or both, and the first real re-run happens at the worst time.

**Rule:** Recurring imports and ETL jobs are idempotent. Re-running produces the same result.
An existing row is a normal outcome, not an error — match on a natural key, upsert, and log
the skip count rather than raising.

**Applies to:** all repos.

**Enforced:** `.claude/rules/laravel.md` and `.claude/rules/python.md`.

---

## 2026-09-21 — A gate that cannot fail is not evidence

**Context:** Seen repeatedly across repos, for both coverage and lint.

**What happened:** A linter silently rotted to dozens of findings across dozens of files
while consecutive CHANGELOG entries claimed it clean. Separately, coverage percentages were reported in repos
with no coverage driver installed, where the tooling cannot produce a number at all.
As one repo's own entry put it: "an instrument that cannot fail is not evidence."

**Rule:** Never claim a check you did not run. If the driver or the tool is missing, say it is
unmeasurable and name what is missing. A percentage nobody measured is worse than an admitted
gap, because it stops anyone looking.

**Applies to:** all repos.

**Enforced:** `AGENTS.md` non-negotiables 6 and 9; the `/verify` skill says it explicitly.

---

## 2026-09-21 — Pre-existing failures need an exit, not a log line

**Context:** Seen repeatedly across repos with long-lived failing tests.

**What happened:** The failure protocol offered Fix Now, Fix Later or Skip, and nothing
escalated a repeated Fix Later. One repo logged the same two failing tests six times over
five months; one entry reads "fifth consecutive deferral". The last entry
had to issue a CORRECTION, because a stale "four failures" sentence had been copied into
several plans and quoted back as current.

**Rule:** Log a pre-existing failure in `.docs/TEST_LEDGER.md`, never in prose and never in a
plan. Two deferrals is the cap. Link to the ledger; do not copy counts out of it.

**Applies to:** all repos.

**Enforced:** `AGENTS.md` Step 4 and the `/verify` skill; `TEMPLATE_TEST_LEDGER.md`.
