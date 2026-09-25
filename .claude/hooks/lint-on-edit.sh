#!/usr/bin/env bash
# PostToolUse, matcher Edit|Write|MultiEdit. Advisory only — always exits 0.
#   - reports style/lint findings for the edited file when the repo has the tool installed
#   - reminds the agent to run the frontend build when frontend source changed
# Report-only on purpose: auto-fixing under the agent's feet makes its next read stale.
set -uo pipefail
source "$(dirname "$0")/_lib.sh"
f="$tool_file"; [ -n "$f" ] || exit 0
msgs=()

case "$f" in
  *.php)
    if [ -x "$repo_dir/vendor/bin/pint" ] && ! "$repo_dir/vendor/bin/pint" --test "$f" >/dev/null 2>&1; then
      msgs+=("pint: $(basename "$f") has style findings — run vendor/bin/pint $f")
    fi ;;
  *.ts|*.tsx|*.vue|*.js|*.mjs)
    # --cache is the difference between ~14s and ~170ms on the repos this installs into, on
    # a path that runs after every frontend edit. timeout keeps a cold cache from stalling.
    # `timeout` is GNU coreutils and absent on stock macOS; without this guard a missing
    # binary exits 127 and every edit reports a phantom lint failure.
    TMO=""; command -v timeout >/dev/null 2>&1 && TMO="timeout 20"
    command -v gtimeout >/dev/null 2>&1 && TMO="gtimeout 20"
    if [ -x "$repo_dir/node_modules/.bin/eslint" ] && ! out="$(cd "$repo_dir" && $TMO node_modules/.bin/eslint --cache --cache-location node_modules/.cache/eslint --max-warnings=0 "$f" 2>&1)"; then
      msgs+=("eslint: $(basename "$f") — $(printf '%s' "$out" | grep -E '^\s+[0-9]+:[0-9]+' | head -n 3 | sed 's/^[[:space:]]*//' | tr '\n' ';')")
    fi ;;
esac

# Frontend source: default Laravel layout; a repo overrides with FRAMEWORK_FRONTEND_RE in its copy.
if printf '%s' "$f" | grep -qE "${FRAMEWORK_FRONTEND_RE:-/resources/(js|css|sass|scss)/}"; then
  msgs+=("Frontend source changed — run the repo's frontend build (CLAUDE.md COMMANDS) before UAT, or the app serves the old bundle.")
fi

[ "${#msgs[@]}" -gt 0 ] || exit 0
text="$(printf '%s\n' "${msgs[@]}")"
printf '{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":%s}}\n' "$(json_string "$text")"
exit 0
