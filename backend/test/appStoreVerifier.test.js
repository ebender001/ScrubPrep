const { test } = require("node:test");
const assert = require("node:assert/strict");

process.env.APPLE_BUNDLE_ID = process.env.APPLE_BUNDLE_ID || "dev.benderapps.ScrubPrep";

const { getVerifier, verifyTransaction, verifyRenewalInfo } = require("../cloud/scrubPrep/appStoreVerifier");

// Deliberately does NOT mock anything — this is the one test that exercises the real
// cert-file path and real SignedDataVerifier construction, so a deploy-breaking mistake
// (e.g. the cert not actually being where the code looks for it) fails a test locally
// instead of only being discovered after a broken deploy.
test("getVerifier constructs successfully from the real bundled Apple root certificate", () => {
  const verifier = getVerifier();
  assert.ok(verifier, "SignedDataVerifier should construct without throwing");
});

function fakeJWS(payload) {
  const header = Buffer.from(JSON.stringify({ alg: "none" })).toString("base64url");
  const body = Buffer.from(JSON.stringify(payload)).toString("base64url");
  return `${header}.${body}.unsigned`;
}

test("verifyTransaction decodes without signature verification only when APPLE_APP_STORE_ENVIRONMENT=Xcode and the payload itself claims Xcode", async () => {
  const original = process.env.APPLE_APP_STORE_ENVIRONMENT;
  process.env.APPLE_APP_STORE_ENVIRONMENT = "Xcode";
  try {
    const jws = fakeJWS({ environment: "Xcode", productId: "dev.benderapps.ScrubPrep.subscription.monthly" });
    const decoded = await verifyTransaction(jws);
    assert.equal(decoded.productId, "dev.benderapps.ScrubPrep.subscription.monthly");
  } finally {
    process.env.APPLE_APP_STORE_ENVIRONMENT = original;
  }
});

test("verifyTransaction refuses an unverified payload that doesn't itself claim environment Xcode, even in Xcode mode", async () => {
  const original = process.env.APPLE_APP_STORE_ENVIRONMENT;
  process.env.APPLE_APP_STORE_ENVIRONMENT = "Xcode";
  try {
    const jws = fakeJWS({ environment: "Production", productId: "dev.benderapps.ScrubPrep.subscription.monthly" });
    await assert.rejects(() => verifyTransaction(jws));
  } finally {
    process.env.APPLE_APP_STORE_ENVIRONMENT = original;
  }
});

test("verifyTransaction does NOT take the unverified shortcut outside Xcode mode (falls through to real verification, which rejects a fake JWS)", async () => {
  const original = process.env.APPLE_APP_STORE_ENVIRONMENT;
  process.env.APPLE_APP_STORE_ENVIRONMENT = "Sandbox";
  try {
    const jws = fakeJWS({ environment: "Xcode", productId: "dev.benderapps.ScrubPrep.subscription.monthly" });
    await assert.rejects(() => verifyTransaction(jws));
  } finally {
    process.env.APPLE_APP_STORE_ENVIRONMENT = original;
  }
});

test("verifyRenewalInfo also honors the same Xcode-only unverified shortcut", async () => {
  const original = process.env.APPLE_APP_STORE_ENVIRONMENT;
  process.env.APPLE_APP_STORE_ENVIRONMENT = "Xcode";
  try {
    const jws = fakeJWS({ environment: "Xcode", autoRenewStatus: 1 });
    const decoded = await verifyRenewalInfo(jws);
    assert.equal(decoded.autoRenewStatus, 1);
  } finally {
    process.env.APPLE_APP_STORE_ENVIRONMENT = original;
  }
});

test("an injected deps.verifier always takes precedence over the Xcode shortcut (tests elsewhere must not be affected)", async () => {
  const original = process.env.APPLE_APP_STORE_ENVIRONMENT;
  process.env.APPLE_APP_STORE_ENVIRONMENT = "Xcode";
  try {
    const fakeVerifier = { verifyAndDecodeTransaction: async () => ({ productId: "from-injected-verifier" }) };
    const decoded = await verifyTransaction("irrelevant", { verifier: fakeVerifier });
    assert.equal(decoded.productId, "from-injected-verifier");
  } finally {
    process.env.APPLE_APP_STORE_ENVIRONMENT = original;
  }
});
