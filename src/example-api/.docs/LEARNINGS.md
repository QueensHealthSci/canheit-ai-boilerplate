# Learnings

Technical patterns, gotchas, and lessons learned while building the Example API (TaskFlow).
This is the **project-specific** memory referenced by `AGENT.md` (Section 0, item 4). 

## NodeNext Module Resolution
- With `"module": "NodeNext"`, relative imports must include the `.js` extension **even in
  `.ts` source** (e.g. `import { getDb } from './db.js'`). TypeScript rewrites nothing — the
  extension refers to the compiled output. Omitting it fails at runtime.

## TypeScript Strict + `noUncheckedIndexedAccess`
- `noUncheckedIndexedAccess` makes indexed access (`arr[0]`, `params.id`) possibly `undefined`.
  Narrow with a guard before use, or destructure with a default — don't reach for `!` or `any`.
- Express route params (`req.params.id`) are typed `string | undefined` under this flag; validate
  and parse them in the handler before passing to a service.

## better-sqlite3 is Synchronous
- Queries are blocking/synchronous — no `await`. This keeps the service layer simple and makes
  tests fast and deterministic. Use prepared statements (`db.prepare(...)`) with `?` placeholders.
- For tests, open the database with `:memory:` so each suite gets an isolated, disposable DB.

## SQLite WAL Mode
- `PRAGMA journal_mode = WAL` is set once when the connection opens, allowing the dashboard to
  read while a write is in progress.

## Soft Deletes
- Tasks use a nullable `deleted_date` integer (Unix timestamp). Never hard-delete a task.
- Default list/get queries add `deleted_date IS NULL`. `DELETE /api/tasks/:id` sets the timestamp
  and returns the (now hidden) task body, because the row still exists.

## Validation Lives in Services
- `src/services.ts` raises `ValidationError`; the error handler in `src/app.ts` translates it to a
  `400` JSON response. This keeps route handlers thin and lets services be unit-tested without HTTP.
