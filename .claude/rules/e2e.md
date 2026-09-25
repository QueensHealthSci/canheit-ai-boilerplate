---
paths:
  - "e2e/**"
  - "tests/e2e/**"
  - "**/*.spec.ts"
  - "playwright.config.*"
---
# End-to-end tests — Playwright

Playwright is the e2e framework for every repo with a UI. Unit and feature tests stay in
the stack's own runner — Pest, PHPUnit, pytest, Vitest or Jest. This file is about the browser layer only.

## What belongs in an e2e test

A user journey that crosses layers and would not be caught lower down: a form that posts and
redirects, a permission that hides a control, an import that changes what a page shows.

**Not** business logic (unit test), **not** an API response shape (feature test), **not** a
single component's rendering. An e2e suite that tests those is slow, flaky, and duplicates
coverage you already have. Three repos here have 75 specs between them; that is a real asset
and it stays one only if it stays about journeys.

## Selectors

`data-testid` first, then Playwright's semantic locators — `getByRole`, `getByLabel`,
`getByText`. Never a CSS path tied to styling: `.btn-primary` and `div > span:nth-child(3)`
break on a refactor that changed nothing a user sees.

**PrimeVue components:** put the `data-testid` on your own wrapper, never reach into PrimeVue
internals. Every repo here is on PrimeVue 4, where internal class names and DOM structure
changed from 3 — tests that reached inside broke on that upgrade.

## Structure

One file per journey (`applicant-submits.spec.ts`), `test.describe` to group, names that read
as behaviour: `'a reader cannot see an unsubmitted application'`.

Tests are independent. No test depends on another's state, and the suite must pass when a
single test is run alone — that is the property that makes a failure debuggable.

Page objects for anything used in more than two specs, in `e2e/pages/`. They hold the
selectors so the specs read as user stories.

## Authentication and data

Authenticate once in a global setup and reuse `storageState`. Logging in per test is the
single biggest source of slow suites here.

Seed through an API call or a factory in `beforeEach`; clean up after. Never hardcode an ID
that differs between environments, and never depend on data that happens to be in a shared
database today.

## Assertions

Use the auto-waiting assertions — `expect(locator).toBeVisible()`, `.toHaveText()`,
`.toHaveURL()`. A bare `waitForTimeout` is a flake waiting to happen.

Assert what the user sees, including the failure cases: validation messages, empty states,
the 403 page. A suite that only walks happy paths tells you the app renders, not that it
works.

## Running them

Headless by default. `--retries=1` locally is acceptable for network flake; retries that hide
a real race are not. Capture trace and screenshot on failure — `trace: 'on-first-retry'` is
the setting that makes a failure diagnosable after the fact.

e2e runs after unit and feature tests pass, not instead of them. `/verify` runs them when the
repo has a `playwright.config.*`; where there is none, it says so rather than passing over it.

## Before adding Playwright to a repo

A repo with the `playwright` plugin enabled in `.claude/settings.json` and no Playwright
installed has configuration for a tool that is not there. Either install it with a
real journey to test, or turn the plugin off. Enabled-and-absent is the worst of both.
