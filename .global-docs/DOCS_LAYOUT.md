# The `.docs/` layout

Every repo keeps its project artefacts in `.docs/`. One name, so the skills, the hooks and
`check-framework.sh` can use one path everywhere.

```
.docs/
├── README.md            # what is in here, one line per entry
├── CHANGELOG.md         # Keep a Changelog; [Unreleased] first; one line per change
├── TEST_LEDGER.md       # pre-existing failures (TEMPLATE_TEST_LEDGER)
├── ARCHITECTURE.md      # the narrative moved out of CLAUDE.md
├── learnings/           # split by domain — the standard
│   ├── README.md        # the index: which domain covers what (TEMPLATE_LEARNINGS_INDEX)
│   ├── backend_learnings.md      # created when it gets its first entry, not before
│   ├── database_learnings.md
│   ├── docker_learnings.md
│   ├── frontend_learnings.md
│   ├── process_learnings.md
│   ├── security_learnings.md
│   └── archive/         # never promoted, older than a year
├── plans/               # <issue>-<slug>.md, from TEMPLATE_PLAN
│   └── archive/         # merged and older than six months
├── design/              # <issue>-<slug>.md ADRs, from TEMPLATE_DESIGN
└── prompts/             # reusable prompts (optional)
```

**There is no `.docs/LEARNINGS.md`.** Learnings are split by domain in every repo, not only
large ones, and the monolith is removed rather than left as a pointer — a file that exists
gets read, and a pointer is one more hop for every session to pay. A session opens the one
domain that matches the work; `learnings/README.md` says which that is. A single file means
reading everything or trusting that "the relevant section" was found: a mature monolith
easily reaches ~96,000 tokens, with single entries thousands of characters wide.

## Why `.docs/` and not `.context/`

`.context/` at the framework root means *framework rules*. A repo that uses the same name
for *project artefacts* makes the word mean two things depending on where you are standing.
`.docs/` is the convention; a repo with a project `.context/` should rename it to match
(`/onboard-repo` step 6).

## Rules

- **No master `PLAN.md` maintained by hand.** An index of plans drifts the moment someone
  forgets it, and the plan files already carry their own `Status:`. `check-framework.sh
  --plans <repo>` prints the index from the files themselves. One repo's `PLAN.md` preamble
  currently reads "do not trust the checkboxes", which is the argument in one line.
- **Plans and design docs are permanent.** They stay after the work ships. A plan marked
  `Superseded by #NN` is how the next person knows a question was settled — deleting it
  invites the argument again.
- **Archive after six months**, merged plans only, to `plans/archive/`. Design docs are not
  archived: an ADR's whole value is being findable years later.
- **The changelog is append-only during a task.** Add a line under `## [Unreleased]`. Never
  read the whole file — they run to 250 KB here, which is more context than most tasks
  deserve. `/release cut` rolls the block into a version.
- **`ARCHITECTURE.md` holds the narrative** — request flow, module map, what tests mock and
  why. It is needed at plan time, not on every turn, which is why it is not in `CLAUDE.md`.

## Which template

| File | Template |
| --- | --- |
| `learnings/README.md` | `.global-docs/TEMPLATE_LEARNINGS_INDEX.md` |
| `TEST_LEDGER.md` | `.global-docs/TEMPLATE_TEST_LEDGER.md` |
| `plans/<issue>-<slug>.md` | `.global-docs/TEMPLATE_PLAN.md` |
| `design/<issue>-<slug>.md` | `.global-docs/TEMPLATE_DESIGN.md` |
| `CHANGELOG.md` | [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) |
