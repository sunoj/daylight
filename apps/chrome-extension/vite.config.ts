/**
 * Vite build config for the Manifest V3 Chrome extension.
 * Exports: Vite config with popup and service worker entry points
 * Deps: vite build API
 */

import { fileURLToPath } from "node:url";

const rootDir = fileURLToPath(new URL("../..", import.meta.url));

export default {
  publicDir: "public",
  resolve: {
    alias: {
      "@daylight/domain": `${rootDir}/packages/domain/src/index.ts`,
      "@daylight/core-calendar": `${rootDir}/packages/core-calendar/src/index.ts`,
      "@daylight/storage": `${rootDir}/packages/storage/src/index.ts`,
      "@daylight/sync": `${rootDir}/packages/sync/src/index.ts`,
    },
  },
  build: {
    emptyOutDir: true,
    outDir: "dist",
    rollupOptions: {
      input: {
        popup: "popup.html",
        "service-worker": "src/service-worker.ts",
      },
      output: {
        entryFileNames: "[name].js",
        assetFileNames: "[name][extname]",
      },
    },
  },
};
