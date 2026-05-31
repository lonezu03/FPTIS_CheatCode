import { execSync } from "node:child_process";
import { cpSync, existsSync, rmSync } from "node:fs";

const nodeModulesDir = "fittrack-frontend/node_modules";
const tscBin =
  process.platform === "win32"
    ? "fittrack-frontend/node_modules/.bin/tsc.cmd"
    : "fittrack-frontend/node_modules/.bin/tsc";

if (!existsSync(nodeModulesDir)) {
  execSync("npm --prefix fittrack-frontend ci", {
    stdio: "inherit",
  });
}

if (!existsSync(tscBin)) {
  throw new Error("fittrack-frontend dependencies are incomplete. Run npm --prefix fittrack-frontend install, then retry.");
}

execSync("npm --prefix fittrack-frontend run build", {
  stdio: "inherit",
});

rmSync("dist", { force: true, recursive: true });
cpSync("fittrack-frontend/dist", "dist", { recursive: true });
