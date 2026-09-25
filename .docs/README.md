# `.docs/` — framework root

The framework's own project artefacts. The layout every repo follows is
`.global-docs/DOCS_LAYOUT.md`.

| Entry | What |
| --- | --- |
| `learnings/` | Lessons that will recur, split by domain. Index and format: `learnings/README.md`. |
| `design/` | ADRs. Permanent, never archived. |
| `CHANGELOG.md` | Framework changes, from `.global-docs/TEMPLATE_CHANGELOG.md`. Append only. |

`TEST_LEDGER.md` is absent because the only suite here is
`.claude/hooks/tests/hooks.sh`, which has no pre-existing failures.
