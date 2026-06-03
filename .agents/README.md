# Agent Instruction Library

A library of focused, reusable agent instruction files. Each file defines a **specialist
persona** with a tight set of standards for one area of the stack. They are intentionally
small so they can be composed: a repo imports only the specialists it needs.

## How to use

Reference a specialist from a repo-level agent file (e.g. `src/{REPO}/CLAUDE.md`) or pull
the relevant rules in when working on that part of the codebase. For example, a Laravel +
Vue project would lean on `architect`, `laravel`, `vue3`, `security`, `dba`, and `testing`.

| Specialist | Focus |
|------------|-------|
| `architect.md`        | Architectural boundaries, layering, separation of concerns. |
| `security.md`         | AuthN/AuthZ, input validation, data isolation. |
| `dba.md`              | Schema design, query optimization, migrations. |
| `testing.md`          | Test quality, coverage thresholds, test structure. |
| `laravel.md`          | Laravel conventions (modern PHP stack). |
| `vue3.md`             | Vue 3 + TypeScript + component standards. |
| `python.md`           | Python services, data pipelines, packaging. |
| `legacy-php.md`       | Maintaining/extending non-framework legacy PHP. |
| `frontend-legacy.md`  | jQuery / Bootstrap / DataTables frontends. |
| `playwright.md`       | End-to-end browser testing. |

> These are **examples**. Add, remove, or rewrite specialists to match your own stack.
