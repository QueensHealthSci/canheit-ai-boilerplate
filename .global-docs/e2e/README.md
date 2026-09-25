# Canonical Playwright setup

Copy into a repo that has a UI. Playwright is the framework's e2e tool; the rules are in
`.claude/rules/e2e.md`, which installs automatically once a `playwright.config.*` exists.

| File | Goes to |
| --- | --- |
| `playwright.config.ts` | repo root |
| `global.setup.ts` | `e2e/global.setup.ts` |
| `smoke.spec.ts` | `e2e/smoke.spec.ts` |

Then:

```bash
npm i -D @playwright/test
npx playwright install chromium
E2E_BASE_URL=http://localhost:<repo port> E2E_USER=... E2E_PASSWORD=... npx playwright test
```

The port comes from the registry in `.context/reference/docker.md` — never guess it, they
collide. Credentials come from the environment; the agent cannot read them from a file.

Add `e2e/.auth/` to `.gitignore`: the stored session is a credential.

## Which repos

Any repo with a `resources/js`, `apps/web` or `www-root` directory. `sync-repo.sh` detects
this, enables the Playwright plugin in `.claude/settings.json`, and scaffolds these files if
the repo has a UI and no config. Backend and ETL repos get neither — e2e there is ceremony.
