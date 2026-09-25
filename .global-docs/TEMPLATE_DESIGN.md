<!-- Save as .docs/design/<issue>-<slug>.md. ADR shape: context, decision, consequences.
     Required by AGENTS.md Step 1 for Large work — a new module, endpoint or table, or a
     change to request flow, ACL or authentication. Write it BEFORE the plan: this decides
     the approach, the plan decides the execution. -->

# ADR <NNNN> — <the decision, as a statement not a question>

**Status:** Proposed <!-- Proposed | Accepted | Superseded by #NN | Withdrawn -->
**Date:** YYYY-MM-DD
**Issue:** #NN
**Decides:** <the question this closes>

## Context

What is true today that makes this a decision rather than a default. Constraints that
matter: the schema lineage, an existing integration, a deadline, something another repo
depends on. Name the forces, not the answer.

A reader in six months needs enough here to judge whether the decision still holds. That is
the entire point of the document.

## Decision

What was decided, in the present tense and as few words as possible. "Imports match on the
OUAC identifier, not the email address."

## Consequences

What follows — the good and the bad. What becomes easy, what becomes harder, what is now
impossible without revisiting this. Anything a future reader would otherwise raise as an
objection should be answered here, including the objection you do not have a good answer to.

## Alternatives considered

One short paragraph each: what it was, and the specific reason it lost. An alternatives
section that only lists straw men is worse than none — it reads as justification rather than
reasoning, and the next person re-proposes the real alternative anyway.

## Open follow-ups

- [ ] Anything this decision defers, with who owns it.
