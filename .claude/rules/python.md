---
paths:
  - "**/*.py"
  - "etl/**"
  - "requirements*.txt"
---
# Python, ETL and models — house rules

## ETL

- **Idempotent.** Re-running a job produces the same result. "Already present" is the normal
  case, not an error — this lesson has been relearned in five repos across two languages.
- Chunk large extracts; one bad record must not abort the batch.
- Log each stage with counts: extracted, transformed, loaded, skipped, failed. A run that
  logs only "done" cannot be debugged later.
- Record run metadata: start, end, rows processed, errors.

## Data warehouse schema

Facts hold measures and dimension foreign keys only; dimensions hold descriptive attributes;
lookups hold static reference data. Surrogate keys in dimensions, natural keys in lookups.
Date dimensions are pre-populated for the whole reporting range.

`migrate:fresh` drops tables but **not views** — views (row-level-security views included) that
live outside the migration system must be recreated by hand. If role lists are defined in
more than one place, a new role means changing every one — record where in the repo's TRAPS.

## Data handling

Timezone-aware datetimes, normalized to UTC on storage. Declare the strategy for NULLs
explicitly — skip, default or flag — and write it in the docstring. Deduplicate before load
using a natural key or hash.

## Models

Pin model versions exactly; never `latest`. Cache downloads locally so a run does not
re-fetch. Record why a model was chosen — a model switched twice with the reasoning
written down neither time is a common loss. Keep inference and training scripts apart.

## Environment and dependencies

`venv` or `conda`, never a global install. Exact pins in `requirements.txt`, dev
dependencies separate. State the Python version.

## Not repeated here

PEP 8 naming, type hints and docstring presence belong to `ruff` or `flake8` once
configured. This file carries the ETL and data-warehouse judgement calls only.
