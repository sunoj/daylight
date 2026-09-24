#!/usr/bin/env node
/**
 * Run every workspace unit test file with tsx and the package-local tsconfig.
 * Exports: none
 * Deps: node child_process, node fs/path
 */

import { spawnSync } from "node:child_process";
import { readdirSync } from "node:fs";
import { dirname, join, relative } from "node:path";
import { fileURLToPath } from "node:url";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");
const testDirs = [
  "packages/domain/tests",
  "packages/core-calendar/tests",
  "packages/storage/tests",
  "packages/sync/tests",
  "apps/chrome-extension/tests",
];

const testFiles = testDirs
  .flatMap((dir) => readdirSync(join(root, dir)).filter((name) => name.endsWith(".test.ts")).map((name) => join(root, dir, name)))
  .sort();

// Most of these files are plain node:assert scripts that print nothing when
// they pass, so a silent run and a run that never happened look identical.
// Report every file by name, and the count at the end.
let failed = 0;
for (const file of testFiles) {
  const tsconfig = resolveTsconfig(file);
  const name = relative(root, file);
  // Fetched through npx rather than pinned as a devDependency: this repo carries
  // a yarn.lock alongside its npm workspaces, and adding one breaks the install.
  const result = spawnSync(
    "npx",
    ["--yes", "-p", "tsx@4.20.3", "tsx", "--tsconfig", tsconfig, file],
    { cwd: root, stdio: "inherit", env: process.env },
  );
  if (result.error) {
    console.error(`FAIL ${name}: ${result.error.message}`);
    failed += 1;
  } else if (result.status !== 0) {
    console.error(`FAIL ${name}`);
    failed += 1;
  } else {
    console.log(`pass ${name}`);
  }
}

console.log(`${testFiles.length - failed}/${testFiles.length} test files passed`);
process.exit(failed ? 1 : 0);

function resolveTsconfig(file) {
  if (file.includes(`${join("apps", "chrome-extension")}`)) {
    return join(root, "apps/chrome-extension/tsconfig.json");
  }
  const match = file.match(/packages\/([^/]+)\//);
  if (!match) throw new Error(`Cannot resolve tsconfig for ${file}`);
  return join(root, "packages", match[1], "tsconfig.json");
}
