# Example Site (TaskFlow) — Agent Configuration

## INHERITANCE
Global Protocol: ../../AGENT.md
This file extends the CLI Development Protocol. All global rules and workflow
steps apply. Do not deviate from AGENT.md unless explicitly noted below.

## ROLE OVERRIDE
Role: Senior Python Developer

## CONTAINER ENVIRONMENT
Type: Docker Compose
Exec Prefix: docker compose exec app
Example: docker compose exec app pytest

## FRONTEND BUILD
Source Directory: N/A (Jinja2 templates, no build step)
Build Command: N/A
Dev Server: N/A

## TESTING
Framework: pytest
Feature Test Command: docker compose exec app pytest tests/test_routes.py --cov=app
Full Suite Command: docker compose exec app pytest --cov=app
Filter Flag: -k

## DEBUG STATEMENTS TO CHECK
Patterns: print() | breakpoint() | pdb.set_trace() | import pdb

## CODING STANDARDS
Reference: ../../.context/rules/coding_standards.md (see the Python Standards section)
Additional Standards: See the `.agents/python.md` specialist for ETL/service conventions.

## REPO-SPECIFIC RULES
- All SQL must use parameterized `?` placeholders — never string interpolation.
- Tasks are soft-deleted via a nullable `deleted_date` integer column — never hard-delete.
- SQLite runs in WAL mode (`PRAGMA journal_mode=WAL`) for concurrent read/write.
- All configuration comes from environment variables (`TASKFLOW_DB`, `APP_PORT`) — no secrets in code.
- Validation lives in `app/services.py` and raises `ValidationError`; routes translate it to a 400 JSON response.
- Run with a single Gunicorn worker (`--threads 2`) so there is one process owning the SQLite file.
