#!/usr/bin/env bash
# PreToolUse, matcher Bash. Enforces AGENTS.md non-negotiables 1, 3 and 5:
#   1. never commit or push on develop/main
#   3. stage by path — never git add . / -A, never git commit -a
#   5. no force push, reset --hard, clean -f, or recursive delete outside the repo
set -uo pipefail
source "$(dirname "$0")/_lib.sh"
[ -n "$tool_command" ] || exit 0

# Cheap gate before anything expensive. Every rule below needs the literal "git" or "rm" in
# the command, and _strip.py only ever DELETES characters, so a raw substring test can never
# produce a false negative. This skips the python3 spawn for the great majority of calls.
case "$tool_command" in
  *git*|*rm*) ;;
  *) exit 0 ;;
esac

# Match against the command with quoted text and heredoc bodies removed, so a commit
# message that talks about a forbidden command is not treated as running it.
cmd="$(printf '%s' "$tool_command" | strip_quoted)"
G="$GIT_CMD"

if [[ $cmd =~ $G ]]; then
  # --- 1. protected branches ---------------------------------------------------------------
  if has "${G}(commit|push)([[:space:]]|$)"; then
    branch="$(git -C "$repo_dir" rev-parse --abbrev-ref HEAD 2>/dev/null || echo '')"
    case "$branch" in
      develop|main|master)
        deny "non-negotiable 1: no commits or pushes on '$branch'. Create <type>/<issue>-<slug> from develop first." ;;
    esac
  fi
  # pushing *to* a protected branch from anywhere (git push origin develop | HEAD:main)
  has "${G}push[^;&|]*[[:space:]:]($PROTECTED_BRANCHES)([[:space:]]|$)" \
    && deny "non-negotiable 1: nothing pushes to develop or main directly. Push the branch and open a pull request."

  # --- 3. stage by path --------------------------------------------------------------------
  has "${G}add([[:space:]]+-[A-Za-z-]+)*[[:space:]]+(\.|-A|--all)([[:space:]]|$)" \
    && deny "non-negotiable 3: stage by path. 'git add .' and '-A' stage whatever the gitignore misses. Run git status, then git add <path> <path>."
  has "${G}commit[^;&|]*([[:space:]]-[A-Za-z]*a[A-Za-z]*([[:space:]]|$)|[[:space:]]--all([[:space:]]|$))" \
    && deny "non-negotiable 3: 'git commit -a' stages blindly. Stage by path, then commit."

  # --- 5. destructive git ------------------------------------------------------------------
  has "${G}push[^;&|]*[[:space:]](--force|-f|--force-with-lease)([[:space:]=]|$)" \
    && deny "non-negotiable 5: no force push. Rewriting shared history is not recoverable by anyone else."
  has "${G}reset[^;&|]*[[:space:]]--hard([[:space:]]|$)" \
    && deny "non-negotiable 5: no git reset --hard. It destroys uncommitted work with no undo. Use git stash, or git revert for committed work."
  has "${G}clean[^;&|]*[[:space:]](-[A-Za-z]*f[A-Za-z]*|--force)([[:space:]]|$)" \
    && deny "non-negotiable 5: no git clean -f. Untracked files are gone for good."
  has "${G}branch[^;&|]*[[:space:]]-D[[:space:]]+($PROTECTED_BRANCHES)([[:space:]]|$)" \
    && deny "non-negotiable 5: protected branch."
  has "${G}(checkout[^;&|]*[[:space:]]--[[:space:]]+|restore[[:space:]]+)(\.|:/|\*)([[:space:]]|$)" \
    && deny "non-negotiable 5: discarding the whole working tree destroys uncommitted work. Restore one path at a time, and only what you changed."
fi

# --- 5. recursive delete outside the repo --------------------------------------------------
# The rule is about WHERE the target is, not how it is spelled. Resolve it and compare against
# the repo root: `rm -rf /abs/path/inside/the/repo/node_modules` and `rm -rf node_modules` are
# the same operation and must get the same answer. Quotes are kept — a quoted path is a real
# argument — but heredoc bodies are still dropped.
cmd_rm="$(printf '%s' "$tool_command" | strip_quoted --keep-quotes)"
RM='(^|[;&|[:space:]])(sudo[[:space:]]+)?rm[[:space:]]'
if [[ $cmd_rm =~ $RM ]] \
   && [[ $cmd_rm =~ ${RM}([^;&|]*[[:space:]])?(-[A-Za-z]*r|--recursive) ]]; then
  top="$(git -C "$repo_dir" rev-parse --show-toplevel 2>/dev/null || printf '%s' "$repo_dir")"
  # One pass: resolve every non-flag target and report those that land outside the repo.
  # realpath normalises `..` and needs no path to exist, which matters because deleting a
  # directory that is not there yet is ordinary. This block only runs for a recursive rm,
  # so the spawn is rare.
  targets="$(printf '%s' "$cmd_rm" | sed -nE 's/.*(^|[;&|[:space:]])(sudo[[:space:]]+)?rm[[:space:]]+([^;&|]*).*/\3/p')"
  outside="$(printf '%s' "$targets" | python3 -c '
import os, sys
top, repo = os.path.realpath(sys.argv[1]), sys.argv[2]
home = os.path.expanduser("~")
for raw in sys.stdin.read().split():
    t = raw.strip().strip("\"\x27")
    if not t or t.startswith("-"):
        continue
    if t in (".", "*", "./*"):          # "everything here" - never a safe recursive delete
        print(t); continue
    t = t.replace("${HOME}", home).replace("$HOME", home)
    t = os.path.expanduser(t)
    p = os.path.realpath(t if os.path.isabs(t) else os.path.join(repo, t))
    if not p.startswith(top + os.sep):  # equal to top counts as outside: that is the repo root
        print(raw)
' "$top" "$repo_dir" 2>/dev/null)"
  [ -z "$outside" ] || deny "non-negotiable 5: recursive delete of $(printf '%s' "$outside" | tr '\n' ' ')— resolves outside the repo ($top), or to the repo root itself. Name a path inside it."
fi

exit 0
