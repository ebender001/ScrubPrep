const { test } = require("node:test");
const assert = require("node:assert/strict");
const references = require("../cloud/scrubPrep/references");

// No NCBI rate-limit spacing in tests.
references.spacingMs = () => 0;

function fakeNCBI(searchIds, records) {
  const paths = [];
  const requestImpl = async (path) => {
    paths.push(path);
    const body = path.includes("esearch")
      ? { esearchresult: { idlist: searchIds } }
      : { result: Object.assign({ uids: Object.keys(records) }, records) };
    return { statusCode: 200, body: JSON.stringify(body) };
  };
  return { requestImpl, paths };
}

const record = (title, nbk, pubdate = "2025 Jan") => ({
  title,
  pubdate,
  articleids: [{ idtype: "bookaccession", value: nbk }],
});

test("sanitizeTerms strips query syntax, boolean operators, duplicates, and caps at 3", () => {
  assert.deepEqual(
    references.sanitizeTerms(['lap chole[ti] OR "x"', "LAP CHOLE ti x", "a", "b", "c", 42]),
    ["lap chole ti x", "a", "b"]
  );
  assert.deepEqual(references.sanitizeTerms(null), []);
});

test("findReferences returns only AI-selected real articles, with links built from NCBI accessions", async () => {
  const { requestImpl, paths } = fakeNCBI(["1", "2", "3"], {
    "1": record("Laparoscopic Cholecystectomy.", "NBK448145"),
    "2": record("Cholecystitis (Archived).", "NBK1"),
    "3": record("Acute Cholecystitis.", "NBK459171", "2024 Jan"),
  });
  let selectionPrompt;
  const generateJSON = async (params) => {
    selectionPrompt = params.userPrompt;
    return { selected: [1, 0, 1, 99, -1] };
  };
  const result = await references.findReferences(
    { caseTitle: "Laparoscopic Cholecystectomy", terms: ["laparoscopic cholecystectomy"] },
    { generateJSON, requestImpl }
  );
  assert.equal(result.ok, true);
  assert.deepEqual(result.references, [
    { title: "Acute Cholecystitis", source: "StatPearls, NCBI Bookshelf, 2024", url: "https://www.ncbi.nlm.nih.gov/books/NBK459171/" },
    { title: "Laparoscopic Cholecystectomy", source: "StatPearls, NCBI Bookshelf, 2025", url: "https://www.ncbi.nlm.nih.gov/books/NBK448145/" },
  ]);
  // Archived articles never reach the selection step.
  assert.ok(!selectionPrompt.includes("Archived"));
  assert.ok(paths[0].includes("statpearls%5Bbook%5D"));
});

test("findReferences falls back to the case title when there are no search terms", async () => {
  const { requestImpl, paths } = fakeNCBI([], {});
  const result = await references.findReferences(
    { caseTitle: "Thyroidectomy", terms: [] },
    { generateJSON: async () => assert.fail("no candidates, so no AI call"), requestImpl }
  );
  assert.deepEqual(result, { ok: true, references: [] });
  assert.ok(decodeURIComponent(paths[0]).includes("Thyroidectomy[ti] AND statpearls[book]"));
});

test("termsFromTitle shortens long operation titles into searchable phrases", () => {
  assert.deepEqual(references.termsFromTitle("Total Hip Arthroplasty (Total Hip Replacement)"), [
    "Total Hip Arthroplasty",
    "Total Hip Replacement",
  ]);
  assert.deepEqual(references.termsFromTitle("Craniotomy for Tumor Resection"), ["Craniotomy"]);
  assert.deepEqual(references.termsFromTitle("Left Ventricular Assist Device (LVAD) Placement"), [
    "Left Ventricular Assist Device",
  ]);
});

test("findReferences always searches the operation's name, ahead of the AI's phrases", async () => {
  const { requestImpl, paths } = fakeNCBI([], {});
  await references.findReferences(
    { caseTitle: "Craniotomy for Tumor Resection", terms: ["glioma", "brain tumor"] },
    { generateJSON: async () => ({ selected: [] }), requestImpl }
  );
  const searched = paths.filter((p) => p.includes("esearch")).map(decodeURIComponent);
  assert.ok(searched[0].includes("Craniotomy[ti]"));
  assert.ok(searched.some((p) => p.includes("glioma[ti]")));
});

test("findReferences reports ok: false (and no references) when the lookup fails", async () => {
  const result = await references.findReferences(
    { caseTitle: "Appendectomy", terms: ["appendectomy"] },
    { generateJSON: async () => ({ selected: [0] }), requestImpl: async () => ({ statusCode: 503, body: "" }) }
  );
  assert.deepEqual(result, { ok: false, references: [] });
});

test("findReferences skips records without a valid NBK accession", async () => {
  const { requestImpl } = fakeNCBI(["1"], {
    "1": { title: "Some Journal Article.", pubdate: "2024", articleids: [{ idtype: "doi", value: "10.1/x" }] },
  });
  const result = await references.findReferences(
    { caseTitle: "Appendectomy", terms: ["appendectomy"] },
    { generateJSON: async () => assert.fail("no valid candidates"), requestImpl }
  );
  assert.deepEqual(result, { ok: true, references: [] });
});
