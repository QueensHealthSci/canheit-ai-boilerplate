#!/usr/bin/env bash
# sync-repo.sh <repo> [--copy] [--dry-run] [--force]
#
# Runs on any branch. It writes files and never commits, so committing them is a separate,
# deliberate act - and non-negotiable 1 still refuses a commit on develop or main.
#
# Points src/<repo> at the canonical framework files. Hooks, settings, skills, subagents,
# rules and bin/ do NOT inherit from a parent directory the way CLAUDE.md does, so each repo
# needs its own entries - relative SYMLINKS by default, so there is one copy to change and
# drift is not possible. --copy is for a checkout that will live outside this workspace.
#
# Linking happens per ENTRY, not per directory, so a repo can add its own hook or skill
# beside the shared ones. settings.json is MERGED, never overwritten: the repo's
# enabledPlugins and local permissions survive, and the framework's wiring is layered on.
#
# Which rules a repo gets is decided by each rule's own `applies:` frontmatter, not by a
# list here - see scripts/_detect.sh, which check-framework.sh reads too so the installer
# and the audit cannot disagree.
#
# Everything it writes is inside src/<repo>. It never commits, never pushes, and never
# touches a file outside .claude/, bin/ or .docs/ scaffolding.
set -uo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
source "$root/scripts/_detect.sh"

repo="${1:-}"; shift || true
dry=0; force=0; mode=link
for a in "$@"; do
  case "$a" in --dry-run) dry=1 ;; --force) force=1 ;; --copy) mode=copy ;; esac
done

[ -n "$repo" ] || { echo "usage: scripts/sync-repo.sh <repo> [--copy] [--dry-run] [--force]"; exit 64; }
dest="$root/src/$repo"
[ -d "$dest" ] || { echo "no such repo: src/$repo" >&2; exit 64; }
# Its own clone, or a directory tracked in-tree by the framework repo (the bundled examples).
git -C "$dest" rev-parse --is-inside-work-tree >/dev/null 2>&1 || { echo "src/$repo is not inside a git work tree" >&2; exit 64; }
# Empty for a clone; `src/<repo>/` for an in-tree example, whose status paths carry it.
git_prefix="$(git -C "$dest" rev-parse --show-prefix 2>/dev/null)"

say() { printf '  %-8s %s\n' "$1" "$2"; }
run() { [ "$dry" = 1 ] && return 0; "$@"; }

# install <abs-src> <abs-dest> <label>
# Default is a RELATIVE SYMLINK. Every repo lives under this root, so the target always
# resolves, the framework is inherited rather than duplicated, and a change here reaches
# every repo at once. --copy is for a checkout that will live outside the workspace, where
# a link would dangle.
# install_entries <abs-src-dir> <abs-dest-dir> <label-prefix>
# Links each ENTRY rather than the directory, so a repo can drop its own hook, agent or
# skill in alongside the shared ones. A directory link would make the whole set read-only.
# The cost: a new canonical file needs a re-sync to appear - check-framework reports that.
install_entries() {
  local src="$1" dst="$2" pre="$3" f b
  [ -L "$dst" ] && run rm -f "$dst"          # undo an older whole-directory link
  run mkdir -p "$dst"
  for f in "$src"/*; do
    [ -e "$f" ] || continue
    b="$(basename "$f")"
    case "$b" in tests) continue ;; esac
    install "$f" "$dst/$b" "$pre$b"
  done
}

install() {
  local src="$1" dst="$2" label="$3" rel
  if [ "$mode" = copy ]; then
    run rm -rf "$dst"; run cp -R "$src" "$dst"; say "copy" "$label"
  else
    rel="$(python3 -c 'import os,sys; print(os.path.relpath(sys.argv[1], sys.argv[2]))' "$src" "$(dirname "$dst")")"
    if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$rel" ]; then say "ok" "$label (already linked)"; return 0; fi
    run rm -rf "$dst"; run ln -s "$rel" "$dst"; say "link" "$label -> $rel"
    # Catch a bad layout at install rather than as a guard that silently never fires. The
    # link is relative, so it only dangles if this repo is not at <workspace>/src/<name>.
    [ "$dry" = 1 ] || [ -e "$dst" ] || say "WARN" "$label links to nothing - is this repo under <workspace>/src/?"
  fi
}

[ "$dry" = 1 ] && echo "sync $repo (dry run — nothing written)" || echo "sync $repo [$mode]"
# The branch is reported, not policed. This script writes files and never commits, so where
# the change lands is the committer's decision, not the installer's - and demanding a branch
# per repo made a mechanical, repeatable sync cost fourteen branches. Non-negotiable 1 still
# stops a commit on develop or main; the dirty-tree guard below still protects work in
# progress. Those are the checks that matter here.
branch="$(git -C "$dest" rev-parse --abbrev-ref HEAD 2>/dev/null || echo '?')"
say "branch" "$branch"

# Everything this script may create or modify, built once from the same helper the install
# loop below uses. The dirty-tree guard filters against it, so the files the script itself
# writes never block the next run. Restating the list by hand is what broke it before: the
# old enumeration missed `.gitignore` (the e2e scaffold appends to it) and the collapsed
# `?? .docs/`, so every UI repo refused its second sync.
owned=( '\.claude/' 'bin/' 'e2e/' 'playwright\.config\.' '\.docs/' '\.gitignore$' )
while IFS= read -r l; do
  [ -n "$l" ] || continue
  owned+=( "$(printf '%s' "$l" | sed 's/[.]/\\./g')\$" )
done < <(linter_targets "$dest")
OWNED_RE="^($(IFS='|'; printf '%s' "${owned[*]}"))"

# A dirty tree means work someone else started. AGENTS.md: uncommitted work you did not write
# is a stop-and-ask, not something to write over.
# Exclude the paths this script writes: after the first sync they are legitimately dirty,
# and refusing on them would make every re-sync impossible.
dirty="$(git -C "$dest" status --porcelain -- . 2>/dev/null \
         | sed -E 's/^.{3}//' | sed "s|^$git_prefix||" | grep -vE "$OWNED_RE" || true)"
if [ -n "$dirty" ] && [ "$force" = 0 ]; then
  echo "  refusing: src/$repo has uncommitted changes outside the files this script owns:" >&2
  printf '%s\n' "$dirty" | head -10 | sed 's/^/      /' >&2
  echo "  Commit or stash them first, or pass --force if you are sure." >&2
  exit 1
fi
[ -n "$dirty" ] && say "WARN" "proceeding over $(printf '%s\n' "$dirty" | wc -l | tr -d ' ') uncommitted change(s) (--force)"

# --- hooks, subagents ---------------------------------------------------------------------
run mkdir -p "$dest/.claude"
for d in hooks agents skills; do
  install_entries "$root/.claude/$d" "$dest/.claude/$d" ".claude/$d/"
done
[ "$mode" = copy ] && run chmod +x "$dest/.claude/hooks/"*.sh 2>/dev/null
:

# --- rules: each rule decides for itself whether it applies here --------------------------
# No list of rule names lives in this script. A rule declares `applies:` (or falls back to
# `paths:`) in its own frontmatter, and adding .claude/rules/go.md needs no edit here.
run mkdir -p "$dest/.claude/rules"
for rule in "$root/.claude/rules"/*.md; do
  [ -f "$rule" ] || continue
  b="$(basename "$rule")"
  if rule_applies "$dest" "$rule"; then
    install "$rule" "$dest/.claude/rules/$b" ".claude/rules/$b"
  elif [ -L "$dest/.claude/rules/$b" ]; then
    # It applied once and no longer does - remove the link, never a real or repo-only file.
    run rm -f "$dest/.claude/rules/$b"; say "unlink" ".claude/rules/$b (no longer applies)"
  fi
done

# --- bin ----------------------------------------------------------------------------------
run mkdir -p "$dest/bin"
# Both are framework content now: bin/check derives the runner rather than carrying a
# hand-written command, so there is nothing repo-specific left in it to preserve. Per-repo
# overrides go through CHECK_CMD / CHECK_PREFIX in the environment.
install "$root/.global-docs/bin/doctor" "$dest/bin/doctor" "bin/doctor"
install "$root/.global-docs/bin/check"  "$dest/bin/check"  "bin/check"

# --- linter configs -------------------------------------------------------------------------
# Installed only when ABSENT. A repo's own pint.json or phpstan.neon is configuration someone
# tuned for that codebase; a sync that overwrote it would be doing the opposite of its job.
# Replacing an installed link with a real file is the documented way to opt out, and
# check-framework reports which repos have done so.
php_linted=0; js_linted=0
while IFS= read -r l; do
  [ -n "$l" ] || continue
  if [ -e "$dest/$l" ] && [ ! -L "$dest/$l" ]; then
    say "keep" "$l (repo's own)"
  else
    install "$root/.global-docs/linters/$l" "$dest/$l" "$l"
    case "$l" in *.mjs) js_linted=1 ;; *) php_linted=1 ;; esac
  fi
done < <(linter_targets "$dest")
# The configs are inert without their tooling, and saying so here is cheaper than a confused
# `phpstan` run later. sync never installs dependencies - that is the repo's own lockfile.
[ "$php_linted" = 1 ] && say "note" "needs: composer require --dev laravel/pint larastan/larastan spaze/phpstan-disallowed-calls"
[ "$js_linted" = 1 ] && say "note" "wire it: import framework from './eslint.framework.mjs'; export default [...base, ...framework]"

# --- e2e scaffold: UI repo with no Playwright yet ------------------------------------------
has_ui=0; repo_has_ui "$dest" && has_ui=1
has_pw=0; repo_has_playwright "$dest" && has_pw=1
if [ "$has_ui" = 1 ] && [ "$has_pw" = 0 ]; then
  run mkdir -p "$dest/e2e"
  run cp "$root/.global-docs/e2e/playwright.config.ts" "$dest/playwright.config.ts"
  run cp "$root/.global-docs/e2e/global.setup.ts"      "$dest/e2e/global.setup.ts"
  run cp "$root/.global-docs/e2e/smoke.spec.ts"        "$dest/e2e/smoke.spec.ts"
  [ -f "$root/.claude/rules/e2e.md" ] && install "$root/.claude/rules/e2e.md" "$dest/.claude/rules/e2e.md" ".claude/rules/e2e.md"   # scaffolded just now, so it applies from here on
  say "scaffold" "playwright.config.ts + e2e/ (run: npm i -D @playwright/test)"
  if [ "$dry" = 0 ] && [ -f "$dest/.gitignore" ] && ! grep -q '^e2e/\.auth' "$dest/.gitignore"; then
    printf '\n# Playwright stored session - a credential\ne2e/.auth/\n' >> "$dest/.gitignore"
    say "append" ".gitignore  e2e/.auth/"
  fi
elif [ "$has_ui" = 0 ]; then
  say "skip" "e2e scaffold (no UI - e2e here would be ceremony)"
fi

# --- settings.json: merge, never clobber ---------------------------------------------------
if [ "$dry" = 0 ]; then
  python3 - "$root/.claude/settings.json" "$dest/.claude/settings.json" "$has_ui" <<'PY'
import json, sys, os
canon, target, has_ui = sys.argv[1], sys.argv[2], sys.argv[3] == "1"
c = json.load(open(canon))
t = json.load(open(target)) if os.path.exists(target) else {}
t["hooks"] = c["hooks"]                                   # framework owns the hook wiring
perms = t.setdefault("permissions", {})
for key in ("deny", "allow"):                             # union, canonical first, repo's kept
    merged = list(c["permissions"][key])
    for v in perms.get(key, []):
        if v not in merged: merged.append(v)
    perms[key] = merged
# Playwright plugin follows whether the repo has a UI, in both directions. Two repos had it
# enabled with no Playwright installed - configuration for a tool that is not there.
plugins = t.setdefault("enabledPlugins", {})
KEY = "playwright@claude-plugins-official"
note = ""
if has_ui and not plugins.get(KEY):
    plugins[KEY] = True; note = "; playwright plugin enabled"
elif not has_ui and KEY in plugins:
    del plugins[KEY]; note = "; playwright plugin removed (no UI)"
if not plugins: t.pop("enabledPlugins", None)
os.makedirs(os.path.dirname(target), exist_ok=True)
json.dump(t, open(target, "w"), indent=2); open(target, "a").write("\n")
print("  merge  .claude/settings.json (%d deny, %d allow, %d plugin(s)%s)"
      % (len(perms["deny"]), len(perms["allow"]), len(t.get("enabledPlugins", {})), note))
PY
else
  say "merge" ".claude/settings.json (skipped in dry run)"
fi

# --- .docs scaffolding: create only what is missing ----------------------------------------
# A repo that keeps its project docs in .context/ gets NOTHING scaffolded. Creating .docs/
# beside it would leave two homes for the same thing and point /release at an empty file
# while the real history sits in the other tree - worse than not running at all.
legacy="$(repo_legacy_docs "$dest")"
if [ -n "$legacy" ]; then
  say "SKIP" ".docs/ scaffold - this repo keeps project docs in $legacy/"
  say ""     "  Migrate $legacy/ to .docs/ first (/onboard-repo step 6), then re-run. Moving $(find "$dest/$legacy" -type f 2>/dev/null | wc -l | tr -d ' ') files is the repo owner's call."
else
  run mkdir -p "$dest/.docs/plans" "$dest/.docs/design"
  # CHANGELOG is scaffolded too: /release step 1 and /verify both read .docs/CHANGELOG.md,
  # and until now nothing created it - two skills pointing at a file that never existed.
  run mkdir -p "$dest/.docs/learnings"
  # Domain files are NOT created here. An empty backend_learnings.md is noise that survives
  # for years; the first entry creates its file. Only the index is scaffolded.
  # No .docs/LEARNINGS.md either, in any form: a monolith is what we are removing, and a
  # pointer file is still a file every session pays to open before reaching the real one.
  [ -f "$dest/.docs/LEARNINGS.md" ] && say "WARN" ".docs/LEARNINGS.md still exists - split it into .docs/learnings/ and delete it (onboard-repo step 7)"
  for pair in "TEMPLATE_LEARNINGS_INDEX.md:.docs/learnings/README.md" \
              "TEMPLATE_TEST_LEDGER.md:.docs/TEST_LEDGER.md" \
              "TEMPLATE_CHANGELOG.md:.docs/CHANGELOG.md"; do
    src="${pair%%:*}"; dst="${pair##*:}"
    if [ -e "$dest/$dst" ]; then say "keep" "$dst (exists)"
    else
      existing="$(repo_changelog "$dest" || true)"
      if [ "$dst" = ".docs/CHANGELOG.md" ] && [ -n "$existing" ]; then
        say "WARN" "changelog is at $existing, not $dst - /release will not find it. Move it."
        continue
      fi
      run cp "$root/.global-docs/$src" "$dest/$dst"; say "copy" "$dst"
    fi
  done
fi

echo
echo "Next, in src/$repo:"
echo "  1. /onboard-repo                 # the judgement work this script cannot do -"
echo "                                   # it is installed now, so the skill exists"
echo "  2. bin/doctor                    # what CLAUDE.md gets wrong"
echo "  3. bin/check                     # it detects the runner; CHECK_CMD overrides"
echo "  4. try a guarded command         # e.g. ask for a commit on develop; it must refuse"
echo "  5. review the diff, then commit  # this script never commits"
echo
echo "The hook fixture suite is not copied - it tests the canonical hooks and lives in"
echo "$root/.claude/hooks/tests/. Run it there after changing a hook, not here."
