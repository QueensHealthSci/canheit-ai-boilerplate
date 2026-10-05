# Changelog — framework root

Keep a Changelog (https://keepachangelog.com), Semantic Versioning.

**Append only.** Add a line under `## [Unreleased]` as part of the work that caused it —
same branch, same pull request (`AGENTS.md` non-negotiable 8). Never read this file whole.

## [Unreleased]

### Added
- Canonical `hooks.json` for Gemini and Antigravity hook execution.
- Dual-engine customization linking in `scripts/sync-repo.sh` (`.agents/` and `GEMINI.md -> CLAUDE.md`).
- Gemini tool call fixtures in `.claude/hooks/tests/hooks.sh`.
- Root `GEMINI.md` entry point symlinked to `AGENTS.md`.

### Changed
- Normalized `.claude/hooks/_lib.sh` to extract tool inputs across Claude and Gemini tools (`run_command`, `view_file`, `replace_file_content`, `write_to_file`, `grep_search`).
- Updated `.global-docs/bin/doctor` and `scripts/check-framework.sh` to recognize `GEMINI.md` alongside `CLAUDE.md`.
- Added affirmative action guidance to non-negotiables in `AGENTS.md`.
- Persona rules not covered elsewhere folded into `.claude/rules/` and the `security-` and `dba-reviewer` subagents.

### Fixed

### Removed
- `.agents/` persona library and the `## IMPORTS` section of `TEMPLATE_AGENT.md` and both examples; stack detail now loads by path from `.claude/rules/`.
