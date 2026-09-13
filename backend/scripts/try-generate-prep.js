#!/usr/bin/env node
// Manual smoke test: makes a real OpenAI call using OPENAI_API_KEY from the environment.
// Usage:
//   OPENAI_API_KEY=sk-... node scripts/try-generate-prep.js "Laparoscopic cholecystectomy for acute cholecystitis"

const { generatePrep } = require("../cloud/scrubPrep/prep");

async function main() {
  const caseDescription =
    process.argv.slice(2).join(" ") || "Laparoscopic cholecystectomy for acute cholecystitis";

  if (!process.env.OPENAI_API_KEY) {
    console.error("Set OPENAI_API_KEY in your environment before running this script.");
    process.exit(1);
  }

  console.log(`Generating OR Prep for: "${caseDescription}"...\n`);
  const result = await generatePrep(caseDescription);
  console.log(JSON.stringify(result, null, 2));
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
