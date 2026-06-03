# src/

Each subdirectory here is an independent **project repository**. In a real setup these are
typically separate git repositories (e.g. git submodules or checked-out side by side); this
boilerplate keeps one example in-tree so the structure is easy to see.

Every project in `src/` must contain its own **repo-level agent file** (`CLAUDE.md`,
`GEMINI.md`, `.cursorrules`, etc.) that inherits from the global `../AGENT.md` and fills in
the technology-specific details (test commands, container setup, debug patterns). Start from
`../.global-docs/TEMPLATE_AGENT.md`.

| Project | Stack | Notes |
|---------|-------|-------|
| `example-site/` | Python · Flask · SQLite · pytest | A minimal task tracker demonstrating the conventions. |
| `example-api/` | Node · TypeScript · Express · Vitest | The same task tracker in a different stack — compare the two side by side. |

## Adding a new project

1. Create the project directory under `src/`.
2. Copy `../.global-docs/TEMPLATE_AGENT.md` into it and rename it for your agent.
3. Fill in every section of the agent file.
4. Create a `.docs/` folder with `CHANGELOG.md`, `LEARNINGS.md`, and `project-plans/`.
5. Follow the workflow in `../.context/development_cycle.md`.
