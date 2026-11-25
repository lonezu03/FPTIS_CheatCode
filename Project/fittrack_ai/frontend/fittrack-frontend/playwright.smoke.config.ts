import { chromium, defineConfig } from "@playwright/test";
import { existsSync } from "node:fs";
import { tmpdir } from "node:os";
import path from "node:path";

/**
 * Smoke tests (e2e/smoke/*.smoke.ts) against a production build with a mocked API.
 * The build goes to a temp folder so the project's dist/ is never touched.
 *   npx playwright test --config playwright.smoke.config.ts
 * Set SMOKE_SKIP_BUILD=1 to reuse the last temp build.
 */
const outDir = path.join(tmpdir(), "ancai-e2e-dist");
const port = 4178;
const vite = "node ./node_modules/vite/bin/vite.js";
const build = `${vite} build --outDir "${outDir}" --emptyOutDir`;
const preview = `${vite} preview --outDir "${outDir}" --host 127.0.0.1 --port ${port} --strictPort`;

// Fall back to the installed Edge when the bundled Chromium revision is missing.
const edge = "C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe";
const bundledChromium = (() => {
  try {
    return existsSync(chromium.executablePath());
  } catch {
    return false;
  }
})();
const executablePath = !bundledChromium && existsSync(edge) ? edge : undefined;

export default defineConfig({
  testDir: "./e2e/smoke",
  testMatch: "**/*.smoke.ts",
  // Traces/screenshots of failures stay outside the repository.
  outputDir: path.join(tmpdir(), "ancai-e2e-results"),
  fullyParallel: true,
  retries: process.env.CI ? 2 : 0,
  reporter: process.env.CI ? "github" : "list",
  use: {
    baseURL: `http://127.0.0.1:${port}`,
    // The production build registers /sw.js; a worker would bypass context.route mocks.
    serviceWorkers: "block",
    viewport: { width: 1366, height: 860 },
    locale: "vi-VN",
    trace: "retain-on-failure",
    launchOptions: executablePath ? { executablePath } : {},
  },
  webServer: {
    command: process.env.SMOKE_SKIP_BUILD ? preview : `${build} && ${preview}`,
    url: `http://127.0.0.1:${port}`,
    reuseExistingServer: false,
    timeout: 240_000,
  },
});
