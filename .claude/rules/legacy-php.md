---
paths:
  - "www-root/**"
  - "**/*.inc.php"
---
# Legacy PHP — house rules

## Use the database layer the code already uses

A rule like "legacy applications MUST use PDO" is wrong for a codebase built on a database
abstraction library (ADOdb, a home-grown wrapper). Follow the code, not the sentence:

- Parameterize through the layer's own binding or quoting. Never concatenate a raw value
  into SQL.
- Check every result for the layer's failure value (often `false`) before using it; many
  older layers return rather than throw.
- Transactions through the layer's own begin / commit / rollback calls.
- If `$db` is a global connection object, use it. Do not open a second one.

## Input and ACL

- `clean_input()` on every user-supplied value, with the right flags for the target context.
- Permissions through the application's ACL object (e.g. `$acl->isAllowed($resource, $action)`),
  checked in the `.inc.php` controller — a check in the template only is not a check.
- Never trust `$_GET`, `$_POST` or `$_REQUEST` unsanitized.
- Escape output for where it lands (HTML, attribute, JS) — Smarty or raw-PHP templates do
  not do it for you.
- Sessions stored through the database layer are used through it, never `session_*()`
  directly. CAS and LDAP go through the application's auth classes, never around them.

## Module structure

A typical shape: entry points `www-root/index.php` and `admin.php`; modules under
`www-root/core/modules/{public,admin}/<module>/`; each section an `.inc.php` file
(`index`, `add`, `edit`, `delete`, `api-*`); models under a PSR-0 library directory.
The repo's `CLAUDE.md` MAP section records the real one.

Match the existing pattern exactly. A new architectural pattern in a legacy module is a
maintenance cost nobody asked for.

## Globals are expected

`$db`, the current user and the ACL object are often globals by design. Do not refactor them away.
Do not introduce Composer autoloading where it does not already exist, and do not add
`declare(strict_types=1)` to a file whose surrounding code is untyped.

## Frontend

jQuery, jQuery UI and DataTables — the established stack. No modern framework goes into a
legacy module. AJAX endpoints are `api-*.inc.php` returning JSON, with CSRF sent on every
state-changing request and an error callback on every call. Match the file's JavaScript:
no ES module syntax without a bundler, and `var` where the file uses it. A 401 or 403 from
an AJAX call sends the user to login, not a silent failure. Submit buttons disable while
the request is in flight. One Bootstrap and one jQuery UI version per project, upgraded
only with approval.

DataTables: server-side processing past a few hundred rows. (The old documents said 100 in
one place and 500 in another; pick based on the query, and say which you picked.)
