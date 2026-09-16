#!/usr/bin/env node
// Bundles @apple/app-store-server-library (and all its transitive dependencies) into a
// single, dependency-free CommonJS file at cloud/scrubPrep/vendor/appStoreServerLibrary.bundle.js.
//
// Why this exists: Back4App's classic Cloud Code deploy (`b4a deploy`) only ships the
// cloud/ folder, and unconditionally excludes any directory literally named
// `node_modules` — confirmed by testing, at ANY depth, even nested deep inside cloud/.
// A real npm dependency can therefore only reach the deployed server as a single
// self-contained file with no external `require()` calls (Node builtins like `crypto`
// are fine — esbuild's node platform target leaves those as-is).
//
// Run this after `npm install` and after bumping the library's version in package.json:
//   node scripts/build-app-store-vendor-bundle.js

const path = require("path");
const esbuild = require("esbuild");

const entry = path.join(__dirname, "..", "node_modules", "@apple", "app-store-server-library", "dist", "index.js");
const outfile = path.join(__dirname, "..", "cloud", "scrubPrep", "vendor", "appStoreServerLibrary.bundle.js");

esbuild
  .build({
    entryPoints: [entry],
    outfile,
    bundle: true,
    platform: "node",
    target: "node18",
    format: "cjs",
  })
  .then(() => {
    console.log(`Bundled to ${outfile}`);
    console.log("Commit this file — it's what actually ships to Back4App.");
  })
  .catch((err) => {
    console.error("Bundle failed:", err);
    process.exit(1);
  });
