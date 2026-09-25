---
name: plan
description: Write the plan for Standard or Large work to .docs/plans/ and take it through Gate 1. Use after /ticket, or whenever the user asks for a plan.
---

# Write the plan

Covers `AGENTS.md` Step 1's planning half and Gate 1. The approved plan is the contract;
changing its shape later means coming back through this gate.

## Before writing

Explore first. Find every file the change touches and read enough of each to know the
approach works. A plan written without reading the code is a guess dressed as a plan.

**Large** work: write the design doc first — `.docs/design/<issue>-<slug>.md`, ADR shape
(Context, Decision, Consequences, Status). Decide the approach there; plan the execution here.

## The plan

Copy `../../.global-docs/TEMPLATE_PLAN.md` to `.docs/plans/<issue>-<slug>.md`. Whatever
else the template asks, the protocol requires these:

- **Files** — every file created or modified, and what changes in each. This is what a
  reviewer actually checks the diff against.
- **Blast radius** — what this breaks that the diff will not show: shared tables, other repos
  on the same database, scheduled jobs, integrations, deploy scripts. The repo `CLAUDE.md` has
  a section for this; start there.
- **Security** — does it touch authentication, authorization, payments or PHI? If yes,
  coverage of the changed code is 100% and the plan says how.
- **Verification** — which tests, happy path and error path, and how you will know it works
  beyond "tests pass". Name the scenario the user will exercise at Gate 2.
- **Risks and unknowns** — say what you are unsure of. An unstated assumption in a plan
  becomes a defect in the code.

**Large**: split into phases that each pass `/verify` on their own.

## Plan mode

**Write the file to disk before leaving plan mode.** A plan that exists only in the approval
dialog is gone when the session ends. This is the single most common way planning work is
lost, and it is non-negotiable.

## Gate 1

Present the plan and stop. Ask explicitly whether it is approved; "looks good" answering a
different question is not approval. If the user changes the approach, update the file before
starting — the plan on disk must match what was agreed, or the next session inherits a lie.
