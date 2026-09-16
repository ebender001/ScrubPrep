const { test } = require("node:test");
const assert = require("node:assert/strict");

process.env.APPLE_BUNDLE_ID = process.env.APPLE_BUNDLE_ID || "dev.benderapps.ScrubPrep";

const { getVerifier } = require("../cloud/scrubPrep/appStoreVerifier");

// Deliberately does NOT mock anything — this is the one test that exercises the real
// cert-file path and real SignedDataVerifier construction, so a deploy-breaking mistake
// (e.g. the cert not actually being where the code looks for it) fails a test locally
// instead of only being discovered after a broken deploy.
test("getVerifier constructs successfully from the real bundled Apple root certificate", () => {
  const verifier = getVerifier();
  assert.ok(verifier, "SignedDataVerifier should construct without throwing");
});
