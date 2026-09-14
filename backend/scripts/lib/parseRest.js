// Shared Parse REST API helper for local scripts (seeding, manual verification). Talks to
// the REST API directly with the Master Key rather than the `b4a cloud` CLI — see
// backend/README.md's "Verifying a deploy actually took effect" section for why.

const https = require("https");
const fs = require("fs");
const path = require("path");
const { URL } = require("url");

function loadDotEnv() {
  const envPath = path.join(__dirname, "..", "..", ".env");
  if (!fs.existsSync(envPath)) return;
  const lines = fs.readFileSync(envPath, "utf8").split("\n");
  for (const line of lines) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith("#")) continue;
    const eq = trimmed.indexOf("=");
    if (eq === -1) continue;
    const key = trimmed.slice(0, eq).trim();
    const value = trimmed.slice(eq + 1).trim();
    if (!(key in process.env)) process.env[key] = value;
  }
}

function loadContext() {
  loadDotEnv();
  const appId = process.env.PARSE_APP_ID;
  const masterKey = process.env.PARSE_MASTER_KEY;
  const serverUrl = process.env.PARSE_SERVER_URL || "https://parseapi.back4app.com/";
  if (!appId || !masterKey) {
    console.error(
      "Set PARSE_APP_ID and PARSE_MASTER_KEY — either in backend/.env or inline in your environment."
    );
    process.exit(1);
  }
  return { appId, masterKey, serverUrl };
}

function restRequest({ method, pathname, appId, masterKey, serverUrl, body }) {
  return new Promise((resolve, reject) => {
    const base = serverUrl.endsWith("/") ? serverUrl : serverUrl + "/";
    const url = new URL(pathname, base);
    const payload = body ? JSON.stringify(body) : undefined;
    const req = https.request(
      {
        hostname: url.hostname,
        path: url.pathname + url.search,
        method,
        headers: {
          "Content-Type": "application/json",
          "X-Parse-Application-Id": appId,
          "X-Parse-Master-Key": masterKey,
          ...(payload ? { "Content-Length": Buffer.byteLength(payload) } : {}),
        },
      },
      (res) => {
        let data = "";
        res.on("data", (chunk) => (data += chunk));
        res.on("end", () => {
          let parsed;
          try {
            parsed = data ? JSON.parse(data) : {};
          } catch {
            parsed = {};
          }
          if (res.statusCode >= 200 && res.statusCode < 300) {
            resolve(parsed);
          } else {
            reject(new Error(`HTTP ${res.statusCode}: ${data}`));
          }
        });
      }
    );
    req.on("error", reject);
    if (payload) req.write(payload);
    req.end();
  });
}

module.exports = { loadDotEnv, loadContext, restRequest };
