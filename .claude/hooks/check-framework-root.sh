#!/usr/bin/env bash
# SessionStart. Advisory only (always exits 0; stdout becomes session context).
#   - says so if no ancestor CLAUDE.md imports AGENTS.md, i.e. the protocol will not load
#   - flags a stale Verified: date or a TEMPORARY block in the repo CLAUDE.md
set -uo pipefail
# SessionStart carries no tool payload, so source the helpers WITHOUT the payload parse.
FRAMEWORK_NO_PAYLOAD=1 source "$(dirname "$0")/_lib.sh"

found="$(find_framework_root "$repo_dir" || true)"
if [ -z "$found" ]; then
  echo "FRAMEWORK: no ancestor of $repo_dir has a CLAUDE.md importing AGENTS.md, so the development protocol is NOT loaded in this session. This repo should sit two levels below the framework root, at <framework-root>/src/<repo>/. The committed rules, hooks and skills here still apply."
fi

f="$repo_dir/CLAUDE.md"
if [ -f "$f" ] && [ "$repo_dir" != "$found" ]; then
  v="$(claude_md_verified_date "$f")"
  if [ -z "$v" ]; then
    echo "FRAMEWORK: CLAUDE.md has no 'Verified:' date. Its commands are unconfirmed; run bin/doctor before trusting them."
  elif age="$(days_since "$v")" && [ "$age" -gt "${FRAMEWORK_VERIFIED_MAX_DAYS:-90}" ]; then
    echo "FRAMEWORK: CLAUDE.md was last verified $v ($age days ago). Treat its commands as unconfirmed; run bin/doctor."
  fi
  tmp_line="$(claude_md_temporary_line "$f")"
  if [ -n "$tmp_line" ]; then
    echo "FRAMEWORK: CLAUDE.md has a TEMPORARY section at line $tmp_line. AGENTS.md voids any block claiming to override the protocol; check whether it has expired."
  fi
fi
exit 0
