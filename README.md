# AI Development Boilerplate

A starter framework for **AI-assisted development** with a workflow that is enforced, not
just written down. It gives Claude Code the context to work like a disciplined senior
developer: pick a tier, plan, branch correctly, test to a measured coverage bar, get a
review from a separate reviewer, keep documentation in the same pull request, and never
commit straight to `develop` or `main`. Where a rule can be checked mechanically, a hook
checks it.

> This is a teaching example for a presentation on AI development. Everything here is
> generic — fork it, rename it, and adapt it to your own stack and team conventions.

## The idea

Don't re-explain your standards to the AI every session. Keep them in version control and
make each one cost context only when it is relevant:

- **A short protocol** (`AGENTS.md`) holding the gates and non-negotiables. It always loads.
- **Hooks** that enforce the mechanical rules: no commits on `main`, stage by path, no
  force-push, never read `.env*`, dump before a destructive migration.
- **Path-scoped rules** (`.claude/rules/`) that load only when you touch a matching file:
  editing a `.vue` file brings in `vue.md` and nothing else.
- **Skills** (`/ticket`, `/plan`, `/verify`, `/release`, `/onboard-repo`) for the repeatable
  sequences, and **reviewer subagents** that review the diff in their own context.
- **A per-repo `CLAUDE.md`** holding configuration only: commands, ports, traps and locked
  decisions.
- **Per-repo memory** (`.docs/`): learnings split by domain, plans, a changelog and a
  test-failure ledger.

## Structure

```
.
├── CLAUDE.md                  # entry point: `@AGENTS.md`, auto-loaded by Claude Code
├── AGENTS.md                  # the protocol: tiers, the cycle, two gates, non-negotiables
├── .claude/                   # canonical set, linked into every repo by sync-repo.sh
│   ├── settings.json          #   deny list for .env*/force-push, hook wiring
│   ├── hooks/                 #   guard-git, guard-secrets, guard-migrations, guard-commit, …
│   ├── rules/                 #   shared.md (always) + laravel, vue, python, node-ts, e2e, legacy-php
│   ├── skills/                #   ticket, plan, verify, release, onboard-repo
│   └── agents/                #   security-, dba-, test-reviewer (read-only)
├── .agents/                   # personas a repo CLAUDE.md can @import (architect, security, …)
├── .context/                  # reference, never auto-loaded: open the section you need
│   ├── development_cycle.md   #   the cycle in detail
│   ├── enforcement.md         #   which rule is enforced where
│   ├── LEARNINGS.md           #   lessons promoted from two or more repos
│   └── reference/             #   docker + port registry, coding-standard worked examples
├── .global-docs/              # templates (CLAUDE.md, plan, design, changelog, ledger), bin/, linters/, e2e/
├── .docs/                     # the framework's own learnings and ADRs
├── scripts/
│   ├── sync-repo.sh           # link a repo in src/ to the canonical .claude/, bin/, linters
│   └── check-framework.sh     # audit every repo: missing, overridden, broken links
└── src/                       # application repos, one folder each
    ├── example-site/          # Python · Flask · SQLite · pytest (TaskFlow)
    └── example-api/           # Node · TypeScript · Express · Vitest (the same TaskFlow)
```

> **Two examples, one domain.** `example-site` (Python) and `example-api` (TypeScript)
> describe the **same** task-tracker domain in different stacks, so you can follow along in
> whichever language is closest to your own. They carry the framework layout — `CLAUDE.md`,
> linked `.claude/`, `bin/`, `.docs/` — ready for the application source.

## How context loads

Claude Code reads `CLAUDE.md` from the working directory **and every ancestor**. Start a
session in `src/example-site/` and it picks up that repo's `CLAUDE.md`, plus the root one,
which imports `AGENTS.md`. Nothing else loads unless something triggers it:

| Layer | Holds | Loaded |
| --- | --- | --- |
| `AGENTS.md` | Gates, non-negotiables, conventions | Always |
| Repo `CLAUDE.md` | Commands, exec prefix, schema lineage, ports, traps, locked decisions | Always |
| `.claude/rules/*.md` | Stack detail, scoped by `paths:` | When a matching file is touched |
| Skills | Repeatable sequences | When invoked |
| `.docs/learnings/`, `.docs/TEST_LEDGER.md` | Repo memory | At intake — the matching domain only |
| `.context/` | Cycle detail, enforcement map, reference | Never by itself |

`settings.json`, hooks, rules, skills and subagents do **not** inherit from a parent
directory the way `CLAUDE.md` does. That's why `scripts/sync-repo.sh` gives each repo
**relative** symlinks to the canonical files: one copy to change, no drift, and nothing
tied to one machine's paths.

## The cycle in one table

| Tier | Looks like | Process |
| --- | --- | --- |
| **Trivial** | 1–2 files, obvious cause, no schema, contract, ACL or auth change | Branch → fix → verify → Gate 2 → ship |
| **Standard** | A feature, a multi-cause bug, a new endpoint or table | Plan → **Gate 1** → branch → implement → `/verify` → review → **Gate 2** → ship |
| **Large** | New module, cross-module integration, data migration | Standard, plus a design doc first and a phased plan |

The agent runs the commands itself. You approve at two gates: the plan (Gate 1) and the UAT
hand-back (Gate 2). Full detail is in `AGENTS.md`.

## Quickstart

### Mode A — clone the whole workspace

```bash
git clone <your-fork> taskflow-workspace
cd taskflow-workspace/src/example-site
claude
```

Ask it to start work on an issue (`/ticket 12`) and it follows the cycle. Try something
the hooks forbid, such as a commit on `main` or `git add .`, and watch it get refused.

### Mode B — bring your own repos

1. Clone or fork this workspace. It becomes the **framework root**.
2. Clone each application repo into `src/<repo>/` (the root `.gitignore` keeps them out of the
   framework's own history).
3. Run `scripts/sync-repo.sh <repo>`. It links `.claude/` and `bin/`, merges `settings.json`,
   installs the linters your stack needs, and scaffolds `.docs/`. It writes files but never
   commits them.
4. In the repo, run `/onboard-repo`. It covers the judgement work: writing `CLAUDE.md` from
   `.global-docs/TEMPLATE_AGENT.md` with every command verified, splitting old learnings by
   domain, and removing competing policy files.
5. Run `scripts/check-framework.sh` from the root to confirm nothing is missing or broken.

The links are relative, so a repo has to stay at `<framework-root>/src/<repo>/`. A clone
anywhere else gets dangling links; use `sync-repo.sh <repo> --copy` for that case.

## Customizing

Nothing here is sacred. When a repo needs to differ, prefer these in order (details in
`.claude/rules/README.md`):

1. **Configure** — the repo `CLAUDE.md`, or the hook tunables (`FRAMEWORK_BACKUP_DIR`,
   `FRAMEWORK_FRONTEND_RE`, …).
2. **Select** — `sync-repo.sh` links only the rules a repo's stack needs.
3. **Add** — drop a repo-only rule, hook or skill beside the links.
4. **Override** — replace a link with a real file. `check-framework.sh` flags it, so record
   why under LOCKED DECISIONS.

For a different stack, add a rule under `.claude/rules/` with `paths:` and `applies:`
frontmatter; no script needs editing. For a different branch model, change `AGENTS.md` and
`guard-git.sh` together.

## Testing the framework itself

```bash
bash .claude/hooks/tests/hooks.sh     # hook fixture suite
scripts/check-framework.sh            # audit every repo under src/
```

## Licence

Provided as an educational example. Use it freely.
