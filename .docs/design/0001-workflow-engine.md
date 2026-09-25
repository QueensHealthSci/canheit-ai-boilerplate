# ADR 0001 — One workflow engine: the protocol owns policy, `superpowers` supplies techniques

**Status:** Accepted
**Date:** 2026-09-21
**Supersedes:** nothing

## Context

Up to three process authorities can load into a single session, and they do not agree:

| Authority | Shape | Where it says plans live |
| --- | --- | --- |
| `AGENTS.md` (this framework) | 7 steps, two gates | `.docs/plans/` |
| an older `.context/development_cycle.md` | 9 steps, a stop after each | `.docs/project-plans/PROJECT_PLAN.md` |
| `superpowers` plugin | injects a skill at session start demanding its own brainstorming, plan-writing and branch-finishing routines | `docs/superpowers/plans/` |
| a repo's own `CLAUDE.md` | a locally invented cycle with no coverage requirement and no stop gates | — |

The split shows up on disk. Repos that run their real workflow through the plugin write
every plan to `docs/superpowers/` and none to `.docs/plans/`. A repo that turns the plugin
off, with no recorded reason, ends up the only one whose plans are where the protocol says
they should be — while still carrying the plugin's build residue from before.

A framework that leaves this unresolved produces two plan directories per repo and lets
a session pick whichever authority it saw last.

## Decision

**The protocol is the only workflow engine.** `AGENTS.md` owns the cycle, the gates, the
branch and plan locations, and the definition of done.

**`superpowers` stays enabled as a technique layer.** Its techniques may be used freely.
Its *process* is not authoritative: where its guidance and `AGENTS.md` disagree about the
number of gates, where a plan lives, or how a branch is finished, `AGENTS.md` wins.

Recorded in `AGENTS.md` under "Workflow engine".

## Consequences

- No settings file changes. Nothing is disabled; nothing that works stops working.
- `.docs/plans/<issue>-<slug>.md` is the one plan path. Plans already under
  `docs/superpowers/plans/` are **not** migrated by this decision; until they are, those
  repos have plan history in two places. New plans go to `.docs/plans/`.
- A repo-local cycle in a `CLAUDE.md` is deleted; any genuinely useful inventions in it
  (plan saved before leaving plan mode, design doc required for new modules, endpoints,
  tables and ACL changes) are kept and promoted to `AGENTS.md`.
- A repo that has disabled the plugin is **left disabled**: find out why before turning it
  back on. Its `.superpowers/sdd` artefacts are build residue, not project memory, and
  should be gitignored or deleted separately.
- The decision is cheap to reverse. If the technique layer turns out to fight the
  protocol in practice, disabling the plugin in each committed settings file is a
  ten-minute change and no content is lost.

## Alternatives considered

**Disable `superpowers` everywhere.** Cleanest single authority, and the option that
best matches "one document owns the cycle". Rejected because some repos' real workflow
runs through it, so disabling it removes a working process and replaces it with one those
repos have never used. The conflict being solved is about *policy*, and policy can be
reclaimed without discarding the techniques.

**Adopt `superpowers` as the engine and retire the protocol's cycle.** Rejected: the
plugin has no opinion on the things a team actually needs enforced — the database dump
before a destructive migration, the branch protection rules, the coverage figures, the
pre-existing-failure protocol, PHI handling. Those are house rules and need a house
document.

**Leave it undecided and gather more data.** Rejected: everything that touches the plan
location, the gates or the skills depends on this, so deferring blocks the rest.

## Open follow-ups

- Record why any repo disabled the plugin, here.
- Decide whether `.superpowers/sdd/` should be gitignored in every repo.
- Migrate or archive plans under `docs/superpowers/plans/`.
