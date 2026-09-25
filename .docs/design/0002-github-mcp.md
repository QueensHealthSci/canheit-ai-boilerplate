# ADR 0002 — GitHub MCP server for issue and pull-request handling

**Status:** Proposed — needs a token and one person to try it
**Date:** 2026-09-21
**Issue:** —

## Context

The cycle hands the user four manual round-trips per task: create the issue, open the pull
request, merge it, close the issue. The agent can do none of them, so every task pauses twice
on work that is pure transcription — it already knows the issue number, the branch name, the
summary and the changelog line.

`gh` already appears in commented-out `FUTURE:` blocks in `development_cycle.md`, so the idea
is not new. It is the highest-value automation still on the table, and comes last only
because it depends on the cycle and the skills being settled. They now are.

This is *not* a pipeline. It is an MCP server the agent talks to, with the user's own
credentials and permissions.

## Decision

Adopt GitHub's MCP server for **reading issues and opening pull requests**. Merging stays
manual.

Scope, deliberately narrow:

| Allowed | Not allowed |
| --- | --- |
| Read an issue and its acceptance criteria | Merging a pull request |
| Create an issue from a described task | Closing an issue |
| Open a pull request with title and description | Approving anything |
| Read pull-request comments | Changing repository settings, protections or collaborators |

## Consequences

- `/ticket` reads the issue instead of asking the user to paste it.
- `/release` opens the pull request instead of printing the text to copy.
- Gate 2 is unaffected: the human still tests and still merges. Removing transcription does
  not remove a gate, and the two gates are the point of the protocol.
- A GitHub token is required. **It is a credential**, so it belongs wherever the team keeps
  those, never in a committed file — `.env*` is already off-limits to the agent
  (non-negotiable 4), and this is no different. Prefer a fine-grained token limited to the
  repositories and to issues and pull requests.
- Per-user, not per-repo: the server is configured in the user's own Claude Code settings, so
  each person's actions run as themselves. That is the right audit trail.

## Setup

Not committed here, because it carries a token. Each person adds GitHub's MCP server to their
own Claude Code settings, following GitHub's current instructions for the remote or local
server, and supplies a token with the same repository access they already have. Restrict the
server's enabled toolsets to issues and pull requests where it allows that.

If the server is unavailable or unwanted, `gh` behind the existing Bash permissions is the
fallback and needs no new machinery.

## Alternatives considered

**`gh` CLI through Bash.** No new server, no token handling beyond what `gh auth` already
does, and it works today. Rejected as the primary route only because every call needs a
permission prompt or a broad `Bash(gh *)` allow rule, which is a wider grant than the read
plus open-PR scope above. Kept as the fallback.

**Do nothing.** Four round-trips per task is a real cost, but one a team can absorb. If the
token turns out to be awkward to issue, this stays proposed.

## Open follow-ups

- [ ] Confirm which GitHub MCP server (remote or local) your organisation permits; if neither, decide on `gh`.
- [ ] One person tries it on one ticket end to end before it is recommended.
- [ ] Decide whether the agent may create issues, or only read them.
