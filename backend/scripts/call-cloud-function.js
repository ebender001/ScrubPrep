#!/usr/bin/env node
// Calls a deployed Cloud Function directly over the Parse REST API — bypasses
// the `b4a cloud` CLI command entirely, useful when that command is unreliable.
//
// Usage:
//   PARSE_APP_ID=... PARSE_MASTER_KEY=... PARSE_SERVER_URL=https://parseapi.back4app.com/ \
//     node scripts/call-cloud-function.js generateScrubPrep '{"caseDescription":"Lap chole for acute cholecystitis"}'

const https = require("https");
const { URL } = require("url");

function main() {
  const [, , functionName, paramsJson] = process.argv;
  if (!functionName) {
    console.error("Usage: node scripts/call-cloud-function.js <functionName> '<jsonParams>'");
    process.exit(1);
  }

  const appId = process.env.PARSE_APP_ID;
  const masterKey = process.env.PARSE_MASTER_KEY;
  const serverUrl = process.env.PARSE_SERVER_URL || "https://parseapi.back4app.com/";
  if (!appId || !masterKey) {
    console.error("Set PARSE_APP_ID and PARSE_MASTER_KEY in your environment first.");
    process.exit(1);
  }

  const params = paramsJson ? JSON.parse(paramsJson) : {};
  const url = new URL(functionName, serverUrl.endsWith("/") ? serverUrl : serverUrl + "/");
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
