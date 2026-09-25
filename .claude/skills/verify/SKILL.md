---
name: verify
description: The verification pass before hand-back - feature tests, full suite, lint and types, measured coverage, diff sweep, pre-existing-failure triage into the ledger, reviewer subagent, then the Gate 2 hand-back. Use after implementing, before asking the user to test.
---

# Verify

Covers `AGENTS.md` Step 4 and Step 5, ending at Gate 2. Run before every hand-back, Trivial
included. Substitute `{EXEC}` from the repo `CLAUDE.md`. This skill adds no rule the protocol
does not state; without it, work Steps 4–5 by hand.

## 1. In order, every time

1. **Tests for what you changed.** Fix and re-run until green.
2. **The full suite** — `bin/check` where the repo has it, otherwise the repo `CLAUDE.md`
   COMMANDS entry. `bin/check` detects the runner, the container prefix and the coverage
   driver, so a missing driver reports UNMEASURABLE rather than a number (non-negotiable 6).
3. **Lint and type checks**, with the repo's commands.
3b. **End-to-end tests**, if the repo has a `playwright.config.*`. They run after the unit and
   feature suites pass, never instead of them. No config means say so — do not report a pass
   for a suite that does not exist.
4. **Coverage**, measured. Protocol non-negotiable 6: 80%, and 100% for authentication,
   authorization, payments and PHI. If the repo has no driver, the command fails or reports
   zero — say **"coverage is unmeasurable in this repo"** and name what is missing. Never
   estimate, never report a number the tooling did not produce.
5. **Sweep the changed files** for debug statements (patterns in the repo `CLAUDE.md`),
   commented-out code, hardcoded values that belong in config, and environment reads in
   application code.

**A failing test means the code is wrong, not the test.** Change an existing test only when
the approved plan names the behaviour change.

## 2. Failures you did not cause

Confirm each by checking out `develop` and running that test there. Then record it in
`.docs/TEST_LEDGER.md`:

| Test | First seen | Fails on develop? | Error (short) | Decision | Deferrals | Owner | Issue | Resolved |

with a decision the user chooses — **Fix now** (separate `bug-fix/` branch, this work
pauses), **Fix later** (a branch opens as soon as this merges) or **Skip** (justified, with an
owner and an issue). **Twice deferred means fixed before a third.** Say so instead of logging
it again; one repo logged the same two tests on six dates across five months.

Read the ledger; never copy a failure count from an older plan.

## 3. Reviewer subagents

Run a reviewer over the diff in its own context, read-only. The context that wrote the code
is the worst placed to find its errors. Tell it what the change is meant to do, which files,
and the blast radius from the plan.

| Subagent | Run it when |
| --- | --- |
| `test-reviewer` | always — it checks whether the tests would have caught this bug, and whether any test was weakened to pass |
| `security-reviewer` | the change touches authentication, authorization, uploads, payments or PHI |
| `dba-reviewer` | the change touches migrations, schema or query code |

They are in `.claude/agents/` and, like everything else there, do not inherit — a repo
without them gets no review pass, so say so rather than skipping the step silently.

Fix what they find. Where you disagree, record why in the plan, not only in chat.

## 4. Documentation, in this branch

One line per change under `## [Unreleased]` in `.docs/CHANGELOG.md` — append; never read the
file whole. Mark the plan's steps done and note where reality differed. A LEARNINGS entry only
if it will recur.

## 5. Gate 2 — the hand-back

Stop, and give the user, in this shape:

- **What changed and why**, two or three sentences; files touched with `+/-` counts
- **Database changes**, and whether each is reversible
- **Tests**: how many, the coverage figure or "unmeasurable", and what is *not* covered
- **How to exercise it**: the real URL, route or command; test data or an account; one
  scenario per acceptance criterion with what they should see
- **Deferred or unsure**: anything in the ledger, anything you are not confident of

Say plainly what did not run. Then ask whether it meets requirements, and wait for an explicit
yes. Six defects on one ticket were found at this step after "done" had been said.
