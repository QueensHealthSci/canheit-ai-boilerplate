#!/usr/bin/env bash
# check-framework.sh [--plans <repo>]
#
# Is the framework still true? Reports five things and exits non-zero on any FAIL:
#   1. line budgets for the always-on files
#   2. dead paths - references to files that no longer exist
#   3. drift - each repo's copy of hooks/rules/skills/agents against canonical
#   4. linters and e2e - whether each repo carries what its stack calls for
#   5. adherence - the three git numbers the review measured, per repo
#
# Read-only. Run it in /release, and whenever the framework changes.
#
# --plans <repo> prints the plan index from the plan files themselves, which is why no
# hand-maintained PLAN.md exists.
set -uo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"; cd "$root"
source "$root/scripts/_detect.sh"
pass=0; warn=0; fail=0
ok(){ pass=$((pass+1)); printf '  PASS  %s\n' "$*"; }
wn(){ warn=$((warn+1)); printf '  WARN  %s\n' "$*"; }
bad(){ fail=$((fail+1)); printf '  FAIL  %s\n' "$*"; }
# A repo is its own clone, or an in-tree example with a CLAUDE.md (the bundled examples).
repos(){ for d in src/*/; do { [ -d "$d/.git" ] || [ -f "$d/CLAUDE.md" ]; } && basename "$d"; done; }

# --- --plans -------------------------------------------------------------------------------
if [ "${1:-}" = "--plans" ]; then
  r="${2:-}"; d="src/$r/.docs/plans"
  [ -d "$d" ] || { echo "no plans in src/$r" >&2; exit 64; }
  printf '%-40s %-14s %s\n' "PLAN" "STATUS" "ISSUE"
  for f in "$d"/*.md; do
    [ -f "$f" ] || continue
    printf '%-40s %-14s %s\n' "$(basename "$f")" \
      "$(grep -m1 -oE '^\*\*Status:\*\*[[:space:]]*[A-Za-z ]+' "$f" | sed -E 's/.*\*\*[[:space:]]*//;s/[[:space:]]*$//' || echo '-')" \
      "$(grep -m1 -oE '^\*\*Issue:\*\*[[:space:]]*#?[0-9]+' "$f" | grep -oE '[0-9]+' || echo '-')"
  done
  exit 0
fi

echo "== line budgets =="
budget(){ local f="$1" max="$2" n; [ -f "$f" ] || { bad "$f missing"; return; }
  n=$(wc -l < "$f" | tr -d ' ')
  [ "$n" -le "$max" ] && ok "$f $n/$max" || bad "$f $n lines, budget $max"; }
budget AGENTS.md 150
budget .claude/rules/shared.md 50
budget .global-docs/TEMPLATE_AGENT.md 100
n=$(wc -l < CLAUDE.md | tr -d ' '); [ "$n" -le 2 ] && ok "CLAUDE.md $n line(s)" || bad "CLAUDE.md should be one @AGENTS.md line, has $n"

echo "== always-on rules =="
for f in .claude/rules/*.md; do
  head -1 "$f" | grep -q '^---$' || { [ "$(basename "$f")" = shared.md ] \
    && ok "$(basename "$f") always-on by design" \
    || bad "$(basename "$f") has no paths: frontmatter - it will load every session"; }
done

echo "== dead paths =="
dead=0
while IFS= read -r hit; do
  f="${hit%%:*}"; p="${hit#*:*:}"
  case "$p" in *'<'*|*'>'*) continue ;; esac   # <placeholder> segments are illustrative
  [ -e "$p" ] || { bad "$f references missing $p"; dead=1; }
done < <(grep -rnoE '\.(context|global-docs|claude)/[A-Za-z0-9_./-]+\.(md|sh|json|neon)' \
           AGENTS.md .context/development_cycle.md .context/enforcement.md .global-docs/*.md .claude/rules/*.md 2>/dev/null \
         | grep -v reference/coding-standards-examples | sort -u)
[ "$dead" = 0 ] && ok "no dead paths in the always-on and reference set"

echo "== per-repo drift =="
for r in $(repos); do
  d="src/$r"; [ -d "$d/.claude" ] || { wn "$r: no .claude/ - not onboarded - run scripts/sync-repo.sh $r"; continue; }
  linked=0; copied=0; over=0; missing=0; own=0; broken=0
  for area in hooks rules skills agents; do
    [ -d "$root/.claude/$area" ] || continue
    for f in "$root/.claude/$area"/*; do
      [ -e "$f" ] || continue
      b="$(basename "$f")"; [ "$b" = tests ] && continue
      t="$d/.claude/$area/$b"
      # A link that resolves to nothing is the dangerous case: the guard does not run, and
      # `-L` alone would have counted it as healthy. Test resolution BEFORE linked-ness.
      if [ -L "$t" ] && [ ! -e "$t" ]; then
        broken=$((broken+1)); printf '        broken:     .claude/%s/%s -> %s\n' "$area" "$b" "$(readlink "$t")"
      elif [ ! -e "$t" ] && [ ! -L "$t" ]; then
        # A selective rule that does not apply here is correctly absent. Asking the rule
        # itself means adding one never needs an edit to this list - there is no list.
        if [ "$area" = rules ] && rule_is_selective "$f" && ! rule_applies "$d" "$f"; then :
        else missing=$((missing+1)); fi
      elif [ -L "$t" ]; then linked=$((linked+1))
      elif diff -rq "$f" "$t" >/dev/null 2>&1; then copied=$((copied+1))
      else over=$((over+1)); printf '        overridden: .claude/%s/%s\n' "$area" "$b"; fi
    done
    # Files the repo added that have no canonical counterpart: legitimate extension.
    for t in "$d/.claude/$area"/*; do
      [ -e "$t" ] || continue
      b="$(basename "$t")"
      [ -e "$root/.claude/$area/$b" ] || { own=$((own+1)); printf '        repo-only:  .claude/%s/%s\n' "$area" "$b"; }
    done
  done
  extra=""; [ "$own" -gt 0 ] && extra=" (+$own repo-only)"
  if   [ "$broken" -gt 0 ];  then bad "$r: $broken BROKEN link(s) - the hooks do not run. Is this repo under <workspace>/src/? Re-run sync-repo.sh $r$extra"
  elif [ "$over" -gt 0 ];    then bad "$r: $over file(s) override canonical - justify in LOCKED DECISIONS or re-link$extra"
  elif [ "$missing" -gt 0 ]; then wn "$r: $missing canonical file(s) not installed$extra"
  elif [ "$copied" -gt 0 ];  then wn "$r: $copied file(s) copied rather than linked - re-run sync-repo.sh $r$extra"
  elif [ "$linked" -gt 0 ];  then ok "$r: $linked file(s) linked to canonical$extra"
  else wn "$r: nothing installed"; fi
done

echo "== project docs =="
for r in $(repos); do
  d="src/$r"
  legacy="$(repo_legacy_docs "$d")"
  cl="$(repo_changelog "$d" || true)"
  if [ -n "$legacy" ]; then
    wn "$r: project docs live in $legacy/, not .docs/ - migrate (/onboard-repo step 6); sync skips scaffolding until then"
  elif [ -z "$cl" ]; then
    wn "$r: no changelog - /release and /verify both read .docs/CHANGELOG.md. Run sync-repo.sh $r"
  elif [ "$cl" != ".docs/CHANGELOG.md" ]; then
    wn "$r: changelog is at $cl - /release reads .docs/CHANGELOG.md. Move it."
  fi
  if [ -f "$d/.docs/LEARNINGS.md" ]; then
    n=$(wc -l < "$d/.docs/LEARNINGS.md" | tr -d ' '); t=$(( $(wc -c < "$d/.docs/LEARNINGS.md") / 4 ))
    if repo_learnings_split "$d"; then
      wn "$r: .docs/learnings/ exists but .docs/LEARNINGS.md remains ($n lines) - finish the move and delete it"
    else
      wn "$r: learnings are one file ($n lines, ~$t tok) - split into .docs/learnings/ by domain (/onboard-repo step 7)"
    fi
  fi
done

echo "== linters =="
for r in $(repos); do
  d="src/$r"; want=0; got=0; ownn=0; miss=""; brk=""
  while IFS= read -r l; do
    [ -n "$l" ] || continue
    want=$((want+1))
    if   [ -L "$d/$l" ] && [ ! -e "$d/$l" ]; then brk="${brk:+$brk }$l"
    elif [ -L "$d/$l" ]; then got=$((got+1))
    elif [ -e "$d/$l" ]; then ownn=$((ownn+1))
    else miss="${miss:+$miss }$l"; fi
  done < <(linter_targets "$d")
  [ "$want" = 0 ] && continue
  if   [ -n "$brk" ];  then bad "$r: broken link(s): $brk - re-run scripts/sync-repo.sh $r"
  elif [ -n "$miss" ]; then wn "$r: no $miss - run scripts/sync-repo.sh $r"
  else ok "$r: $got linked, $ownn repo's own"; fi
done

echo "== e2e readiness =="
printf '        %-18s %-5s %-11s %-7s %s\n' "REPO" "UI" "PLAYWRIGHT" "PLUGIN" ""
for r in $(repos); do
  d="src/$r"
  ui=0; repo_has_ui "$d" && ui=1
  pw=0; repo_has_playwright "$d" && pw=1
  pl=0; repo_playwright_plugin_on "$d" && pl=1
  specs=0; [ "$pw" = 1 ] && specs=$(repo_e2e_spec_count "$d")
  printf '        %-18s %-5s %-11s %-7s ' "$r" "$([ $ui = 1 ] && echo yes || echo no)" \
         "$([ $pw = 1 ] && echo "yes ($specs)" || echo no)" "$([ $pl = 1 ] && echo yes || echo no)"
  if   [ $ui = 0 ] && [ $pl = 1 ]; then echo ""; wn "$r: playwright plugin enabled with no UI - remove it"
  elif [ $ui = 1 ] && [ $pw = 0 ] && [ $pl = 1 ]; then echo ""; bad "$r: plugin enabled but Playwright is not installed - scaffold it or turn the plugin off"
  elif [ $ui = 1 ] && [ $pw = 0 ]; then echo ""; wn "$r: has a UI and no e2e - run scripts/sync-repo.sh $r to scaffold"
  elif [ $ui = 1 ] && [ $pw = 1 ] && [ $pl = 0 ]; then echo ""; wn "$r: Playwright installed but the plugin is off"
  else echo "ok"; fi
done

echo "== adherence (last 12 months) =="
printf '        %-18s %-22s %-16s %s\n' "REPO" "CONVENTIONAL COMMITS" "ON BASE BRANCH" "STALE REMOTES"
for r in $(repos); do
  d="src/$r"; since="12 months ago"
  base=develop; git -C "$d" rev-parse --verify -q develop >/dev/null 2>&1 || base=main
  total=$(git -C "$d" log --since="$since" --no-merges --format=%s 2>/dev/null | wc -l | tr -d ' ')
  [ "$total" -gt 0 ] || { printf '        %-18s %s\n' "$r" "no commits in window"; continue; }
  conv=$(git -C "$d" log --since="$since" --no-merges --format=%s 2>/dev/null \
         | grep -cE '^(feat|fix|docs|style|refactor|perf|test|chore|wip)(\([^)]+\))?!?: ' || true)
  direct=$(git -C "$d" log --since="$since" --no-merges --first-parent "$base" --format=%H 2>/dev/null | wc -l | tr -d ' ')
  stale=$(git -C "$d" branch -r --merged "$base" 2>/dev/null | grep -vcE 'HEAD|/(develop|main|master)$' || true)
  pct=$(( conv * 100 / total ))
  printf '        %-18s %3d%% (%d/%d)%-8s %-16s %s\n' "$r" "$pct" "$conv" "$total" "" "$direct on $base" "$stale"
  [ "$pct" -ge 90 ] || wn "$r: $pct% Conventional Commits"
done

echo
printf '%d pass, %d warn, %d fail\n' "$pass" "$warn" "$fail"
[ "$fail" -eq 0 ]
