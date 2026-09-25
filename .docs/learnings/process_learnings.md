# Process learnings — framework root

Workflow, testing, review, release — and the shell tooling the framework is written in.
Newest first. Format and promotion rule: `README.md` in this directory.

## 2026-09-22 — Archive the commit, never a tree under `.claude/`

**Context:** reverting a documentation change and keeping the corrected files somewhere so
they could be reviewed and reapplied rather than lost.

**What happened:** copying them into `.docs/archive/<date>/` at their original paths put a
`.claude/skills/verify/SKILL.md` on disk under the archive. It was discovered and registered
as a live, path-scoped `verify` skill the moment it was written — an archived copy of
framework content became active tooling. The same applies to a backup, an example directory
or a `.bak` beside the original.

**Rule:** never keep a second copy of `.claude/` content — skills, agents, rules, hooks —
anywhere in the working tree, whatever the directory is called. Git is the archive: record
the commit hash and what it changed. `git show <sha>` is the diff, `git cherry-pick <sha>`
restores it. A redirected `git show` is refused by `guard-secrets.sh`, which is another
reason not to keep a patch copy either.

**Applies to:** all repos.

## 2026-09-22 — Never test a pipeline's exit status when the right-hand side short-circuits

**Context:** deciding whether a rule applies to a repo, with
`git ls-files | grep -v … | grep -qE "$pattern"` under `set -uo pipefail`.

**What happened:** the same dry run gave different answers on different invocations. `grep -q`
exits the moment it matches and closes the pipe; upstream `git` then dies of SIGPIPE and exits
141. Under `pipefail` the pipeline's status is the rightmost **non-zero** one, so a successful
match reported failure — but only when it won the race. A pattern matching an early line lost
almost always; one matching a late line (`*.vue`) usually survived. It read as
non-determinism, which sent me looking in entirely the wrong place.

**Rule:** with `pipefail` on, never branch on the status of a pipeline whose last stage exits
early — `grep -q`, `head -1`, `find -quit`. Capture the text and test that instead:
`[ -n "$(producer | grep -m1 -E "$re")" ]`. The same applies to `… | head -1` guards.

**Applies to:** all repos — `bin/check`, the hooks and every shared script set `pipefail`.

## 2026-09-22 — Derive a list from its source; never restate it in a second place

**Context:** three separate bugs in one session, all the same shape.

**What happened:** `sync-repo.sh` decided which rules to install from a hand-written ladder;
`check-framework.sh` excused a hand-written list of rule names from its missing-file count;
the dirty-tree guard restated the paths the script writes. Every one of the three had drifted
from reality. The audit excused files that had genuinely failed to install, and the guard
missed `.gitignore` and the collapsed `?? .docs/`, so every UI repo refused its second sync.

**Rule:** when two pieces of code need the same list, one of them owns it and the other asks.
Prefer letting the *thing itself* declare its own answer — a rule's `applies:` frontmatter
beats any table of rule names — and when that is not possible, put the list in one shared
helper that both callers source. A second copy is not a shortcut; it is a bug with a delay.

**Applies to:** all repos.

## 2026-09-22 — Shell here runs on macOS bash 3.2 and BSD userland, not GNU

**Context:** writing the framework scripts and hooks, which run on developers' Macs.

**What happened:** four separate surprises. `**` is not recursive — macOS ships bash 3.2 and
`globstar` does not exist, so `ls **/*.py` silently searched one level. `"${arr[@]}"` on an
empty array errors under `set -u`. BSD `sed` emits no trailing newline, so a `while read` loop
dropped its final field — which happened to be the actual argument being checked. There is no
`timeout` binary, so an unguarded call exits 127 and looked like a lint failure on every edit.

**Rule:** target bash 3.2 and BSD tools. Use `find … -print` instead of `**`; write
`${arr[@]+"${arr[@]}"}`; end a `while read` with `|| [ -n "$last" ]` or avoid `sed` for the
last field; guard optional binaries with `command -v` before calling them. Test on macOS, not
only in a Linux container.

**Applies to:** all repos.

## 2026-09-22 — Test that a symlink resolves, not just that it is one

**Context:** auditing whether each repo's framework files are linked to canonical.

**What happened:** the check tested `[ -L "$t" ]` before testing `-e`, so a dangling link
counted as healthy. Because the links are committed into each repo and are relative, a
checkout outside `<workspace>/src/<name>` breaks every one of them — the hooks then never run,
and the audit reported the repo as fully linked. A silently disabled guard that passes its own
audit is the worst available failure mode.

**Rule:** `-L` answers "is this a symlink", not "does it work". Test `[ -L "$p" ] && [ ! -e "$p" ]`
first and treat it as a failure, naming the target. Verify a link immediately after creating
it, so a bad layout surfaces at install rather than as enforcement that quietly stopped.

**Applies to:** all repos.
