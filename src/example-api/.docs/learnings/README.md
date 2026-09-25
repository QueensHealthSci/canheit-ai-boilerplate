# Learnings by domain — Example API (TaskFlow)

Team-shared institutional knowledge: committed, versioned, reviewed. Separate from Claude
Code's per-user auto-memory, which is personal and not shared.

Split by domain so a session reads only what matches the work. This is the standard for
every repo, large or small.

| File | Scope |
| --- | --- |
| `backend_learnings.md` | services, controllers, models, business logic |
| `database_learnings.md` | migrations, queries, encoding, data integrity |
| `docker_learnings.md` | containers, environments, local setup |
| `frontend_learnings.md` | components, state, build tooling |
| `process_learnings.md` | workflow, testing, review, release |
| `security_learnings.md` | authentication, authorization, data protection |

**A domain file is created when it gets its first entry, not before.** Creating all six up
front tends to leave them at zero bytes while entries pile up in one monolith — the scaffold
is not the point, the entries are.

## Entry format

```markdown
## YYYY-MM-DD — Short imperative title (#issue)

**Context:** one or two sentences on what was being done.
**What happened:** the surprise — the error text, or the behaviour you did not expect.
**Rule:** the generalised lesson, written as an instruction the next person can follow.
**Applies to:** this repo | legacy-lineage repos | all Laravel repos | all repos
```

Newest first within each file.

`Rule:` and `Applies to:` are not decoration. They are what makes promotion mechanical: when
the same `Rule:` appears in a second repo, it moves to `../../../.context/LEARNINGS.md` or
into a `.claude/rules/` file, and both local copies are deleted. An entry without
`Applies to:` cannot be promoted without being rewritten first.

## When to write one

When something non-obvious cost you time and will cost the next person the same: an implicit
assumption that turned out false, a framework behaviour that surprised you, a gotcha nobody
could infer from the code.

**Not** for: anything a test now covers, anything true only of the task you just finished, a
pre-existing test failure (that is `TEST_LEDGER.md`), or a decision and its rationale (that
is `.docs/design/`).

A repo that adds a learning to every change is writing a diary. A repo that never adds one is
relearning the same lesson.

## Size

**Cap each domain file near 300 lines.** Past that, split by sub-topic within the domain
rather than growing one file — the whole point of the split is that reading one domain is
cheap. Lines matter less than width: a single entry wrapped into one 2,900-character line
costs as much as fifty normal ones.

## Archiving

Move entries older than a year that were never promoted to `.docs/learnings/archive/`. An
entry that has not recurred in a year is history, and history should not cost context at plan
time.

## Reading it

`/ticket` reads the domain matching the work — never the whole directory.
