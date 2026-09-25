# Framework hooks

Deterministic enforcement of the `[hook]`-marked rules in `AGENTS.md`. A hook that exits 2
blocks the tool call and returns its reason to the model; the protocol says the hook is right.

| Hook | Event | Enforces |
| --- | --- | --- |
| `guard-git.sh` | PreToolUse · Bash | NN 1 no commit/push on develop or main · NN 3 stage by path · NN 5 no force push, `reset --hard`, `clean -f`, whole-tree discard, recursive delete outside the repo |
| `guard-migrations.sh` | PreToolUse · Bash | NN 2 dump within 10 min before `migrate:fresh/refresh/reset/rollback`, `db:wipe`, Prisma reset, `DROP`/`TRUNCATE` |
| `guard-secrets.sh` | PreToolUse · Read/Edit/Write/Grep + Bash | NN 4 the agent never reads, prints or edits `.env*` — including `.env.example`. It may stage and commit a human's change (plain `git add <path>`; not `-p`/`-i`/`-e`, which show hunks). Because stage files are committed by design, it also refuses `git show`, `git log -p` and content-producing `git diff` — including `--cached` — when an env file is in the result (`--stat`/`--name-only` stay allowed) |
| `guard-commit.sh` | PreToolUse · Bash | Step 6 Conventional Commit subject, issue number never in it · NN 8 advisory when pushing code with no CHANGELOG entry. Local, so it holds with or without CI |
| `check-framework-root.sh` | SessionStart | advisory: protocol not loaded (clone location), stale `Verified:`, `TEMPORARY` block |
| `lint-on-edit.sh` | PostToolUse · Edit/Write | advisory: pint/eslint findings on the edited file; frontend-build reminder |

`_lib.sh` is shared and reads the payload (jq, else python3). Scripts are `chmod +x`.

## Installing in a repo

Hooks **do not inherit** from a parent directory — unlike `CLAUDE.md`, `.claude/` is read
from the project root only. So each repo needs its own `.claude/hooks/`:

```bash
scripts/sync-repo.sh <repo>
```

That symlinks each hook individually, so an edit here reaches every repo at once, and a repo
can still add a `guard-something-local.sh` of its own beside them — a re-sync leaves anything
with no canonical counterpart alone. `settings.json` is merged rather than linked, because
`enabledPlugins` differs per repo. `--copy` gives real files instead, for a checkout outside
the workspace.

The four ways a repo can differ — configure, select, add, override — are in
`.claude/rules/README.md`.

## What is scanned

The guards match against the *text* of a Bash command, and differ deliberately in how much
of it they look at:

- `guard-git.sh` drops heredoc bodies and the contents of quoted strings first, so a commit
  message that says "never `git add .`" is not treated as one. The rm rule keeps quotes
  (a quoted path is a real argument) but still drops heredoc bodies.
- `guard-migrations.sh` drops heredoc bodies and keeps quotes, so `mysql -e "DROP TABLE x"`
  is caught while a commit message naming `migrate:fresh` is not.
- `guard-secrets.sh` strips nothing for its verb-plus-path rule. A heredoc fed to `python3`
  or `bash` can read a file, so any Bash command whose text pairs a reading verb with an
  env-file path is blocked — including a commit message or `echo` that merely mentions one.
  That false positive is accepted; the test suite was written with the Write tool for
  exactly this reason. Word messages around it ("staging an environment file") rather than
  weakening the guard. Its history rule (`show`, `log -p`, content `diff`) does drop heredoc
  bodies, since a bare `git show` only runs at the top level of a shell.

The one gap this leaves open — a real forbidden command inside a heredoc executed by
`bash <<EOF` — is exotic, and the commit-time check for staged env files still holds.
While these hooks were being written they blocked the author's own calls three times,
twice on text that merely mentioned the operations; the Edit and Write tools are the
right way to change a file whose contents name a guarded command.

## Testing a hook

Feed it the JSON Claude Code would send:

```bash
echo '{"tool_name":"Bash","tool_input":{"command":"git add ."}}' | CLAUDE_PROJECT_DIR=$PWD .claude/hooks/guard-git.sh; echo "exit $?"
```

Exit 0 = allowed, 2 = blocked (reason on stderr). `tests/hooks.sh` in this directory runs the
whole fixture set.

## Tunables (environment)

`FRAMEWORK_BACKUP_DIR`, `FRAMEWORK_BACKUP_WINDOW_MIN` (10), `FRAMEWORK_VERIFIED_MAX_DAYS` (90),
`FRAMEWORK_FRONTEND_RE` (`/resources/(js|css|sass|scss)/`).
