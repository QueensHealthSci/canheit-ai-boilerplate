---
name: ticket
description: Start work on a GitHub issue - confirm the issue, orient in the repo, run the pre-flight checks, pick the work tier and hand off to /plan. Use at the start of a session when the user gives an issue number or describes new work.
---

# Start a ticket

Covers `AGENTS.md` Step 1 up to the plan. Replaces the hand-pasted session kickoff. This skill
adds no rule the protocol does not state; it makes the order repeatable.

## 1. The issue

Every task has a GitHub issue. If the user gave a number, read it and capture the acceptance
criteria and anything marked out of scope. If they described work with no issue, ask them to
create one and give you the number — never invent one, and do not pass Gate 1 without it.

A **hotfix** (critical production bug) still branches from `develop` and merges back to it,
like everything else; the `hotfix/` prefix marks it for fast-track review and a prompt release.
Ask whether this is one so the pace is right.

## 2. Orient

In this order, stopping when you have enough:

1. The repo `CLAUDE.md` — commands, traps, blast radius, locked decisions. Check its
   `Verified:` date; if it is months old, treat the commands as unconfirmed and say so.
2. `.docs/learnings/<domain>_learnings.md` — **only the domain matching this work**, never the
   directory. `.docs/learnings/README.md` says which domain covers what.
3. `.docs/TEST_LEDGER.md` if it exists — know which failures are already known before you run
   the suite, or you will chase someone else's bug.
4. `.docs/plans/` — an existing plan for this area? One marked superseded means the question
   was settled; do not reopen it.

## 3. Pre-flight

The tree first: on `develop`, current, clean. Uncommitted work you did not write is a
stop-and-ask, never a stash.

Then the environment, using the repo's commands — containers up, database reachable,
migrations current, dependencies installed, and **the suite passes on `develop` before you
touch anything**. Check the coverage driver runs; if it does not, note now that coverage will
be reported as unmeasurable, so it is not a surprise at Gate 2.

## 4. Tier

Per `AGENTS.md`: **Trivial** (1–2 files, obvious cause, no schema, contract, ACL or auth
change) · **Standard** · **Large** (new module, cross-module integration, data migration, or
reversing a decided question). Unsure means the higher one.

## 5. Report and hand off

One short block: the issue and its acceptance criteria; the tier and why; anything in
LEARNINGS or the ledger that bears on it; the pre-flight result; any question you need
answered before planning.

Standard or Large: run `/plan`. Trivial: branch and go.
