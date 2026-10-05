# ADR 0003 — Dual-Engine AI Development: Extending Framework to Gemini and Antigravity

**Status:** Proposed
**Date:** 2026-10-05
**Supersedes:** nothing

## Context

The framework was initially built around Claude Code conventions:
1. `CLAUDE.md` as the root entry point, importing `AGENTS.md` via `@AGENTS.md`.
2. Workspace customizations placed exclusively in `.claude/` (`rules/`, `skills/`, `agents/`, `settings.json`).
3. Hooks parsing only Claude tool names (`Bash`, `Read`, `Edit`, `Write`, `Grep`) and expecting `$CLAUDE_PROJECT_DIR`.
4. Prompting styles tailored for Claude's strict negative-constraint adherence, rather than Gemini's affirmative guidance.

When using Google Gemini (via Gemini CLI, Antigravity IDE, or Gemini Code Assist), the framework fails to load repo configuration, skills, and path-scoped rules:
- Gemini searches for `AGENTS.md` or `GEMINI.md` at workspace roots, missing child repo `CLAUDE.md` files.
- Gemini discovers skills and rules under `.agents/` or `~/.gemini/config/`, completely ignoring `.claude/`.
- Hook execution payloads from Gemini tools (`run_command`, `view_file`, `replace_file_content`, `write_to_file`, `grep_search`) are unparsed by `.claude/hooks/_lib.sh`, causing mechanical guards to fail or bypass.

## Decision

**Make the framework natively bilingual (Claude and Gemini) with zero rule duplication:**

1. **Normalized Hook Engine:**
   - Extend `.claude/hooks/_lib.sh` to extract tool arguments across both Claude (`Bash`, `Read`, `Edit`, `Write`, `Grep`) and Gemini (`run_command`, `view_file`, `replace_file_content`, `write_to_file`, `grep_search`).
   - Fall back from `$CLAUDE_PROJECT_DIR` to `$GEMINI_PROJECT_DIR` and `$PWD`.
   - Provide a canonical `hooks.json` mapping Gemini tools to the same guard scripts.

2. **Customization Dual-Linking (`.claude/` and `.agents/`):**
   - Update `scripts/sync-repo.sh` to symlink canonical rules and skills into both `.claude/` and `.agents/`.
   - Since both engines share the identical `SKILL.md` frontmatter format (`name:`, `description:`), no duplicate skill files are needed.

3. **Entry Points & Repo Discovery:**
   - Maintain `AGENTS.md` as the universal root protocol.
   - At framework root, add a `GEMINI.md` referencing or symlinking `AGENTS.md`.
   - In each repo, `scripts/sync-repo.sh` maintains a relative symlink: `GEMINI.md -> CLAUDE.md`.
   - Update `.global-docs/TEMPLATE_AGENT.md` to remove the "Claude Code only" restriction.

4. **Tooling & Auditing:**
   - Update `.global-docs/bin/doctor` to detect either `CLAUDE.md` or `GEMINI.md`.
   - Update `scripts/check-framework.sh` to recognize `GEMINI.md` and audit both `.claude/` and `.agents/` symlinks.

5. **Affirmative Guidance:**
   - Refine `AGENTS.md` non-negotiables so negative constraints include explicit affirmative actions (e.g., branching immediately when on develop/main).

## Consequences

- **Positive:** Developers using either Claude or Gemini experience identical workflow gates, mechanical guardrails, and repeatable skills.
- **Positive:** Zero content drift — both engines read the same underlying markdown rules and shell hooks via symlinks.
- **Neutral:** Child repositories carry additional symlinks (`.agents/` and `GEMINI.md`), which are lightweight and tracked in git.

## Alternatives Considered

- **Separate Gemini Branch or Fork:** Rejected. Maintaining two parallel codebases causes rapid drift and doubles maintenance overhead.
- **Monolithic Single File:** Rejected. Monolithic instructions defeat path-scoped context efficiency.
