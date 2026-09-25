<!-- Save as .docs/plans/<issue>-<slug>.md — one plan per GitHub issue.
     Required for Standard and Large work (AGENTS.md "Pick the tier"); Trivial work has no
     written plan. Stack-neutral: the file and directory names below are illustrative.
     For Large work, write .docs/design/<issue>-<slug>.md first. -->

# <Issue title>

**Status:** Draft <!-- Draft | Approved | In progress | Complete | Superseded by #NN | Abandoned -->
**Issue:** #NN
**Tier:** Standard <!-- Standard | Large -->
**Estimate:** <hours or days — a number, so the next estimate can be calibrated against it>
**Design doc:** <.docs/design/NN-slug.md, or "none — Standard tier">

## 1. Goal

One sentence on what this delivers. If it takes two, the issue may be two issues.

## 2. Approach

How, in a short paragraph. The alternative you rejected and why, if the choice was close.

## 3. Files

Every file created or modified, and what changes in each. **This is the section reviewers
check the diff against**, so vagueness here costs more than anywhere else.

| File | Change |
| --- | --- |
| | |

## 4. Blast radius

What this breaks that the diff will not show. Shared tables; other repos reading the same
database; scheduled jobs; deploy scripts; integrations; cached config. The repo's `CLAUDE.md`
has a BLAST RADIUS section — start there.

"Nothing" is a valid answer. An empty section is not.

## 5. Security

- [ ] Does this touch **authentication, authorization, payments or PHI**? **[YES/NO]**
      *If YES: 100% coverage of the changed code, and say here how that is achieved.*
- [ ] Authorization: which policy, guard or middleware enforces access?
- [ ] Validation: what is validated, and where?
- [ ] Can a user reach another user's data by changing an identifier in the request?

## 6. Steps

Numbered, each independently verifiable. For Large work, group them into phases that each
pass `/verify` on their own.

1. [ ]
2. [ ]

## 7. Verification

- [ ] **Tests:** which, covering what — happy path and error path.
- [ ] **Coverage:** measured, against the figures in Security above.
- [ ] **How the user exercises it at Gate 2:** the URL, route or command, the test data, and
      what they should see. One scenario per acceptance criterion.

## 8. Risks and unknowns

What you are unsure of. An unstated assumption in a plan becomes a defect in the code.

## 9. Outcome

<!-- Filled in at Step 5, before the hand-back. -->

- **Actual effort:**
- **Where reality differed from this plan:**
- **Deferred:** <link to TEST_LEDGER.md rows or follow-up issues — never copy their contents>
