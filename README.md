# AI Development Boilerplate

A starter template for setting up **AI-assisted development** with a clear, enforceable
workflow. It gives an AI coding agent (Claude Code, Gemini CLI, Cursor, etc.) the context it
needs to behave like a disciplined senior developer: plan before coding, branch correctly,
write tests, update documentation, and never commit straight to the main branch.

> This is a teaching example used for a presentation on AI development. Everything here is
> generic — fork it, rename it, and adapt it to your own stack and team conventions.

## The idea

Instead of re-explaining your standards to the AI in every session, you keep them in version
control as a small set of layered context files:

- A **global protocol** that defines the workflow and non-negotiable rules.
- A **library of specialist personas** you can pull in per task.
- **Shared reference docs** for your coding standards, dev cycle, and Docker setup.
- A **per-project agent file** that fills in the technology-specific details.
- **Per-project memory** (`.docs/`) so lessons learned persist across sessions.

## Structure

```
.
├── CLAUDE.md                    # Root ENTRY POINT — auto-loaded by the AI tool; imports AGENT.md
├── AGENT.md                     # GLOBAL protocol: workflow + mandatory rules (the spine)
├── .agents/                     # Library of specialist personas (architect, security, …)
│   ├── README.md
│   ├── architect.md  security.md  dba.md  testing.md
│   ├── laravel.md  vue3.md  python.md
│   ├── legacy-php.md  frontend-legacy.md  playwright.md
├── .global-docs/                # Shared templates + cross-project memory
│   ├── README.md
│   ├── TEMPLATE_AGENT.md        # Starting point for a repo-level agent file
│   └── TEMPLATE_PLAN.md         # Per-feature planning template
├── .context/                    # Reference docs the agent indexes on every request
│   ├── development_cycle.md     # The 9-step Issue → PR → cleanup workflow
│   ├── docker_setup.md          # Laravel Sail / multi-project port management
│   ├── docker_setup_php.md      # Native PHP Docker setup
│   └── rules/
│       └── coding_standards.md  # PHP/Laravel, Vue/TS, and Python standards
└── src/                         # Project repositories (one folder per project)
    ├── README.md
    ├── example-site/            # Example #1 — Python · Flask · SQLite · pytest (TaskFlow)
    │   ├── CLAUDE.md            # Repo-level agent file (inherits ../../AGENT.md)
    │   ├── README.md
    │   ├── .docs/               # Project memory: CHANGELOG, LEARNINGS, plans
    │   ├── app/                 # Application source
    │   └── tests/               # pytest suite
    └── example-api/             # Example #2 — Node · TypeScript · Express · Vitest (same TaskFlow)
        ├── CLAUDE.md            # Repo-level agent file (inherits ../../AGENT.md)
        ├── README.md
        ├── .docs/               # Project memory: CHANGELOG, LEARNINGS, plans
        ├── src/                 # Application source
        └── tests/               # Vitest suite
```

> **Two examples, one domain.** `example-site` (Python) and `example-api` (TypeScript)
> implement the **same** task-tracker domain in different stacks — so you can follow along in
> whichever language is closest to your own and compare how the standards map across both.

## How the layers fit together

0. **`CLAUDE.md` (root) is the entry point.** AI tools auto-load a file named for the tool at
   the repo root. This one contains a single `@AGENT.md` import, so opening the repo
   immediately loads the protocol. (Using a different tool? Copy it to `GEMINI.md`,
   `AGENTS.md`, etc. — see Quickstart.)
1. **`AGENT.md` is the spine.** It defines a 9-step development cycle and a set of always-on
   rules (tests mandatory, >80% coverage, never commit to `develop`/`main`, document as you
   go). It contains placeholders for anything technology-specific.
2. **A repo-level agent file** (e.g. `src/example-site/CLAUDE.md`) inherits from `AGENT.md`
   and fills in those placeholders — the role, container commands, test commands, debug
   patterns, and any repo-specific rules.
3. **`.context/` docs** are indexed on every request so the agent applies your real coding
   standards and dev workflow rather than generic defaults.
4. **`.agents/` specialists** are small, composable personas you reference when working on a
   particular slice of the stack.
5. **`.docs/LEARNINGS.md`** (per project) act as
   long-term memory, so gotchas don't have to be rediscovered.

## Quickstart

There are two ways to use this, depending on what you copied.

### Mode A — Clone the whole workspace and try it as-is

```bash
git clone <your-fork> taskflow-workspace
cd taskflow-workspace
claude            # or: open the folder in your AI tool of choice
```

Because the root `CLAUDE.md` imports `AGENT.md`, the agent loads the full protocol on the
first turn. Ask it to build a feature and it will follow the workflow (plan → branch → code →
test → review → commit). The two `src/` projects are ready to run (see "Try the examples").

### Mode B — Drop the setup into your own existing project

Copy these four things into the root of your repo and you have the same headstart:

```bash
cp -R taskflow-workspace/AGENT.md \
      taskflow-workspace/.agents \
      taskflow-workspace/.context \
      taskflow-workspace/.global-docs \
      your-project/

# Create the entry point your AI tool auto-loads (Claude Code shown):
cp taskflow-workspace/.global-docs/TEMPLATE_AGENT.md your-project/CLAUDE.md
# ...then fill in CLAUDE.md with your stack's role, container, test, and debug details.
```

If your tool isn't Claude Code, name the entry-point file accordingly: `GEMINI.md` (Gemini),
`AGENTS.md` (many tools), or your tool's convention. The content is identical — a short header
plus `@AGENT.md`.

### Then tailor it to your team

1. Read `AGENT.md` — it is the contract the agent follows. Adjust any rules you disagree with.
2. Edit `.context/rules/coding_standards.md` and `.context/development_cycle.md` for your stack
   and host (this example uses GitHub + a `develop` branch — swap for GitLab/Bitbucket freely).
3. Trim `.agents/` to the specialists your stack actually uses; add your own.
4. Start a `.docs/` folder in each project (`CHANGELOG.md`, `LEARNINGS.md`, `project-plans/`).

> **What "copy-paste headstart" really gives you:** the agent stops improvising. It plans
> before coding, branches correctly, writes tests to a coverage bar, keeps a changelog and
> learnings file, and refuses to commit straight to `develop`/`main` — because all of that is
> written down in files it loads automatically, not re-typed into a chat each session.

## Try the examples

Both examples implement the same TaskFlow domain — pick the one closest to your stack.

**Example #1 — Python / Flask**
```bash
cd src/example-site
python -m venv venv && source venv/bin/activate
pip install -r requirements.txt
flask --app app init-db
flask --app app run        # http://127.0.0.1:5000
pytest --cov=app           # run the tests
```

**Example #2 — Node / TypeScript / Express**
```bash
cd src/example-api
npm install
npm run dev                # http://localhost:8000
npm test                   # run the tests with coverage
```

See each project's `README.md` for the full API and Docker instructions.

## Customizing

Nothing here is sacred — it's a starting point:

- **Different host?** Swap the GitHub references in `development_cycle.md` for GitLab/Bitbucket.
- **Different stack?** Replace the specialists in `.agents/` and the standards in `.context/`.
- **Different branch model?** Adjust the branching steps in `AGENT.md` and `development_cycle.md`.

## License

Provided as an educational example. Use it freely.
