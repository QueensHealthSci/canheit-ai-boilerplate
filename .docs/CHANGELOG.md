# Changelog — framework root

Keep a Changelog (https://keepachangelog.com), Semantic Versioning.

**Append only.** Add a line under `## [Unreleased]` as part of the work that caused it —
same branch, same pull request (`AGENTS.md` non-negotiable 8). Never read this file whole.

## [Unreleased]

### Added

### Changed
- Persona rules not covered elsewhere folded into `.claude/rules/` and the `security-` and `dba-reviewer` subagents.

### Fixed

### Removed
- `.agents/` persona library and the `## IMPORTS` section of `TEMPLATE_AGENT.md` and both examples; stack detail now loads by path from `.claude/rules/`.
