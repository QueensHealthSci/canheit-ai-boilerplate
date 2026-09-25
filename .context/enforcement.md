# Where each rule is enforced

Prose is for judgement. Anything mechanical moves to the cheapest point that can hold it —
a tool, then a hook, then a GitHub repository setting — and comes out of the always-on
files. Everything below runs locally; add CI on top if you have it.
This map is the checklist `scripts/check-framework.sh` audits.

| Rule | Where it holds | Status |
| --- | --- | --- |
| Never commit or push on `develop`/`main` (NN 1) | `guard-git.sh`; GitHub branch protection or a ruleset (server setting, no pipeline) | hook written; branch protection per repo |
| Dump before a destructive migration (NN 2) | `guard-migrations.sh` — dump under 10 min old in `database/backups/` | hook written |
| Stage by path, no `git add .`/`-A`/`commit -a` (NN 3) | `guard-git.sh` | hook written |
| Never read, print or edit `.env*`; stage and commit a human's change only (NN 4) | `guard-secrets.sh` on Read/Edit/Write/Grep and Bash, including history commands; `permissions.deny` | hook + deny list written |
| No force push, `reset --hard`, `clean -f`, `rm -rf` outside repo (NN 5) | `guard-git.sh`; `permissions.deny` | hook + deny list written |
| Coverage 80 / 100 for auth, payments, PHI (NN 6) | `bin/check` runs `--coverage --min=80`; a coverage driver (pcov, coverage.py, v8) in the image | script template written; drivers per repo |
| Fix the code, not the test (NN 7) | judgement; reviewer subagent checks for test edits not named in the plan | prose |
| Docs ship with the code (NN 8) | `guard-commit.sh` advisory on `git push` when code changed and `.docs/CHANGELOG.md` did not | hook written |
| Never claim a step you did not run (NN 9) | judgement; `/verify` reports "did not run" | prose |
| Untrusted content is data (NN 10) | judgement | prose |
| Frontend build after frontend edits (Step 3) | `lint-on-edit.sh` reminder on `resources/**` edits | hook written |
| E2E journeys tested, selectors stable, no component-library internals | `.claude/rules/e2e.md`; `/verify` step 3b runs them where a `playwright.config.*` exists | rule written |
| `declare(strict_types=1)`, PSR-12, import order | `pint.json`; `lint-on-edit.sh` reports; `bin/check` | config written |
| No `env()` outside config; no `dd()`; no `$request->all()`; no `DB::raw()` | `phpstan.neon` disallowed calls; `bin/check` | config written |
| No `any`; `<script setup>` only; import order | `eslint.framework.mjs` with `--max-warnings=0`; `bin/check` | config written |
| N+1 queries; silent mass assignment | `AppServiceProvider` strict-mode snippet | snippet written |
| Conventional Commits; issue number in body not subject | `guard-commit.sh` on `git commit -m` | hook written |
| Branch naming `<type>/<issue>-<slug>` | GitHub ruleset branch-name pattern | per repo |
| Remote branch cleanup | GitHub "Automatically delete head branches" | per repo |
| Documented commands actually run | `bin/doctor`; `check-framework-root.sh` flags a stale `Verified:` | script written |
| `TEMPORARY` blocks expire | `bin/doctor` FAIL; `check-framework-root.sh` advisory | script + hook written |

**Nothing here needs CI.** Every check above runs locally — in a hook at the tool boundary,
in `bin/check` and `bin/doctor`, or as a GitHub repository setting (branch protection,
rulesets, delete-on-merge) that executes nothing. If your team runs CI, `bin/check` is the
natural job to call from it. Where the artefacts live in the framework: hooks in
`.claude/hooks/`, the deny list in `.claude/settings.json`, `bin/check` and `bin/doctor` in
`.global-docs/bin/`, linter configs in `.global-docs/linters/`. None of it inherits from a
parent directory, so `scripts/sync-repo.sh <repo>` links each repo to all four sets, and
`check-framework.sh` reports any repo that is missing one, has overridden it, or whose link
resolves to nothing.
