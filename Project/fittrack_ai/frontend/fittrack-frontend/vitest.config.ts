import { defineConfig } from "vitest/config";
import react from "@vitejs/plugin-react";
import path from "node:path";

export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: {
      "@": path.resolve(import.meta.dirname, "./src"),
    },
  },
  test: {
    environment: "jsdom",
    setupFiles: "./src/test/setup.ts",
    include: ["src/**/*.test.{ts,tsx}"],
    css: false,
    // Trang nặng có thể mất vài giây ở lần chạy nguội; tránh timeout 5 giây mặc định gây lỗi ngẫu nhiên.
    testTimeout: 15_000,
  },
});
