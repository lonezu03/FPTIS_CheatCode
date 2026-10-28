import {defineConfig} from '@playwright/test';
export default defineConfig({testDir:'./e2e-production',testMatch:'web-expansion.spec.ts',workers:1,use:{baseURL:'http://127.0.0.1:4176',trace:'retain-on-failure'},webServer:{command:'node ./node_modules/vite/bin/vite.js preview --host 127.0.0.1 --port 4176',url:'http://127.0.0.1:4176',reuseExistingServer:!process.env.CI}});
