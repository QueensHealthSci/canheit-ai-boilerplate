#!/usr/bin/env bash
# PreToolUse, matcher Bash. Enforces AGENTS.md non-negotiable 2:
#   dump the database before any destructive migration; restore after testing.
# A dump newer than FRAMEWORK_BACKUP_WINDOW_MIN (default 10) minutes must exist in
# FRAMEWORK_BACKUP_DIR (default <repo>/database/backups).
set -uo pipefail
source "$(dirname "$0")/_lib.sh"
[ -n "$tool_command" ] || exit 0

# Laravel artisan, Prisma, generic SQL. Stack-specific additions belong in the repo's copy.
DESTRUCTIVE='migrate:(fresh|refresh|reset|rollback)|db:wipe|schema:drop'
DESTRUCTIVE="$DESTRUCTIVE"'|prisma[[:space:]]+migrate[[:space:]]+reset|db[[:space:]]+push[^;&|]*--force-reset'
DESTRUCTIVE="$DESTRUCTIVE"'|(^|[^A-Za-z_])(DROP[[:space:]]+(TABLE|DATABASE|SCHEMA)|TRUNCATE)([^A-Za-z_]|$)'
# Gate on the RAW command first: _strip.py only ever deletes characters, so a raw match is a
# superset of a stripped one. This skips the python3 spawn on every non-destructive command.
printf '%s' "$tool_command" | grep -qiE "$DESTRUCTIVE" || exit 0
# Now strip, so a commit message naming these operations does not count. Quotes are kept, so
# an inline SQL string still does.
cmd="$(printf '%s' "$tool_command" | strip_quoted --keep-quotes)"
printf '%s' "$cmd" | grep -qiE "$DESTRUCTIVE" || exit 0

backup_dir="${FRAMEWORK_BACKUP_DIR:-$repo_dir/database/backups}"
window="${FRAMEWORK_BACKUP_WINDOW_MIN:-10}"
if find "$backup_dir" -type f \( -name '*.sql' -o -name '*.sql.gz' -o -name '*.sql.zst' -o -name '*.dump' \) \
     -mmin "-$window" 2>/dev/null | grep -q .; then
  exit 0
fi

deny "non-negotiable 2: destructive database operation with no dump in ${backup_dir#$repo_dir/} from the last $window minutes.
Run the 'Database dump' command from the repo CLAUDE.md COMMANDS table first, then retry. Restore the dump when testing is done."
