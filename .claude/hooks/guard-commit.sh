#!/usr/bin/env bash
# PreToolUse, matcher Bash. Enforces AGENTS.md Step 6 and advises on non-negotiable 8,
# locally, so they hold with or without CI.
#   Step 6  commit subject is <type>(<scope>): <subject>; the issue number is never in it
#   NN 8    (advisory) pushing a branch that changes code without a CHANGELOG entry
# Only `git commit -m "..."` subjects are checked; -F and editor-based commits are not parsed.
set -uo pipefail
source "$(dirname "$0")/_lib.sh"
cmd="$tool_command"; [ -n "$cmd" ] || exit 0
case "$cmd" in *git*) ;; *) exit 0 ;; esac   # nothing below applies without a git invocation
G="$GIT_CMD"

# --- Step 6: subject format --------------------------------------------------------------
if has "${G}commit[^;&|]*[[:space:]](-m|--message)([[:space:]]|=)"; then
  subj="$(printf '%s' "$cmd" | sed -nE "s/.*[[:space:]](-m|--message)[[:space:]=]+([\"'])([^\"'\\\\]*).*/\3/p" | head -1)"
  [ -n "$subj" ] || subj="$(printf '%s' "$cmd" | sed -nE 's/.*[[:space:]](-m|--message)[[:space:]=]+([^[:space:]"'"'"']+).*/\2/p' | head -1)"
  if [ -n "$subj" ]; then
    printf '%s' "$subj" | grep -qE '^#[0-9]' \
      && deny "Step 6: the issue number goes in the body as 'Resolves #NN', never in the subject — '$subj' breaks changelog generation."
    printf '%s' "$subj" | grep -qE "$CONVENTIONAL" \
      || deny "Step 6: subject must be Conventional Commits — <type>(<scope>): <subject>, type in feat fix docs style refactor perf test chore. Got: '$subj'"
  fi
fi

# --- NN 8 advisory: docs travel with the code -------------------------------------------
if has "${G}push([[:space:]]|$)"; then
  # Fall through every candidate: a repo on main with no develop would otherwise
  # resolve to empty and skip the check silently, which is the failure this advisory exists
  # to prevent.
  base=""
  for c in origin/develop develop origin/main main origin/master master; do
    base="$(git -C "$repo_dir" rev-parse --verify -q "$c" 2>/dev/null || true)"
    [ -n "$base" ] && break
  done
  if [ -n "$base" ]; then
    changed="$(git -C "$repo_dir" diff --name-only "$base...HEAD" 2>/dev/null || true)"
    if printf '%s\n' "$changed" | grep -qE '^(app|Modules|src|resources/js|database/migrations)/' \
       && ! printf '%s\n' "$changed" | grep -qx '.docs/CHANGELOG.md'; then
      msg="This branch changes application code without a .docs/CHANGELOG.md entry. Documentation ships with the code (AGENTS.md non-negotiable 8) — add the line under ## [Unreleased] before pushing, or say why not."
      printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","additionalContext":%s}}\n' "$(json_string "$msg")"
    fi
  fi
fi
exit 0
