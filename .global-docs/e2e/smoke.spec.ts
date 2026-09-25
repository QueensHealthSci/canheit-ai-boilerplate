// The first real spec. Copy to e2e/smoke.spec.ts and adapt to the repo's actual routes.
//
// A smoke suite is not a formality: these three catch the failures that take an app down
// entirely — it does not boot, auth is broken, or an authorization gate is inverted.
import { test, expect } from '@playwright/test';

test.describe('smoke', () => {
  test('the authenticated landing page loads', async ({ page }) => {
    await page.goto('/');
    await expect(page.getByRole('heading', { level: 1 })).toBeVisible();
    // No unhandled error surfaced to the user.
    await expect(page.getByText(/something went wrong|500|exception/i)).toHaveCount(0);
  });

  test('a signed-out visitor is sent to login, not shown the page', async ({ browser }) => {
    // Fresh context: no storageState, so genuinely unauthenticated.
    const page = await browser.newPage({ storageState: undefined });
    await page.goto('/');
    await expect(page).toHaveURL(/login/);
    await page.close();
  });

  test('a protected route refuses an unauthorized role', async ({ page }) => {
    // Replace with a route this user must NOT reach. Asserting the denial is the half of
    // authorization testing that usually gets skipped.
    await page.goto('/admin');
    await expect(page.getByText(/forbidden|not authorized|403/i)).toBeVisible();
  });
});
