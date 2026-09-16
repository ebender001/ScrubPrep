// Thin wrapper around Apple's official `@apple/app-store-server-library`, used to verify
// the cryptographic signature on a client-submitted transaction/renewal info (see
// subscriptions.js's syncSubscriptionStatus). This verification path needs NO App Store
// Connect API credentials — only Apple's public root certificate (bundled in this repo at
// cloud/certs/AppleRootCA-G3.cer) and the app's bundle id/environment as plain config.
// Never trust unverified client-reported subscription state — everything that matters for
// access control flows through here first.
//
// There's deliberately no App Store Server Notifications V2 (webhook) support: testing
// against this app's Back4App instance confirmed its hosted gateway rejects Apple's
// webhook calls outright (Apple can't send Parse's required auth headers, and the
// documented query-string fallback returns 401 here) — see backend/README.md's
// "Subscriptions & complimentary case" section for why relying solely on client-pushed
// syncSubscriptionStatus calls (launch/foreground/purchase/restore) is still correct
// enforcement, not a shortcut.

const fs = require("fs");
const path = require("path");
// Required from a pre-built bundle (vendor/appStoreServerLibrary.bundle.js), not the
// bare npm package — Back4App's classic Cloud Code deploy unconditionally excludes any
// `node_modules` directory (confirmed by testing, at any depth under cloud/), so a real
// npm dependency can only reach the deployed server as a single dependency-free file.
// See scripts/build-app-store-vendor-bundle.js (regenerate after bumping the version in
// package.json) and backend/README.md's "Subscriptions & complimentary case" section.
const { SignedDataVerifier, Environment } = require("./vendor/appStoreServerLibrary.bundle.js");

// Lives under cloud/ (not the backend project root) because Back4App's classic Cloud
// Code deploy only ships the cloud/ folder — see backend/README.md's "Subscriptions &
// complimentary case" section for the full explanation.
const ROOT_CERT_PATH = path.join(__dirname, "..", "certs", "AppleRootCA-G3.cer");

function resolveEnvironment() {
  const raw = (process.env.APPLE_APP_STORE_ENVIRONMENT || "Sandbox").trim();
  if (raw === "Production") return Environment.PRODUCTION;
  if (raw === "Xcode") return Environment.XCODE;
  if (raw === "LocalTesting") return Environment.LOCAL_TESTING;
  return Environment.SANDBOX;
}

// Transactions from Xcode's local StoreKit Configuration file (used for local simulator/
// device testing with no real Apple ID) are signed with a synthetic, locally-generated
// key — their certificate chain does NOT and CANNOT trace back to Apple's real root CA,
// regardless of which `Environment` is configured on the verifier. Real cryptographic
// verification of local-testing transactions is therefore impossible in principle, not a
// bug here — this is Apple's own documented limitation of local StoreKit testing.
//
// To still let local testing exercise the full purchase -> paywall-dismisses loop, when
// (and ONLY when) APPLE_APP_STORE_ENVIRONMENT=Xcode we decode the JWT payload WITHOUT
// verifying its signature, and additionally require the decoded payload to itself claim
// `environment: "Xcode"` — so a misconfigured/forgotten "Xcode" setting can't be tricked
// into accepting a Sandbox- or Production-shaped payload. This is a deliberate,
// narrowly-scoped relaxation of "never trust unverified client-reported state," gated
// behind a config value that must be explicitly set and must NEVER be used on a real
// (Sandbox/Production) deployment — see backend/README.md and .env.example.
function isLocalXcodeTestingMode() {
  return resolveEnvironment() === Environment.XCODE;
}

function decodeUnverifiedJWSPayload(jws) {
  const parts = jws.split(".");
  if (parts.length !== 3) {
    throw new Error("Malformed JWS: expected 3 dot-separated segments.");
  }
  const payload = JSON.parse(Buffer.from(parts[1], "base64url").toString("utf8"));
  if (payload.environment !== "Xcode") {
    throw new Error(
      `Refusing to accept an unverified payload claiming environment "${payload.environment}" while ` +
        `APPLE_APP_STORE_ENVIRONMENT=Xcode is set — only payloads that themselves claim "Xcode" are accepted ` +
        `this way. This should never happen outside local testing.`
    );
  }
  console.warn(
    "[appStoreVerifier] Accepted an UNVERIFIED local Xcode StoreKit testing transaction " +
      "(no signature check) — this must never happen on a Sandbox/Production deployment."
  );
  return payload;
}

let cachedVerifier = null;

/** @returns {SignedDataVerifier} */
function getVerifier() {
  if (cachedVerifier) return cachedVerifier;
  const bundleId = process.env.APPLE_BUNDLE_ID;
  if (!bundleId) {
    throw new Error("APPLE_BUNDLE_ID is not configured.");
  }
  const rootCert = fs.readFileSync(ROOT_CERT_PATH);
  // enableOnlineChecks: false — avoids an extra network round-trip (OCSP revocation
  // checking) per verification from inside Cloud Code; the offline checks (signature
  // chain + expiration) are what actually matter for this app's access control.
  cachedVerifier = new SignedDataVerifier([rootCert], false, resolveEnvironment(), bundleId);
  return cachedVerifier;
}

/**
 * @param {string} signedTransactionInfo
 * @param {{ verifier?: SignedDataVerifier }} [deps]
 * @returns {Promise<import("@apple/app-store-server-library").JWSTransactionDecodedPayload>}
 */
async function verifyTransaction(signedTransactionInfo, deps = {}) {
  if (!deps.verifier && isLocalXcodeTestingMode()) {
    return decodeUnverifiedJWSPayload(signedTransactionInfo);
  }
  const verifier = deps.verifier || getVerifier();
  return verifier.verifyAndDecodeTransaction(signedTransactionInfo);
}

/**
 * @param {string} signedRenewalInfo
 * @param {{ verifier?: SignedDataVerifier }} [deps]
 * @returns {Promise<import("@apple/app-store-server-library").JWSRenewalInfoDecodedPayload>}
 */
async function verifyRenewalInfo(signedRenewalInfo, deps = {}) {
  if (!deps.verifier && isLocalXcodeTestingMode()) {
    return decodeUnverifiedJWSPayload(signedRenewalInfo);
  }
  const verifier = deps.verifier || getVerifier();
  return verifier.verifyAndDecodeRenewalInfo(signedRenewalInfo);
}

module.exports = { verifyTransaction, verifyRenewalInfo, getVerifier, isLocalXcodeTestingMode };
