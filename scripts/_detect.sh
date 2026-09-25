#!/usr/bin/env bash
# Shared repo detection. Sourced by sync-repo.sh and check-framework.sh so the installer and
# the audit cannot disagree about what a repo needs — a disagreement there shows up as the
# checker demanding a sync that would do nothing, or staying quiet about one that is due.
#
# Nothing here hard-codes a rule name. A rule declares what it applies to in its own `paths:`
# frontmatter, and that declaration is the single source of truth: adding .claude/rules/go.md
# with a `paths:` list makes both scripts handle it with no edit to either.

# repo_files <dir> -> paths relative to the repo: tracked, plus untracked that are not ignored.
# .claude/ is excluded: it is what the framework installs, and counting it lets the framework
# trigger its own rules — a Laravel repo's only .py file can be the hooks' own _strip.py,
# which would install python.md there.
repo_files() {
  git -C "$1" ls-files --cached --others --exclude-standard 2>/dev/null | grep -v '^\.claude/'
}

# glob_to_regex <glob> -> an ERE body (no anchors).
#   **/  -> (.*/)?   so `**/*.py` matches both src/pkg/deep.py and root.py
#   **   -> .*
#   *    -> [^/]*
glob_to_regex() {
  printf '%s' "$1" | sed -e 's/[].[^$\\]/\\&/g' \
                         -e 's|\*\*/|\x01|g' -e 's|\*\*|\x02|g' \
                         -e 's|\*|[^/]*|g' \
                         -e 's|\x01|(.*/)\?|g' -e 's|\x02|.*|g'
}

# rule_globs <rule-file> [key] -> the entries of a frontmatter list, one per line.
# `paths:` answers "when should this LOAD". `applies:` answers "should this repo INSTALL it",
# which is a different question: every language has a tests/ directory, so laravel.md's
# `tests/**` load-trigger must not be what decides a non-Laravel repo needs Laravel rules.
# A rule without `applies:` falls back to `paths:`.
rule_globs() {
  awk -v key="^${2:-paths}:" '
    NR == 1 && $0 != "---" { exit }          # no frontmatter at all
    NR > 1 && $0 == "---"  { exit }          # end of frontmatter
    $0 ~ key               { inp = 1; next }
    inp && /^[[:space:]]*-[[:space:]]*/ {
      line = $0
      sub(/^[[:space:]]*-[[:space:]]*/, "", line)
      gsub(/^"|"$/, "", line)
      gsub(/^\x27|\x27$/, "", line)
      if (line != "") print line
      next
    }
    inp && /^[^[:space:]-]/ { inp = 0 }       # a sibling key ends the list
  ' "$1" 2>/dev/null
}

# rule_is_selective <rule-file> -> 0 if it declares paths:, i.e. it is installed only where
# it applies. A rule with none (shared.md) is always-on and belongs in every repo.
rule_is_selective() { [ -n "$(rule_globs "$1")" ]; }

# rule_applies <repo-dir> <rule-file> -> 0 when the repo contains a file the rule matches.
rule_applies() {
  local dir="$1" rule="$2" re="" g key=applies
  [ -n "$(rule_globs "$rule" applies)" ] || key=paths
  while IFS= read -r g; do
    [ -n "$g" ] || continue
    re="${re:+$re|}^$(glob_to_regex "$g")\$"
  done < <(rule_globs "$rule" "$key")
  [ -n "$re" ] || return 0        # no paths: -> always applies
  # NOT `repo_files | grep -qE`: under `set -o pipefail` (which both callers set) grep -q
  # exits on the first match, git upstream dies of SIGPIPE, and 141 becomes the pipeline's
  # status - so a rule matching an EARLY line reads as "does not apply" while one matching a
  # late line survives the race. Testing the captured text instead cannot be raced.
  [ -n "$(repo_files "$dir" | grep -m1 -E "$re")" ]
}

# repo_has_ui <dir> — drives the Playwright plugin and the e2e scaffold in both scripts.
repo_has_ui() {
  [ -d "$1/resources/js" ] || [ -d "$1/apps/web" ] || [ -d "$1/www-root" ]
}

# repo_has_playwright <dir> — a committed config is the signal, not the package.
# -prune rather than -not -path: find still walks node_modules otherwise, which measured ~4x.
repo_has_playwright() {
  [ -n "$(find "$1" \( -name node_modules -o -name vendor -o -name .git \) -prune -o \
          -name 'playwright.config.*' -print -quit 2>/dev/null)" ]   # captured, not piped: see rule_applies
}

# repo_e2e_spec_count <dir>
repo_e2e_spec_count() {
  find "$1" \( -name node_modules -o -name vendor -o -name .git \) -prune -o \
       \( -name '*.spec.ts' -o -name '*.spec.js' \) -print 2>/dev/null | grep -ciE 'e2e|playwright' || true
}

# repo_has_js_ui <dir> - a modern JS toolchain, which is NOT the same question as repo_has_ui:
# a legacy PHP repo has a UI in www-root and no eslint to point at it.
repo_has_js_ui() {
  [ -f "$1/package.json" ] && { [ -d "$1/resources/js" ] || [ -d "$1/apps/web" ]; }
}

# linter_targets <dir> -> the linter config filenames this repo should carry, one per line.
# Source and destination basenames are the same, both at the repo root.
#
# The mapping lives here, not in sync-repo.sh, so the audit checks exactly what the installer
# writes. AppServiceProvider.snippet.php is deliberately absent: it is a snippet to paste into
# an existing provider, not a file to install, and README.md is documentation.
#
# pint.json and phpstan.neon are Laravel-shaped - the `laravel` preset, Larastan, `paths: app`,
# `tmpDir: storage/phpstan` - so `artisan` is the signal, the same one laravel.md uses.
linter_targets() {
  [ -f "$1/artisan" ] && printf '%s\n' pint.json phpstan.neon
  repo_has_js_ui "$1" && printf '%s\n' eslint.framework.mjs
  return 0
}

# repo_legacy_docs <dir> -> the legacy project-docs directory, or empty.
# Some repos keep PROJECT artefacts in `.context/` - the name `.docs/` carries everywhere
# else - while at the framework root `.context/` means framework rules. Same name, two
# meanings, which is the whole argument in DOCS_LAYOUT.md for renaming them.
# Both scripts need to see this: the installer to refuse to build a second home for the same
# thing, the audit to report that the migration is still outstanding.
repo_legacy_docs() {
  { [ -d "$1/.context/memory" ] || [ -d "$1/.context/docs" ]; } && printf '.context'
}

# repo_changelog <dir> -> where this repo's changelog actually is, or empty.
# /release and /verify both name .docs/CHANGELOG.md; a repo keeping one elsewhere needs
# moving, not a second empty file beside it.
repo_changelog() {
  local c
  for c in .docs/CHANGELOG.md .context/docs/CHANGELOG.md CHANGELOG.md docs/CHANGELOG.md; do
    [ -f "$1/$c" ] && { printf '%s' "$c"; return 0; }
  done
  return 1
}

# repo_learnings_split <dir> -> 0 when learnings are split by domain, the standard.
# A single .docs/LEARNINGS.md holding entries is the thing to migrate: a mature one can be
# ~96k tokens with lines up to 2,900 characters, so "read the relevant section" is doing work
# no one can verify. Split, a session reads one domain.
repo_learnings_split() { [ -d "$1/.docs/learnings" ]; }

# repo_playwright_plugin_on <dir>
repo_playwright_plugin_on() {
  grep -q '"playwright@[^"]*": *true' "$1/.claude/settings.json" 2>/dev/null
}
