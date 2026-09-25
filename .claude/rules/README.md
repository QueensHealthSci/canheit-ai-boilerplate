---
# Documentation about rules rather than a rule, so it ships everywhere: `applies: **` is how
# a file says "every repo" without either script needing to know its name.
applies:
  - "**"
paths:
  - ".claude/rules/**"
---
# Path-scoped rules

Stack detail that loads **only when a matching file is touched**. A `paths:` frontmatter
list is what makes that work: editing a `.vue` file brings `vue.md` into context and nothing
else. `shared.md` has no `paths:` and therefore loads every session, which is why it is
capped at 50 lines.

## Two frontmatter keys, two questions

`paths:` answers **when does this load**. `applies:` answers **which repos install it**, and
they are not the same question. `laravel.md` should load when you edit `tests/` inside a
Laravel repo, but every language has a `tests/` directory, so using that as the install
signal put Laravel rules into a legacy PHP repo. `node-ts.md`'s `**/*.spec.ts` — shared with
`e2e.md` — put NestJS rules into every Laravel repo with Playwright.

A rule with no `applies:` falls back to `paths:`, which is right for most. A rule with
neither installs everywhere. Both scripts read these keys through
`scripts/_detect.sh`, so **adding a rule needs no edit to any script**.

| File | Installs where (`applies:`) | Loads when you touch (`paths:`) | Lines |
| --- | --- | --- | --- |
| `shared.md` | every repo | always | 46 |
| `laravel.md` | `artisan` | `app/`, `Modules/`, `database/`, `routes/`, `config/`, `tests/` | 74 |
| `vue.md` | *falls back to `paths:`* | `resources/js/`, `resources/css/`, `*.vue` | 48 |
| `legacy-php.md` | *falls back to `paths:`* | `www-root/`, `*.inc.php` | 58 |
| `python.md` | *falls back to `paths:`* | `*.py`, `etl/`, `requirements*.txt` | 50 |
| `node-ts.md` | `apps/`, `packages/`, `prisma/` | those three, plus `*.spec.ts` | 61 |
| `e2e.md` | *falls back to `paths:`* | `e2e/`, `tests/e2e/`, `*.spec.ts`, `playwright.config.*` | 76 |
| `README.md` | `**` — it is docs, not a rule | `.claude/rules/**` | this file |

Detection ignores `.claude/` itself, or the framework would trigger its own rules: a PHP
repo's only `.py` file can be the hooks' own `_strip.py`.

## What belongs here

**Deviations from the framework default, and traps that have cost someone time.** Not
tutorials. A single monolithic `coding_standards.md` runs to thousands of lines, most of them worked
examples of idioms the model already knows; these seven files are about 400 lines total and
cost nothing until they are relevant.

Before adding a rule, ask where else it could live:

1. A linter or hook config — cheapest, runs every time, zero context. See
   the framework root's `.context/enforcement.md`.
2. A path-scoped rule here — costs context only in a matching session.
3. The repo's own `CLAUDE.md` TRAPS section — if it is true of one repo only.

`AGENTS.md` is none of these: it carries gates and non-negotiables, not stack detail.

## Installing

Rules do not inherit from a parent directory, so each repo needs its own `.claude/rules/`.
`scripts/sync-repo.sh <repo>` **symlinks** them to the canonical files, taking only what that
repo needs — a Laravel repo has no use for `node-ts.md`. A link means an edit here reaches
every repo at once and drift is impossible. Use `--copy` only for a checkout that will live
outside the workspace, where a link would dangle.

## When a repo needs something different

Shared content is linked, so it is identical everywhere by construction. Divergence has four
places to live, in order of preference:

1. **Configure it.** Hooks read `FRAMEWORK_BACKUP_DIR`, `FRAMEWORK_BACKUP_WINDOW_MIN`,
   `FRAMEWORK_VERIFIED_MAX_DAYS` and `FRAMEWORK_FRONTEND_RE`. The repo's `CLAUDE.md` carries
   its commands, ports, traps and locked decisions. Most "this repo is different" is this.
2. **Select it.** `sync-repo` links only the rules a repo needs — it detects Laravel, Vue,
   `www-root`, Python and Prisma. A Laravel repo never sees `node-ts.md`.
3. **Add to it.** Drop a repo-only file beside the links: `.claude/rules/<your-rule>.md`,
   `.claude/hooks/guard-<your-thing>.sh`, a skill of your own. Entries are linked individually,
   so a re-sync leaves anything with no canonical counterpart alone. `check-framework`
   reports these as `repo-only` — visible, not a problem.
4. **Override it.** Replace a symlink with a real file. Nothing stops you, but
   `check-framework` FAILs on it: an override is a fork of shared content and has to earn
   its keep. Record why under LOCKED DECISIONS in the repo `CLAUDE.md`, or re-link.

What should *not* happen is a rule that is true of two repos living in both. That is the
promotion rule: it moves to the canonical file and both copies go.
