#!/usr/bin/env bash
# Shared helpers for the framework hooks. Sourced by each hook; never run directly.
#
# These run on EVERY tool call, so cost here is paid hundreds of times a session. Two rules:
# parse the payload once, and never fork a process for something bash can do.

# One read, no `cat` fork. Skipped when there is no tool payload (SessionStart, or a script
# sourcing this only for the constants and helpers) - reading stdin there would block.
hook_payload=""
[ -n "${FRAMEWORK_NO_PAYLOAD:-}" ] || IFS= read -r -d '' hook_payload 2>/dev/null || true

# One pass for every field, rather than one spawn per field. NUL-separated, not newline:
# a Bash command is routinely multi-line, and line-based reads would split it across fields.
_parse_payload() {
  local q='[.tool_name, .tool_input.command, .tool_input.file_path, .tool_input.path] | map(. // "") | join("\u0000") + "\u0000"'
  if command -v jq >/dev/null 2>&1; then
    printf '%s' "$hook_payload" | jq -j "$q" 2>/dev/null
  else
    printf '%s' "$hook_payload" | python3 -c '
import json, sys
try:
    o = json.load(sys.stdin); i = o.get("tool_input", {})
    if not isinstance(i, dict): i = {}
    vals = [o.get("tool_name"), i.get("command"), i.get("file_path"), i.get("path")]
except Exception:
    vals = [None] * 4
sys.stdout.write("".join((v if isinstance(v, str) else "") + "\0" for v in vals))' 2>/dev/null
  fi
}
tool_name=""; tool_command=""; tool_file=""; tool_path=""
if [ -n "$hook_payload" ]; then
  { IFS= read -r -d '' tool_name; IFS= read -r -d '' tool_command
    IFS= read -r -d '' tool_file; IFS= read -r -d '' tool_path; } < <(_parse_payload) || true
fi
: "${tool_name:=}" "${tool_command:=}" "${tool_file:=}" "${tool_path:=}"
repo_dir="${CLAUDE_PROJECT_DIR:-$PWD}"

# --- shared constants ----------------------------------------------------------------------
# One definition each, because a bypass found in one guard has to close in all of them.
GIT_CMD='(^|[;&|[:space:](`])(sudo[[:space:]]+)?git[[:space:]]+'   # a real git invocation
PROTECTED_BRANCHES='develop|main|master'                            # AGENTS.md non-negotiable 1
CONVENTIONAL='^(feat|fix|docs|style|refactor|perf|test|chore|wip)(\([^)]+\))?!?: .+'
PATCH_FLAG='(^|[[:space:]])(-[A-Za-z0-9]*[pu]|--patch)([[:space:]]|$)'

json_string() {  # json_string "text" -> "\"escaped text\""
  if command -v jq >/dev/null 2>&1; then printf '%s' "$1" | jq -Rs . 2>/dev/null
  else printf '%s' "$1" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))' 2>/dev/null; fi
}

# strip_quoted [--keep-quotes]: the command with heredoc bodies — and, unless --keep-quotes,
# quoted-string contents — removed, so a message that merely mentions a command is not
# mistaken for the command. python3 is REQUIRED: falling back to `cat` would silently
# disable stripping and make the guards deny on their own commit messages.
strip_quoted() {
  python3 "$(dirname "${BASH_SOURCE[0]}")/_strip.py" "$@"
}

# days_since YYYY-MM-DD -> whole days, portable across BSD and GNU date.
days_since() {
  local t
  t="$(date -j -f %Y-%m-%d "$1" +%s 2>/dev/null || date -d "$1" +%s 2>/dev/null)" || return 1
  echo $(( ( $(date +%s) - t ) / 86400 ))
}

# claude_md_verified_date <file> -> YYYY-MM-DD or empty. One pass.
claude_md_verified_date() {
  sed -nE 's/.*Verified:\**[[:space:]]*([0-9]{4}-[0-9]{2}-[0-9]{2}).*/\1/p' "$1" 2>/dev/null | head -1
}

# claude_md_temporary_line <file> -> first line number of a TEMPORARY heading, or empty.
# Case-insensitive in both callers: `## Temporary workaround` must not slip past one of them.
claude_md_temporary_line() {
  grep -niE '^#+ .*TEMPORARY' "$1" 2>/dev/null | head -1 | cut -d: -f1
}

# find_framework_root <start-dir> -> the directory whose CLAUDE.md imports the protocol.
# One definition, so a rename of the protocol file is one constant here and nowhere else.
PROTOCOL_FILE="AGENTS.md"
find_framework_root() {
  local d="${1:-$PWD}" i
  for i in 0 1 2 3 4; do
    if [ -f "$d/CLAUDE.md" ] && grep -q "^@${PROTOCOL_FILE}\$" "$d/CLAUDE.md" 2>/dev/null \
       && [ -f "$d/$PROTOCOL_FILE" ]; then printf '%s' "$d"; return 0; fi
    [ "$d" = "/" ] && break
    d="$(dirname "$d")"
  done
  return 1
}

# deny: block the tool call. Exit 2 returns stderr to the model as the reason.
deny() { printf 'BLOCKED by %s — %s\n' "$(basename "$0")" "$*" >&2; exit 2; }

# has <extended-regex> [string]: bash's own matcher, no subprocess. Defaults to $cmd.
# Measured 135x cheaper than `printf | grep -qE`, and these run on every tool call.
has() { [[ ${2-${cmd:-}} =~ $1 ]]; }
