// Authenticates once and saves the session. Every other project reuses it via storageState.
// Copy to e2e/global.setup.ts and replace the selectors and credentials source.
import { test as setup, expect } from '@playwright/test';

const authFile = 'e2e/.auth/user.json';

setup('authenticate', async ({ page }) => {
  // Credentials come from the environment, never from a committed file. Ask for the values
  // rather than reading an environment file — the agent is not permitted to open one.
  const email = process.env.E2E_USER;
  const password = process.env.E2E_PASSWORD;
  if (!email || !password) throw new Error('Set E2E_USER and E2E_PASSWORD before running e2e.');

  await page.goto('/login');
  await page.getByLabel('Email').fill(email);
  await page.getByLabel('Password').fill(password);
  await page.getByRole('button', { name: 'Log in' }).click();

  // Assert the destination, not the click — a redirect that silently fails is the bug this
  // catches, and every later test depends on this having worked.
  await expect(page).toHaveURL(/dashboard/);
  await page.context().storageState({ path: authFile });
});
