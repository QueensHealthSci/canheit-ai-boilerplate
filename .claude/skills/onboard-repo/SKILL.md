---
name: onboard-repo
description: Bring an application repo under the framework - check the clone location, remove the obsolete protocol import, fix the gitignore, delete competing policy, write the repo CLAUDE.md from the template with every command verified, and install the .claude/ contents that never inherit. Use when adopting the framework in a repo for the first time.
---

# Onboard a repo

**`scripts/sync-repo.sh <repo>` has already run.** It is what installed this skill — skills
are read only from the repo's own `.claude/`, so there is no `/onboard-repo` to invoke until
it has. Sync linked the hooks, rules, skills and subagents, merged `settings.json`, installed
`bin/` and the stack's linters, and scaffolded `.docs/`. This skill is everything that takes
judgement afterwards.

Work in the target repo, on whichever branch the change should land. Non-negotiable 1 still
refuses the commit on `develop` or `main`, and nothing is pushed without the user's say-so.
Before anything, run `scripts/check-framework.sh` from the framework root and read what it
reports for this repo.

## 1. Clone location

The protocol loads by ancestor walk-up from the framework root's `CLAUDE.md`; a repo cloned
anywhere else gets nothing. Confirm the repo sits two levels below that root, at
`<framework-root>/src/<repo>/`. If not, stop and say so — every
step below assumes it.

## 2. Remove the protocol import

Delete any `@../../AGENT.md`, `Inherits: ../../AGENT.md` or `Global Protocol: ../../AGENT.md`
line from `CLAUDE.md`. They raise an approval dialog every session and resolve to nothing
outside the framework workspace. Keep `@../../.agents/*.md` persona imports for now.

Verify with `/memory`: root and repo `CLAUDE.md` both listed, no failed imports.

## 3. Gitignore

```gitignore
.DS_Store
**/.DS_Store
.env
.env.local
.env.*.local
.env.bak*
```

That covers the local working file, local overrides and backups — nothing else.

**The committed stage environment files stay exactly as they are.** They are how credentials
reach the server: the deploy copies the one for the target stage into the release. Do not
untrack them, do not add patterns that would ignore them, do not audit them, and do not open
them — non-negotiable 4 applies to you like any other session.

Note them under BLAST RADIUS in the repo `CLAUDE.md`, because a change to one ships on the
next deploy. That is the only thing to do with them.

## 4. Delete competing policy

Anything in `CLAUDE.md` defining its own workflow, gates, step numbering or coverage figures
goes; keep the configuration. Blocks claiming to override the protocol — `TEMPORARY` or not —
are void by `AGENTS.md`. Delete them and say so.

## 5. Write the repo CLAUDE.md

From `.global-docs/TEMPLATE_AGENT.md`. Under 100 lines. Configuration only.

**Run every command before you write it down.** A documented test command that did not exist
went unnoticed for six months here. Set `Verified:` to today only for commands you actually
ran; leave the rest out rather than guess. Declare the schema lineage and the test database
engine — the protocol requires both.

Architecture narrative goes to `.docs/ARCHITECTURE.md`. Fill TRAPS and LOCKED DECISIONS from
the repo's learnings: anything that has bitten twice belongs where it loads every session.

## 6. Migrate `.context/`, if the repo has one

Some repos keep their project artefacts there, changelogs included. `git mv` the tree to `.docs/` so the history follows, and point the repo
`CLAUDE.md` at the new paths. At the framework root `.context/` means *framework rules*, so
the name cannot mean both things (`.global-docs/DOCS_LAYOUT.md`).

`sync-repo.sh` refuses to scaffold `.docs/` while `.context/` is present, because two homes
for the same thing is worse than one in the wrong place — `/release` would read a new empty
changelog while the real one sat in `.context/docs/`. So the sync that installed this skill
skipped that part and said so. **Re-run `scripts/sync-repo.sh <repo>` once the tree has
moved** to pick up `.docs/learnings/README.md`, the changelog and the ledger.

## 7. Split the learnings by domain

Sync scaffolded `.docs/learnings/README.md` and nothing else — which entry belongs in which
domain is a judgement call, and the content is the repo's.

**Read `.docs/LEARNINGS.md` and move every entry** into
`.docs/learnings/<domain>_learnings.md`: `backend`, `database`, `docker`, `frontend`,
`process`, `security`. Sort by what the entry is *about*, not by which file touched it — a
migration that deadlocked under load is `database`, not `process`. **Create a domain file
only when it gets its first entry**; six empty files is a known failure.

**Then delete `.docs/LEARNINGS.md`.** The repo layout has no such file — not even as a
pointer. A file that exists gets read, and leaving one behind means two places to look and
two places to fall out of date. Say in your report how many entries went to each domain, so
the count can be checked against the original.

While moving, convert each entry to the standard format and **add `Applies to:`**. Without it
a lesson cannot be promoted to `../../.context/LEARNINGS.md` when it recurs in a second repo,
which is the whole point of the field. Rewrite `Issue:`/`Resolution:` pairs as
`What happened:`/`Rule:`.

Do not reflow prose you are not otherwise touching, but do break any single line running to
thousands of characters — a 490-line file with 2,900-character lines costs ~96,000
tokens. Width, not line count, is what makes a learnings file expensive.

## 8. Verify

```
scripts/check-framework.sh
```

The repo should reach `linked to canonical`, with its linters and changelog reported present.
Then `bin/doctor` for what the new `CLAUDE.md` gets wrong, `bin/check` to confirm the runner
resolves, and one guarded command — ask for a commit on `develop` — to confirm the hooks fire.

## 9. Report

What changed; what you left tracked and why; which commands you could not verify.
