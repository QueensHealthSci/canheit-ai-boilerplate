# src/

Each subdirectory here is an application repository. In a real setup each is its own git
clone, ignored by the framework repo; the two examples are kept in-tree so the layout is
easy to see.

A repo here needs no import to get the protocol: Claude Code walks up from the repo to the
framework root's `CLAUDE.md`, which loads `../AGENTS.md`. What does **not** walk up —
settings, hooks, rules, skills, subagents — `../scripts/sync-repo.sh` links in as relative
symlinks.

| Project | Stack | Notes |
|---------|-------|-------|
| `example-site/` | Python · Flask · SQLite · pytest | A minimal task tracker demonstrating the conventions. |
| `example-api/` | Node · TypeScript · Express · Vitest | The same task tracker in a different stack — compare the two side by side. |

## Adding a project

1. Clone it here: `git clone <url> src/<repo>`. It must sit exactly at `src/<repo>/`, or the
   relative links will not resolve.
2. From the framework root: `scripts/sync-repo.sh <repo>`.
3. In the repo, run `/onboard-repo`. It writes `CLAUDE.md` from
   `../.global-docs/TEMPLATE_AGENT.md`, with every command verified, and handles the rest of
   the adoption.
4. From the framework root: `scripts/check-framework.sh`.
5. Commit the result on a branch in the repo — never on `develop` or `main`.
