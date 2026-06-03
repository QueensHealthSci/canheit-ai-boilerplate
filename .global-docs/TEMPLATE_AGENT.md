# {REPO NAME} - Agent Configuration

> **How to use this template**
> Copy this file into your repo root and rename it to match your agent:
> - `CLAUDE.md` (for Claude Code / Claude CLI)
> - `GEMINI.md` (for Gemini)
> - `.cursorrules` (for Cursor)
> - Or any other agent-specific filename
>
> Fill in ALL sections below. Do not remove any sections — mark as `N/A` if not applicable.

## INHERITANCE
Global Protocol: ../../AGENT.md
This file extends the CLI Development Protocol. All global rules and workflow
steps defined in AGENT.md apply without exception. Do not deviate from AGENT.md
unless explicitly noted in REPO-SPECIFIC RULES below.

## ROLE OVERRIDE
Role: [e.g., Senior PHP and Laravel 11 Developer | Senior TypeScript and Vue 3 Developer | Senior Python Developer]

## CONTAINER ENVIRONMENT
Type: [Laravel Sail | Docker Compose | Podman | None]
Exec Prefix: [./vendor/bin/sail | docker compose exec <service> | none]
Example: [e.g., ./vendor/bin/sail artisan migrate]

## FRONTEND BUILD
Source Directory: [resources/ | src/ | pages/ | app/ | components/ | N/A]
Build Command: [npm run build | yarn build | pnpm build | N/A]
Dev Server: [npm run dev | yarn dev | N/A]
Trigger Rule: [e.g., If any file in resources/ is modified, append `npm run build`]

## TESTING
Framework: [Pest PHP | PHPUnit | Vitest | Jest | Pytest | Go test]
Feature Test Command: [e.g., php artisan test --filter YourTest --coverage]
Full Suite Command: [e.g., php artisan test --coverage]
Filter Flag: [--filter | --testNamePattern | -k | -run]

## DEBUG STATEMENTS TO CHECK
Patterns: [e.g., dd() | dump() | console.log | print() | pdb.set_trace() | debugger]

## CODING STANDARDS
Reference: [e.g., ../../.context/rules/coding_standards.md]
Additional Standards: [any repo-specific standards — or N/A]

## REPO-SPECIFIC RULES (OPTIONAL)
Add any rules unique to this repository that do not conflict with AGENT.md.

> These MUST NOT conflict with AGENT.md. Examples:
> - "All API responses must use JsonResource classes"
> - "Database migrations must include a rollback method"
> - "All Vue components must use Composition API with `<script setup>`"
