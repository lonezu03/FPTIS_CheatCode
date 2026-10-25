import { defineConfig } from '@playwright/test';

export default defineConfig({
  testDir: './e2e-production',
  testMatch: ['convenience-mobile.spec.ts', 'catalog-training.spec.ts'],
  workers: 1,
  use: { baseURL: 'http://127.0.0.1:4175', trace: 'retain-on-failure' },
  webServer: {
    command: 'node ./node_modules/vite/bin/vite.js preview --host 127.0.0.1 --port 4175',
    url: 'http://127.0.0.1:4175',
    reuseExistingServer: !process.env.CI,
  },
});
