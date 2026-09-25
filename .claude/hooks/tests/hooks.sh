#!/usr/bin/env bash
# Fixture tests for the framework hooks. Run from anywhere: .claude/hooks/tests/hooks.sh
# Each case feeds the JSON Claude Code would send and asserts the exit code (0 allow, 2 block).
#
# Written with the Write tool, not a Bash heredoc: guard-secrets blocks any Bash command
# whose text mentions reading an env file, and this file's fixtures do exactly that.
set -uo pipefail
H="$(cd "$(dirname "$0")/.." && pwd)"
pass=0; fail=0
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
g() { git -C "$T" -c user.email=t@t -c user.name=t "$@"; }
g init -q && g checkout -q -b develop && g commit -q --allow-empty -m init

bash_json() { jq -nc --arg c "$1" '{tool_name:"Bash",tool_input:{command:$c}}'; }
file_json() { jq -nc --arg t "$1" --arg f "$2" '{tool_name:$t,tool_input:{file_path:$f}}'; }
t() {  # t <expect> <hook> <json> <label>
  local want="$1" hook="$2" json="$3" label="$4" got
  printf '%s' "$json" | CLAUDE_PROJECT_DIR="$T" "$H/$hook" >"$T/.out" 2>"$T/.err"; got=$?
  if [ "$got" = "$want" ]; then pass=$((pass+1)); printf '  ok    %-20s %s\n' "$hook" "$label"
  else fail=$((fail+1)); printf '  FAIL  %-20s %s  (want %s got %s) %s\n' "$hook" "$label" "$want" "$got" "$(head -c 140 "$T/.err")"; fi
}
expect_out() {  # expect_out <grep-pattern> <label>   (stdout of the last t call)
  if grep -q "$1" "$T/.out"; then pass=$((pass+1)); printf '  ok    %-20s %s\n' "output" "$2"
  else fail=$((fail+1)); printf '  FAIL  %-20s %s  got: %s\n' "output" "$2" "$(head -c 140 "$T/.out")"; fi
}
expect_silent() {
  if [ ! -s "$T/.out" ]; then pass=$((pass+1)); printf '  ok    %-20s %s\n' "output" "$1"
  else fail=$((fail+1)); printf '  FAIL  %-20s %s  got: %s\n' "output" "$1" "$(head -c 140 "$T/.out")"; fi
}
B=guard-git.sh; M=guard-migrations.sh; S=guard-secrets.sh; C=guard-commit.sh

echo "guard-git on develop"
t 2 $B "$(bash_json 'git commit -m "x"')"            "commit on develop"
t 2 $B "$(bash_json 'git push origin develop')"      "push on develop"
t 0 $B "$(bash_json 'git status')"                   "status on develop"
t 0 $B "$(bash_json 'git checkout -b feature/1-x')"  "branching off develop"

g checkout -q -b feature/1-x
echo "guard-git on a feature branch"
t 0 $B "$(bash_json 'git commit -m "feat(x): y"')"   "commit"
t 0 $B "$(bash_json 'git push origin feature/1-x')"  "push own branch"
t 2 $B "$(bash_json 'git push origin develop')"      "push to develop from elsewhere"
t 2 $B "$(bash_json 'git push origin HEAD:main')"    "push HEAD:main"
t 2 $B "$(bash_json 'git add .')"                    "git add ."
t 2 $B "$(bash_json 'git add -A')"                   "git add -A"
t 2 $B "$(bash_json 'git add --all')"                "git add --all"
t 2 $B "$(bash_json 'git add -v .')"                 "git add -v ."
t 0 $B "$(bash_json 'git add app/Foo.php tests/FooTest.php')" "git add by path"
t 0 $B "$(bash_json 'git add ./app')"                "git add ./dir"
t 0 $B "$(bash_json 'git add .gitignore')"           "git add .gitignore"
t 2 $B "$(bash_json 'git commit -am "x"')"           "commit -am"
t 2 $B "$(bash_json 'git commit -a -m "x"')"         "commit -a -m"
t 0 $B "$(bash_json 'git commit --amend --no-edit')" "commit --amend"
t 2 $B "$(bash_json 'git push --force origin feature/1-x')" "push --force"
t 2 $B "$(bash_json 'git push -f')"                  "push -f"
t 2 $B "$(bash_json 'git push --force-with-lease')"  "push --force-with-lease"
t 2 $B "$(bash_json 'git reset --hard HEAD~1')"      "reset --hard"
t 0 $B "$(bash_json 'git reset --soft HEAD~1')"      "reset --soft"
t 0 $B "$(bash_json 'git reset -q')"                 "reset (unstage)"
t 2 $B "$(bash_json 'git clean -fd')"                "clean -fd"
t 2 $B "$(bash_json 'git clean -f')"                 "clean -f"
t 0 $B "$(bash_json 'git clean -n')"                 "clean -n (dry run)"
t 2 $B "$(bash_json 'git branch -D develop')"        "branch -D develop"
t 0 $B "$(bash_json 'git branch -d feature/2-y')"    "branch -d own"
t 2 $B "$(bash_json 'git checkout -- .')"            "checkout -- ."
t 2 $B "$(bash_json 'git restore .')"                "restore ."
t 0 $B "$(bash_json 'git restore --staged .')"       "restore --staged . (unstage)"
t 0 $B "$(bash_json 'git restore app/Foo.php')"      "restore one path"
t 2 $B "$(bash_json 'rm -rf /tmp/x')"                "rm -rf absolute"
t 2 $B "$(bash_json 'rm -rf ~/x')"                   "rm -rf ~"
t 2 $B "$(bash_json 'rm -rf "$HOME/x"')"             "rm -rf \$HOME quoted"
t 2 $B "$(bash_json 'rm -rf ../other')"              "rm -rf .."
t 2 $B "$(bash_json 'rm -rf .')"                     "rm -rf ."
t 2 $B "$(bash_json 'rm -rf *')"                     "rm -rf *"
t 2 $B "$(bash_json 'sudo rm -r -f /var/x')"         "sudo rm -r -f"
t 2 $B "$(bash_json 'rm --recursive --force /opt')"  "rm --recursive"
t 0 $B "$(bash_json 'rm -rf node_modules')"          "rm -rf inside repo"
t 0 $B "$(bash_json 'rm -rf ./build')"               "rm -rf ./dir"
# The rule is about WHERE the target resolves, not how it is spelled. These three name the
# same directory three ways and must all get the same answer.
t 0 $B "$(bash_json "rm -rf $T/node_modules")"       "rm -rf ABSOLUTE path inside the repo"
t 0 $B "$(bash_json "rm -rf $T/./app/../node_modules")" "rm -rf non-normalised path inside repo"
t 0 $B "$(bash_json 'rm -rf storage/framework/cache')" "rm -rf nested inside repo"
t 0 $B "$(bash_json 'rm -rf does/not/exist/yet')"    "rm -rf path that does not exist yet"
t 2 $B "$(bash_json "rm -rf $T/../outside")"         "rm -rf absolute path escaping via .."
t 0 $B "$(bash_json 'rm -f /tmp/file.log')"          "rm -f single file (not recursive)"
t 0 $B "$(bash_json 'rm storage/logs/laravel.log')"  "rm plain"
t 0 $B "$(bash_json "git commit -F - <<'EOF'
docs(x): y

Never run rm -rf / or rm -rf ~ anywhere.
EOF")"                                                "heredoc body mentioning rm -rf /"
t 2 $B "$(bash_json "cat <<'EOF' > n.txt
x
EOF
rm -rf \"\$HOME/tmp\"")"                              "real quoted rm -rf after heredoc"
t 0 $B "$(bash_json 'echo "do not git add . here"')" "quoted text mentioning git add ."
# _strip.py fails closed: an unterminated heredoc (the `<<` was inside a quoted string) must
# NOT swallow the rest of the command, or every later line goes unguarded.
t 2 $B "$(bash_json 'echo "use <<EOF for heredocs"
git push --force origin x')"                          "unterminated heredoc must not hide a force push"
t 2 $B "$(bash_json 'echo "see <<HERE"
git add .')"                                          "unterminated heredoc must not hide git add ."
t 0 $B "$(bash_json "git commit -F - <<'EOF'
fix(x): y

Never use git add . or git reset --hard here.
EOF")"                                                "heredoc body mentioning forbidden commands"
t 2 $B "$(bash_json "cat <<'EOF' > note.txt
hello
EOF
git add .")"                                          "real git add . after a heredoc terminator"
t 2 $B "$(bash_json 'git commit -m "wip: x" && git push --force')" "force push after a quoted message"

echo "guard-migrations"
mkdir -p "$T/database/backups"
t 2 $M "$(bash_json 'docker compose exec app php artisan migrate:fresh --seed')" "fresh, no dump"
t 2 $M "$(bash_json './vendor/bin/sail artisan migrate:rollback')" "rollback, no dump"
t 2 $M "$(bash_json 'npx prisma migrate reset')"     "prisma reset, no dump"
t 2 $M "$(bash_json 'mysql -e "DROP TABLE users"')"  "DROP TABLE, no dump"
t 2 $M "$(bash_json 'psql -c "truncate table logs"')" "TRUNCATE lowercase, no dump"
t 0 $M "$(bash_json 'php artisan migrate')"          "plain migrate"
t 0 $M "$(bash_json 'php artisan migrate:status')"   "migrate:status"
t 0 $M "$(bash_json 'grep dropdown resources/js/App.vue')" "dropdown is not DROP"
t 0 $M "$(bash_json 'tail truncated.log')"           "truncated is not TRUNCATE"
t 0 $M "$(bash_json "git commit -F - <<'EOF'
feat(hooks): guard migrate:fresh and DROP TABLE
EOF")"                                                "heredoc commit message naming the operations"
t 2 $M "$(bash_json 'docker compose exec -T db mysql -e "DROP TABLE users"')" "quoted DROP TABLE still caught"
touch "$T/database/backups/fresh.sql"
t 0 $M "$(bash_json 'php artisan migrate:fresh')"    "fresh WITH recent dump"
if touch -t "$(date -v-20M +%Y%m%d%H%M 2>/dev/null || date -d '-20 min' +%Y%m%d%H%M)" "$T/database/backups/fresh.sql" 2>/dev/null; then
  t 2 $M "$(bash_json 'php artisan migrate:fresh')"  "fresh, dump 20 min old"
fi
rm -f "$T/database/backups/fresh.sql"

echo "guard-secrets (file tools)"
t 2 $S "$(file_json Read .env)"                      "Read .env"
t 2 $S "$(file_json Read /repo/.env.staging)"        "Read .env.staging"
t 2 $S "$(file_json Read .env-main)"                 "Read .env-main"
t 2 $S "$(file_json Read .env.example-main)"         "Read .env.example-main (stage file)"
t 2 $S "$(file_json Read .env.example)"              "Read .env.example (by design)"
t 2 $S "$(file_json Edit .env.develop)"              "Edit .env.develop"
t 2 $S "$(file_json Write .env)"                     "Write .env"
t 2 $S "$(jq -nc '{tool_name:"Grep",tool_input:{pattern:"PASSWORD",path:".env.main"}}')" "Grep in .env.main"
t 0 $S "$(file_json Read config/app.php)"            "Read config"
t 0 $S "$(file_json Read .envrc)"                    "Read .envrc (direnv, not an env file)"
t 0 $S "$(file_json Read src/environment.ts)"        "Read environment.ts"

echo "guard-secrets (bash)"
t 2 $S "$(bash_json 'cat .env')"                     "cat .env"
t 2 $S "$(bash_json 'cat .env.staging | grep DB_')"  "cat .env.staging"
t 2 $S "$(bash_json 'head -5 .env.local')"           "head .env.local"
t 2 $S "$(bash_json 'grep PASSWORD .env.main')"      "grep in .env.main"
t 2 $S "$(bash_json 'source .env')"                  "source .env"
t 2 $S "$(bash_json '. .env')"                       ". .env"
t 2 $S "$(bash_json 'mysql < .env')"                 "redirect from .env"
t 2 $S "$(bash_json 'cp .env.example .env')"         "cp .env.example .env (humans do setup)"
t 0 $S "$(bash_json 'git add .env.staging')"         "git add env file (staging a human's change: allowed)"
t 0 $S "$(bash_json 'git add -f .env.staging')"      "git add -f env file"
t 0 $S "$(bash_json 'git add .env.staging app/X.php')" "stage env file with code"
t 2 $S "$(bash_json 'git add -p .env.staging')"      "git add -p shows hunks"
t 2 $S "$(bash_json 'git add --patch .env.staging')" "git add --patch"
t 2 $S "$(bash_json 'git add -i .env.staging')"      "git add -i"
t 2 $S "$(bash_json 'git add -e .env.staging')"      "git add -e"
t 2 $S "$(bash_json 'git diff HEAD .env.main')"      "git diff .env.main"
t 2 $S "$(bash_json 'git show HEAD:.env.staging')"   "git show .env.staging"
t 2 $S "$(bash_json 'git show origin/develop:.env.main')" "git show remote:.env.main"
t 2 $S "$(bash_json 'cat .env.staging,.env.main')"   "comma-separated env paths"
t 2 $S "$(bash_json "python3 -c \"print(open('.env').read())\"")" "python reads .env"
t 0 $S "$(bash_json 'ls -la')"                       "ls -la"
t 0 $S "$(bash_json 'ls .env*')"                     "ls .env* (names only)"
t 0 $S "$(bash_json 'git status')"                   "git status"
t 0 $S "$(bash_json 'git diff --name-only')"         "git diff --name-only"
t 0 $S "$(bash_json 'docker compose --env-file .env.staging up -d')" "docker --env-file (not printed)"
t 0 $S "$(bash_json 'php artisan config:cache')"     "config:cache"
t 0 $S "$(bash_json 'echo $DB_HOST')"                "echo a var"
t 0 $S "$(bash_json 'grep -rn "env(" config/')"      "grep for env( in config"
t 0 $S "$(bash_json 'git commit -m "x"')"            "commit, nothing env staged"
touch "$T/.env.staging"; g add -f .env.staging
t 0 $S "$(bash_json 'git commit -m "x"')"            "commit with env file staged (allowed)"
t 2 $S "$(bash_json 'git diff --cached')"            "but diff --cached of it is refused"
g reset -q

echo "guard-commit (subject format)"
t 0 $C "$(bash_json 'git commit -m "feat(x): add y"')"      "feat(scope): ok"
t 0 $C "$(bash_json 'git commit -m "fix: y"')"              "fix: no scope ok"
t 0 $C "$(bash_json 'git commit -m "chore(release): 1.2.0"')" "chore(release) ok"
t 0 $C "$(bash_json 'git commit -m "wip(x): state"')"       "wip ok"
t 0 $C "$(bash_json "git commit -m 'refactor(a-b)!: breaking'")" "breaking marker ok"
t 2 $C "$(bash_json 'git commit -m "Fixed the thing"')"     "no type"
t 2 $C "$(bash_json 'git commit -m "#31 fix(x): y"')"       "issue number in subject"
t 2 $C "$(bash_json 'git commit -m "feature(x): y"')"       "wrong type"
t 0 $C "$(bash_json 'git commit -F -')"                     "-F (unchecked by design)"
t 0 $C "$(bash_json 'git commit --amend --no-edit')"        "amend"

echo "guard-commit (docs-travel advisory on push)"
mkdir -p "$T/app"; : > "$T/app/X.php"; g add app/X.php; g commit -q -m "feat(x): y"
t 0 $C "$(bash_json 'git push origin feature/1-x')"         "push, code without changelog -> allowed"
expect_out 'CHANGELOG' "advisory emitted"
mkdir -p "$T/.docs"; printf '## [Unreleased]\n- x\n' > "$T/.docs/CHANGELOG.md"; g add .docs/CHANGELOG.md; g commit -q -m "docs(x): changelog"
t 0 $C "$(bash_json 'git push origin feature/1-x')"         "push, code with changelog"
expect_silent "no advisory when changelog travels"

echo "guard-secrets (history: committed env files)"
: > "$T/.env.staging"; g add -f .env.staging; g commit -q -m "chore(env): staging"
t 2 $S "$(bash_json 'git show')"                     "git show, HEAD touched an env file"
t 2 $S "$(bash_json 'git show HEAD')"                "git show HEAD"
t 2 $S "$(bash_json 'git log -p -n 2')"              "git log -p over an env commit"
t 2 $S "$(bash_json 'git diff HEAD~1')"              "git diff across an env commit"
t 0 $S "$(bash_json 'git show --stat')"              "git show --stat (names only)"
t 0 $S "$(bash_json 'git show --name-only')"         "git show --name-only"
t 0 $S "$(bash_json 'git show -s')"                  "git show -s (no patch)"
t 0 $S "$(bash_json 'git log --oneline -n 5')"       "git log --oneline"
t 0 $S "$(bash_json 'git log -n 3')"                 "git log without -p"
t 0 $S "$(bash_json 'git diff --name-only HEAD~1')"  "git diff --name-only"
: > "$T/app/Y.php"; g add app/Y.php; g commit -q -m "feat(y): z"
t 0 $S "$(bash_json 'git show')"                     "git show, HEAD is code"
t 0 $S "$(bash_json 'git diff HEAD~1')"              "git diff over a code-only commit"
t 2 $S "$(bash_json 'git show HEAD~1')"              "git show HEAD~1 (the env commit)"
t 2 $S "$(bash_json 'git log -p -n 5')"              "git log -p reaching the env commit"
printf 'X=1\n' >> "$T/.env.staging"
t 2 $S "$(bash_json 'git diff')"                     "git diff, env file modified in tree"
g add -f .env.staging
t 2 $S "$(bash_json 'git diff --cached')"            "git diff --cached, env staged"
g reset -q; g checkout -q -- .env.staging
t 2 $S "$(bash_json 'git show $(git rev-parse HEAD~1)')" "substitution in ref: cannot verify"
t 0 $S "$(bash_json "git commit -F - <<'EOF'
fix(hooks): refuse git show and git diff over committed environment files
EOF")"                                                "heredoc message naming history commands"

echo "check-framework-root"
mkdir -p "$T/root/src/repo"; printf '@AGENTS.md\n' > "$T/root/CLAUDE.md"; : > "$T/root/AGENTS.md"
printf '# repo\n**Verified:** 2025-01-01\n## Tool Execution Safety (TEMPORARY – Oct 2025)\n' > "$T/root/src/repo/CLAUDE.md"
out="$(echo '{}' | CLAUDE_PROJECT_DIR="$T/root/src/repo" "$H/check-framework-root.sh")"
printf '%s' "$out" | grep -q 'last verified 2025-01-01' && { pass=$((pass+1)); echo "  ok    stale Verified flagged"; } || { fail=$((fail+1)); echo "  FAIL  stale Verified: $out"; }
printf '%s' "$out" | grep -q 'TEMPORARY section' && { pass=$((pass+1)); echo "  ok    TEMPORARY flagged"; } || { fail=$((fail+1)); echo "  FAIL  TEMPORARY: $out"; }
printf '%s' "$out" | grep -q 'NOT loaded' && { fail=$((fail+1)); echo "  FAIL  false 'not loaded' under a framework root"; } || { pass=$((pass+1)); echo "  ok    protocol found via ancestor"; }
out="$(echo '{}' | CLAUDE_PROJECT_DIR="$T" "$H/check-framework-root.sh")"
printf '%s' "$out" | grep -q 'NOT loaded' && { pass=$((pass+1)); echo "  ok    'not loaded' outside a framework root"; } || { fail=$((fail+1)); echo "  FAIL  missing 'not loaded': $out"; }
out="$(echo '{}' | CLAUDE_PROJECT_DIR="$H/.." "$H/check-framework-root.sh")"
[ -z "$out" ] && { pass=$((pass+1)); echo "  ok    silent at the framework root itself"; } || { fail=$((fail+1)); echo "  FAIL  noisy at framework root: $out"; }

echo "lint-on-edit"
out="$(file_json Edit "$T/resources/js/App.vue" | CLAUDE_PROJECT_DIR="$T" "$H/lint-on-edit.sh")"
printf '%s' "$out" | grep -q 'Frontend source changed' && printf '%s' "$out" | jq -e .hookSpecificOutput.additionalContext >/dev/null && { pass=$((pass+1)); echo "  ok    frontend reminder as JSON additionalContext"; } || { fail=$((fail+1)); echo "  FAIL  frontend reminder: $out"; }
out="$(file_json Edit "$T/app/Foo.php" | CLAUDE_PROJECT_DIR="$T" "$H/lint-on-edit.sh")"
[ -z "$out" ] && { pass=$((pass+1)); echo "  ok    silent for backend file with no linter installed"; } || { fail=$((fail+1)); echo "  FAIL  unexpected output: $out"; }

echo; printf '%d passed, %d failed\n' "$pass" "$fail"; [ "$fail" -eq 0 ]
