// Canonical Playwright config. Copy to the repo root, then:
//   npm i -D @playwright/test && npx playwright install chromium
//
// BASE_URL comes from the repo's own port (see .context/reference/docker.md). Never hardcode
// a port here — they differ per repo and collide when guessed.
import { defineConfig, devices } from '@playwright/test';

const baseURL = process.env.E2E_BASE_URL ?? 'http://localhost:8000';

export default defineConfig({
  testDir: './e2e',
  // A test that only passes in isolation is not a test. Full parallel by default.
  fullyParallel: true,
  forbidOnly: true,
  retries: 1,
  workers: undefined,
  reporter: [['list'], ['html', { open: 'never' }]],

  use: {
    baseURL,
    // What makes a failure diagnosable after the fact, rather than a rerun.
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
    actionTimeout: 5_000,
    navigationTimeout: 30_000,
  },

  projects: [
    // Authenticate once; every other project reuses the stored state. Logging in per test is
    // the single biggest cause of slow suites.
    { name: 'setup', testMatch: /global\.setup\.ts/ },
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'], storageState: 'e2e/.auth/user.json' },
      dependencies: ['setup'],
    },
  ],

  // Uncomment once the app starts reliably from a cold command:
  // webServer: { command: 'npm run dev', url: baseURL, reuseExistingServer: true },
});
