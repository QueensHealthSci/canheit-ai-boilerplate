# Dual-Engine Support: Optimizing Framework for Google Gemini and Antigravity

**Status:** In progress
**Issue:** #3
**Tier:** Large
**Estimate:** 4 hours
**Design doc:** `.docs/design/0003-gemini-optimization.md`

## 1. Goal

Make the multi-repo AI development framework natively bilingual — fully functional with both Claude Code and Google Gemini / Antigravity — ensuring identical protocol gates, mechanical hooks, repeatable skills, and repo-level configuration with zero rule duplication.

## 2. Approach

1. Normalize `.claude/hooks/_lib.sh` to extract tool execution and path payloads from both Claude (`Bash`, `Read`, `Edit`, `Write`, `Grep`) and Gemini (`run_command`, `view_file`, `replace_file_content`, `write_to_file`, `grep_search`), falling back from `$CLAUDE_PROJECT_DIR` to `$GEMINI_PROJECT_DIR` and `$PWD`.
2. Provide a canonical `hooks.json` mapping Gemini tools to the existing guard scripts.
3. Update `scripts/sync-repo.sh` to dual-link `.agents/` (`rules/`, `skills/`, `hooks/`, `hooks.json`) alongside `.claude/`, and link `GEMINI.md -> CLAUDE.md` in child repos.
4. Update `scripts/check-framework.sh` and `.global-docs/bin/doctor` to recognize `GEMINI.md` and verify `.agents/` symlinks.
5. Provide affirmative prompt guidance in `AGENTS.md` and `.global-docs/TEMPLATE_PLAN.md` (e.g., pairing negative constraints with immediate deterministic actions).

## 3. Files

| File | Change |
| :--- | :--- |
| `.claude/hooks/_lib.sh` | Normalize tool names and input arguments across Claude and Gemini; support `$GEMINI_PROJECT_DIR`. |
| `.claude/hooks/tests/hooks.sh` | Add test cases verifying that Gemini tool payloads (`run_command`, `view_file`, etc.) trigger the guards identically. |
| `hooks.json` | Create canonical Gemini / Antigravity hook configuration mapping tools to guard scripts. |
| `scripts/sync-repo.sh` | Add dual-linking for `.agents/rules/`, `.agents/skills/`, `.agents/hooks.json`, and `GEMINI.md -> CLAUDE.md`. |
| `scripts/check-framework.sh` | Update repo discovery to support `GEMINI.md`; audit `.agents/` and `.claude/` link health. |
| `.global-docs/bin/doctor` | Support reading `GEMINI.md` or `CLAUDE.md` and validating protocol reachability. |
| `.global-docs/TEMPLATE_AGENT.md` | Remove "Claude Code only" restriction; clarify that `CLAUDE.md` and `GEMINI.md` are unified. |
| `GEMINI.md` | Create root-level entry point pointing to `AGENTS.md`. |
| `AGENTS.md` | Add affirmative guidance to non-negotiables for improved Gemini instruction following. |
| `.docs/CHANGELOG.md` | Record unreleased changes under `## [Unreleased]`. |

## 4. Blast radius

- **Existing Claude Code workflows:** All `.claude/` paths and payload structures remain fully intact. Claude Code continues to function without change.
- **Existing Repos:** `sync-repo.sh` adds `.agents/` and `GEMINI.md` links; existing `.claude/` links and linter configs are untouched.
- **Line budgets:** `AGENTS.md` must stay $\le$ 150 lines and `TEMPLATE_AGENT.md` $\le$ 100 lines as verified by `check-framework.sh`.

## 5. Security

- [x] Does this touch **authentication, authorization, payments or PHI**? **NO**
- [x] Authorization: Guard scripts continue to block unauthorized/dangerous git commands and environment file reads.
- [x] Validation: Hook payload parser safely handles malformed JSON inputs with Python/jq fallbacks.
- [x] Data isolation: `guard-secrets.sh` prevents `.env*` leaks across both Claude and Gemini file-reading and command-execution tools.

## 6. Steps

### Phase 1: Hook Normalization & Test Suite
1. [ ] Update `.claude/hooks/_lib.sh` to extract tool names and payloads for `run_command`, `view_file`, `replace_file_content`, `write_to_file`, `grep_search`.
2. [ ] Update `.claude/hooks/tests/hooks.sh` with test fixtures for Gemini tool calls. Run and verify all pass.
3. [ ] Create canonical `hooks.json` mapping Gemini tools to the guard scripts.

### Phase 2: Customization Sync & Entry Points
4. [ ] Create root `GEMINI.md` referencing `AGENTS.md`.
5. [ ] Update `scripts/sync-repo.sh` to scaffold `.agents/` (rules, skills, hooks.json) and create `GEMINI.md -> CLAUDE.md` symlink.
6. [ ] Update `.global-docs/TEMPLATE_AGENT.md` to remove tool-exclusive restrictions.
7. [ ] Run `scripts/sync-repo.sh example-site` and `scripts/sync-repo.sh example-api` to test sync on bundled examples.

### Phase 3: Auditing & Health Checks
8. [ ] Update `.global-docs/bin/doctor` to detect `CLAUDE.md` or `GEMINI.md`.
9. [ ] Update `scripts/check-framework.sh` to recognize `GEMINI.md` and verify `.agents/` links. Run and confirm 0 failures.

### Phase 4: Prompt Refinements & Documentation
10. [ ] Refine `AGENTS.md` non-negotiables with affirmative actions while maintaining $\le$ 150 lines budget.
11. [ ] Update `.docs/CHANGELOG.md` under `## [Unreleased]`.

## 7. Verification

- [ ] **Tests:** Run `bash .claude/hooks/tests/hooks.sh` to verify both Claude and Gemini payloads trigger guards (0 failures).
- [ ] **Framework Audit:** Run `bash scripts/check-framework.sh` (0 failures, line budgets respected).
- [ ] **Repo Health:** Run `bin/doctor` in `src/example-site` and `src/example-api`.
- [ ] **How the user exercises it at Gate 2:**
  - Run `bash .claude/hooks/tests/hooks.sh` — displays passing tests for both Claude and Gemini payloads.
  - Run `scripts/sync-repo.sh example-site` — verifies `.agents/` and `GEMINI.md` are linked.
  - Run `scripts/check-framework.sh` — passes with all line budgets met.

## 8. Risks and unknowns

- **Line budget overflow:** `AGENTS.md` is currently at 150/150 lines. Any affirmative prompt additions must be tightly edited or replace redundant wording to strictly respect the 150-line limit.
- **Mac vs. Linux compatibility:** Symlinks and shell scripts must remain portable across BSD and GNU utilities.

## 9. Outcome

<!-- Filled in at Step 5, before the hand-back. -->

- **Actual effort:**
- **Where reality differed from this plan:**
- **Deferred:**
