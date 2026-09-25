#!/usr/bin/env bash
# PreToolUse, matchers Read|Edit|Write|MultiEdit|Grep and Bash. Enforces AGENTS.md
# non-negotiable 4: never read, print or edit `.env*`. Environment files are committed by
# design (the deploy copies .env.{stage} into the release) and are edited by humans; the
# agent may stage and commit a human's change but never opens the file. This hook keeps
# their contents out of the transcript.
#
# Deliberately blocks .env.example too: an `.env.example-*` stage file can hold
# real production credentials, so the "example" name is not a safe carve-out. Learn key names from
# config/*.php or the template instead, or ask for the one value you need.
set -uo pipefail
source "$(dirname "$0")/_lib.sh"

ENV_BASENAME='(^|/)\.env([.-][A-Za-z0-9_.-]*)?$'
REDIRECT='(^|[[:space:]/=<:,"'"'"'])\.env([.-][A-Za-z0-9_.-]*)?([[:space:]"'"'"';),]|$)'

# --- file-based tools ----------------------------------------------------------------------
for f in "$tool_file" "$tool_path"; do
  [ -n "$f" ] || continue
  if printf '%s' "$f" | grep -qE "$ENV_BASENAME"; then
    deny "non-negotiable 4: $tool_name on '$(basename "$f")'. Environment files are never read, printed or edited by the agent. Key names live in config/; ask the user for a specific value."
  fi
done

# --- Bash ----------------------------------------------------------------------------------
cmd="$tool_command"; [ -n "$cmd" ] || exit 0

if has "$REDIRECT"; then
  # A verb that prints, copies, sources, greps or stages the file.
  VERBS='(^|[;&|[:space:](`])(sudo[[:space:]]+)?(cat|less|more|head|tail|tac|nl|grep|egrep|fgrep|rg|ag|sed|awk|cut|sort|uniq|strings|xxd|od|hexdump|base64|cp|mv|scp|rsync|curl|wget|source|export|set[[:space:]]+-a|printenv|python3?|php|node|ruby|perl|open|code|vim|vi|nano|emacs|git[[:space:]]+(show|diff|log|blame|grep|cat-file))([[:space:]]|$)'
  if has "$VERBS" || has '(^|[[:space:]])\.[[:space:]]+\.env' || has '<[[:space:]]*\.env'; then
    deny "non-negotiable 4: that command reads or copies an environment file. Their contents never enter the transcript. Ask the user for the one value you need."
  fi
  # Plain `git add <env file>` is allowed - staging a human's change prints nothing (decided
  # 2026-09-21). The patch, interactive and edit forms show hunks, which is a read.
  if has '(^|[;&|[:space:]])(sudo[[:space:]]+)?git[[:space:]]+add[^;&|]*[[:space:]](-[A-Za-z]*[pie][A-Za-z]*|--patch|--interactive|--edit)([[:space:]]|$)'; then
    deny "non-negotiable 4: git add with -p, -i or -e shows the file's contents. Stage the environment file by path with no flags."
  fi
fi

# History and index commands that print file CONTENT without naming a path: show, log -p,
# diff. Environment files are committed by design, so `git show` after a human committed
# one prints a secret. Re-run the same command names-only and refuse if an env file is in it.
# This rule matches the command with heredoc bodies dropped (quotes kept): a bare `git show`
# only runs at the top level of a shell, and commit messages here name these commands often.
# The verb-plus-path rule above deliberately does not strip.
case "$cmd" in *git*) ;; *) exit 0 ;; esac   # the history rule needs a git invocation
cmd_top="$(printf '%s' "$tool_command" | strip_quoted --keep-quotes)"
HIST='(^|[;&|[:space:]])(sudo[[:space:]]+)?git[[:space:]]+(show|log|diff|whatchanged)([[:space:]]|$)'
NAMES_ONLY='(^|[[:space:]])(-s|--no-patch|--name-only|--name-status|--stat|--shortstat|--numstat|--summary|--oneline)([[:space:]=]|$)'
if printf '%s' "$cmd_top" | grep -qE "$HIST" && ! printf '%s' "$cmd_top" | grep -qE "$NAMES_ONLY"; then
  sub="$(printf '%s' "$cmd_top" | sed -nE 's/.*(^|[;&|[:space:]])(sudo[[:space:]]+)?git[[:space:]]+(show|log|diff|whatchanged)([[:space:]]|$).*/\3/p' | head -1)"
  args="$(printf '%s' "$cmd_top" | sed -nE "s/.*(^|[;&|[:space:]])(sudo[[:space:]]+)?git[[:space:]]+${sub}([[:space:]]+([^;&|]*))?.*/\4/p" | head -1)"
  # One constant for both the test and the strip below. They previously disagreed: the test
  # matched the bundled form `-up`, the strip removed only `-p|-u|--patch`, so `git log -up`
  # was detected as a patch request and then re-run with `-up` still attached.
  if { [ "$sub" = log ] || [ "$sub" = whatchanged ]; } && ! printf '%s' "$args" | grep -qE "$PATCH_FLAG"; then
    exit 0   # log without a patch flag prints subjects, not content
  elif printf '%s' "$args" | grep -qE '\$\(|`|[<>]'; then
    deny "non-negotiable 4: a history command with a substitution or redirection cannot be checked against committed environment files. Add --name-only or --stat, or resolve the ref first."
  else
    clean="$(printf '%s' "$args" | sed -E "s/(^|[[:space:]])(-[A-Za-z0-9]*[pu]|--patch)([[:space:]]|\$)/\1\3/g")"
    if ! eval "set -- $clean" 2>/dev/null; then
      deny "non-negotiable 4: could not parse that history command well enough to check it against committed environment files. Add --name-only or --stat."
    fi
    if [ "$sub" = diff ]; then
      touched="$(git -C "$repo_dir" diff --name-only "$@" 2>/dev/null | grep -E "$ENV_BASENAME" | head -3 || true)"
    else
      touched="$(git -C "$repo_dir" "$sub" --name-only --format= "$@" 2>/dev/null | grep -E "$ENV_BASENAME" | head -3 || true)"
    fi
    [ -z "$touched" ] || deny "non-negotiable 4: that would print the contents of a committed environment file ($(printf '%s' "$touched" | tr '\n' ' ')). Use --name-only or --stat, or name paths that are not environment files."
  fi
fi

# Committing with an environment file staged is allowed (decided 2026-09-21): the agent may
# ship a human's change without opening it. `git diff --cached` over it is still refused by
# the history rule above, so the contents cannot be pulled into the transcript that way.

exit 0
