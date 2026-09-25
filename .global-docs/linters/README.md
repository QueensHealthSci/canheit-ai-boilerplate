# Canonical linter configuration

One config file replaces about twenty lines of always-on prose, and runs in seconds. `bin/check` is
the gate, locally and in CI if you run one. The full rule-to-enforcement map is
`../../.context/enforcement.md`.

**`scripts/sync-repo.sh` installs these** — you do not copy them by hand. It links the ones a
repo's stack calls for (`scripts/_detect.sh: linter_targets`), and **never overwrites a config
the repo already has**, because a tuned `pint.json` is real configuration and a sync that
clobbered it would be doing the opposite of its job. To opt a repo out of a canonical config,
replace the link with a real file; `check-framework.sh` reports which repos have.

`AppServiceProvider.snippet.php` is the exception: it is pasted into an existing provider, so
nothing installs it.

| File | Goes to | Enforces |
| --- | --- | --- |
| `pint.json` | repo root | `declare(strict_types=1)`, PSR-12 via the Laravel preset, import order, unused imports |
| `phpstan.neon` | repo root | types (Larastan level 6); no `env()` outside `config/`; no `dd()`/`dump()`; no `$request->all()`; no `DB::raw()` |
| `eslint.framework.mjs` | repo root, spread into `eslint.config.js` | no `any`; `<script setup>` only; import order; no `debugger`/`console.log` |
| `AppServiceProvider.snippet.php` | `app/Providers/AppServiceProvider.php` | N+1 and silent mass assignment throw outside production |

**Coverage** is not a config file: it is `--coverage --min=80` in `bin/check`, plus a driver in
the image. A stock PHP image often installs neither pcov nor Xdebug, and a Sail image needs
`SAIL_XDEBUG_MODE=coverage`. Until the driver is there, `bin/check` reports PHP coverage as
unmeasurable rather than a number.

Install the PHP tools: `composer require --dev laravel/pint larastan/larastan spaze/phpstan-disallowed-calls`.
