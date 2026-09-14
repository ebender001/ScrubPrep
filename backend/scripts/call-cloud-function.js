#!/usr/bin/env node
// Calls a deployed Cloud Function directly over the Parse REST API — bypasses
// the `b4a cloud` CLI command entirely, useful when that command is unreliable.
//
// Usage (reads backend/.env if present, so you never have to type the Master
// Key into a command — just fill it into .env with a text editor):
//   node scripts/call-cloud-function.js generateScrubPrep '{"caseDescription":"Lap chole for acute cholecystitis"}'
//
// Or override via environment inline if you prefer:
//   PARSE_APP_ID=... PARSE_MASTER_KEY=... node scripts/call-cloud-function.js ...

const https = require("https");
const fs = require("fs");
const path = require("path");
const { URL } = require("url");

function loadDotEnv() {
  const envPath = path.join(__dirname, "..", ".env");
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

function main() {
  loadDotEnv();
  const [, , functionName, paramsJson] = process.argv;
  if (!functionName) {
    console.error("Usage: node scripts/call-cloud-function.js <functionName> '<jsonParams>'");
    process.exit(1);
  }

  const appId = process.env.PARSE_APP_ID;
  const masterKey = process.env.PARSE_MASTER_KEY;
  const serverUrl = process.env.PARSE_SERVER_URL || "https://parseapi.back4app.com/";
  if (!appId || !masterKey) {
    console.error(
      "Set PARSE_APP_ID and PARSE_MASTER_KEY — either in backend/.env (recommended, edit with a text editor) or inline in your environment."
    );
    process.exit(1);
  }

  const params = paramsJson ? JSON.parse(paramsJson) : {};
  const base = serverUrl.endsWith("/") ? serverUrl : serverUrl + "/";
  const url = new URL(`functions/${functionName}`, base);
  const payload = JSON.stringify(params);

  const req = https.request(
    {
      hostname: url.hostname,
      path: url.pathname,
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Content-Length": Buffer.byteLength(payload),
        "X-Parse-Application-Id": appId,
        "X-Parse-Master-Key": masterKey,
      },
    },
    (res) => {
      let data = "";
      res.on("data", (chunk) => (data += chunk));
      res.on("end", () => {
        console.log(`HTTP ${res.statusCode}`);
        try {
          console.log(JSON.stringify(JSON.parse(data), null, 2));
        } catch {
          console.log(data);
        }
      });
    }
  );
  req.on("error", (err) => {
    console.error("Request failed:", err.message);
    process.exit(1);
  });
  req.write(payload);
  req.end();
}

main();
