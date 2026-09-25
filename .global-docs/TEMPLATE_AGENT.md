# {REPO NAME}

<!--
Copy to the repo root as CLAUDE.md. Claude Code only — no GEMINI.md, AGENTS.md, .cursorrules.

CONFIGURATION, not policy. AGENTS.md owns the cycle, gates, coverage, branch and plan locations
and the definition of done; restate none of it. Where they disagree, AGENTS.md wins and this
file is the bug. Every value must be real and current — a stale value is worse than a missing
one, because the agent will act on it. Delete rows that do not apply; never leave a placeholder.

Do NOT import AGENTS.md: it loads by ancestor walk-up through the framework root's CLAUDE.md,
and an explicit import raises an approval dialog every session and resolves to nothing in a
clone outside the framework workspace.
Under 100 lines. Architecture narrative goes in .docs/ARCHITECTURE.md.
-->

**Verified:** [YYYY-MM-DD — the last date every command below was run and worked]

## ROLE
[e.g. Senior PHP developer in a legacy in-house PHP codebase | Senior TypeScript/NestJS developer]

## STACK
[Language, framework, database, frontend, auth, key packages — with versions. Only what
changes how code is written here.]

**Schema lineage:** [legacy (integer `deleted_date`, `{table}_id` keys) | framework-default (`deleted_at`, `id`) | prisma (`deletedAt`, uuid `id`)] — never mixed.
**Test database:** [same engine as production — name it. SQLite in-memory is not acceptable.]

## COMMANDS
<!-- Each runs as written; `bin/doctor` dry-runs them against the Verified date.
     A changed command is changed here in the same commit. -->

| Purpose | Command |
| --- | --- |
| Exec prefix `{EXEC_RAW}` | |
| Framework CLI `{EXEC}` | |
| Node service `{EXEC_NODE}` | |
| Tests for one file or filter | |
| Full suite with coverage | |
| Lint | |
| Static analysis / types | |
| Frontend build | |
| Dev server | |
| Database dump (before destructive migrations) | |

## PORTS
[App, database, cache, mail, Vite — from the port registry in `../../.context/reference/docker.md`, never from memory; collisions between repos are a known problem.]

## MAP
<!-- Paths only. The .docs/ rows are the framework default; change one only if this repo
     truly differs, and say why under LOCKED DECISIONS. -->

| What | Where |
| --- | --- |
| Application code | |
| Modules / domains | |
| Tests | |
| Migrations | |
| Frontend source | |
| Plans | `.docs/plans/<issue>-<slug>.md` |
| Design docs | `.docs/design/<issue>-<slug>.md` |
| Changelog | `.docs/CHANGELOG.md` — append under `## [Unreleased]`; never read whole |
| Learnings | `.docs/learnings/<domain>_learnings.md` |
| Failure ledger | `.docs/TEST_LEDGER.md` |
| Architecture | `.docs/ARCHITECTURE.md` |

## TRAPS
<!-- What has actually bitten someone: what looks right, what happens instead — connection
     names, soft-delete columns, engine differences. In LEARNINGS twice? It belongs here. -->
-

## BLAST RADIUS
<!-- What a change here breaks that the diff will not show: shared tables, other repos on this
     database, scheduled jobs, integrations, deploy scripts that read committed files. -->
-

## LOCKED DECISIONS
<!-- Settled questions a session must not reopen. Date and where the reasoning lives. -->

| Decision | Date | Reasoning |
| --- | --- | --- |
| | | |

## FEATURE CHECKLIST
<!-- Optional. What every new feature here must include that the protocol cannot know —
     a permission seeded, a menu entry, a shared-package export. -->
-

## DEBUG PATTERNS
[e.g. `dd()` `dump()` `var_dump()` `console.log` `debugger` `print()`]

## REPO RULES
<!-- Additive only; true here and nowhere else. Cycle, gates and coverage belong to AGENTS.md;
     stack-wide conventions belong in .claude/rules/, which load by path. -->
-
