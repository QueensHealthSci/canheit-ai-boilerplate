# Shared documentation

Content shared across every repo under the framework root. `scripts/sync-repo.sh <repo>` installs the
parts a repo needs — you do not copy these by hand.

| Entry | Purpose | How it reaches a repo |
| --- | --- | --- |
| `TEMPLATE_AGENT.md` | Copy into a repo root as `CLAUDE.md` and fill in. Configuration only — commands, exec prefix, schema lineage, ports, traps, locked decisions. Budget 100 lines. | by hand, once |
| `TEMPLATE_PLAN.md` | Copy to `.docs/plans/<issue>-<slug>.md` at the start of a Standard or Large task. | by hand, per task |
| `TEMPLATE_DESIGN.md` | Copy to `.docs/design/<issue>-<slug>.md` for a Large task, before the plan. ADR shape: context, decision, consequences. | by hand, per task |
| `TEMPLATE_CHANGELOG.md` | The `.docs/CHANGELOG.md` format. Keep a Changelog, append-only, never read whole. | scaffolded by `sync-repo.sh` |
| `TEMPLATE_LEARNINGS_INDEX.md` | The `.docs/learnings/README.md` index: the six domains, the entry format and the promotion rule. | scaffolded by `sync-repo.sh` |
| `TEMPLATE_TEST_LEDGER.md` | The `.docs/TEST_LEDGER.md` format for pre-existing failures. | scaffolded by `sync-repo.sh` |
| `DOCS_LAYOUT.md` | What `.docs/` holds and why, for every repo. | reference |
| `bin/` | `check` and `doctor`. `check` detects the test runner, the container prefix and the coverage driver rather than carrying a hand-written command. | linked by `sync-repo.sh` |
| `e2e/` | Playwright config, global setup and a smoke spec, scaffolded into repos that have a UI and no Playwright yet. | scaffolded by `sync-repo.sh` |
| `linters/` | `pint.json`, `phpstan.neon`, `eslint.framework.mjs` and an `AppServiceProvider` snippet. | linked by `sync-repo.sh`, by stack |

Which repo gets what is decided by `scripts/_detect.sh`, from the repo's own contents — no
script knows any repo by name. `scripts/check-framework.sh` reports what is missing,
overridden, or linked to nothing.

The development protocol itself is `../AGENTS.md`. It loads automatically into every session
started under the framework root, through its `CLAUDE.md`. Repo files must not import it.
