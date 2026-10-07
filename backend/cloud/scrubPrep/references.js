// Finds verified references for a generated OR Prep (App Store guideline 1.4.1: medical
// information must cite its sources).
//
// The AI never supplies a reference. The prep prompt returns plain search phrases
// (`reference_search_terms`); this module looks them up in StatPearls via NCBI's
// E-utilities API, and a second, constrained AI call may only choose among the real
// articles that search returned (by index). Every title and link comes from NCBI's own
// records — links are built from NCBI's Bookshelf accession — so a fabricated or
// malformed citation can't reach the student.
//
// Never throws: references are supplementary, and a failed or slow lookup must not break
// prep generation. `findReferences` reports `ok: false` so callers don't cache a failed
// lookup as "no references".
//
// Optional env: PUBMED_API_KEY (an NCBI API key; raises NCBI's rate limit from 3 to 10
// requests/second) and PUBMED_EMAIL (one developer contact address, so NCBI can reach the
// developer before blocking the app's traffic — never a user's email).

const https = require("https");

const EUTILS_HOST = "eutils.ncbi.nlm.nih.gov";
const EUTILS_PATH = "/entrez/eutils/";
const REQUEST_TIMEOUT_MS = 5000;
const MAX_TERMS = 3;
const RESULTS_PER_TERM = 5;
const MAX_CANDIDATES = 10;
const MAX_SELECTED = 2;

const SELECTION_SCHEMA = {
  type: "object",
  properties: {
    selected: { type: "array", items: { type: "integer" } },
  },
  required: ["selected"],
  additionalProperties: false,
};

const SELECTION_SYSTEM_PROMPT = `You choose reference articles for a medical student preparing for an operation. You are given the operation and a numbered list of real StatPearls article titles. Choose at most ${MAX_SELECTED} articles whose main subject is one of: this operation; a closely related form of it (for example open vs. laparoscopic, or a named technique of the same operation); or the specific condition this operation treats. Do not choose articles that only mention it in passing, cover a different procedure or condition, or are about anesthesia, imaging, or nursing care. Prefer an article about the operation itself over one about the condition. If none fit, choose none. Respond only with the indices of your choices, best first.`;

function httpsGet(path) {
  return new Promise(function (resolve, reject) {
    const req = https.request(
      { host: EUTILS_HOST, path: path, method: "GET", headers: { Accept: "application/json" } },
      function (res) {
        let data = "";
        res.on("data", function (chunk) {
          data += chunk;
        });
        res.on("end", function () {
          resolve({ statusCode: res.statusCode, body: data });
        });
      }
    );
    req.setTimeout(REQUEST_TIMEOUT_MS, function () {
      req.destroy(new Error("NCBI request timed out."));
    });
    req.on("error", reject);
    req.end();
  });
}

function eutilsPath(endpoint, params) {
  const query = Object.assign({ db: "pubmed", retmode: "json", tool: "scrubprep" }, params);
  if (process.env.PUBMED_API_KEY) query.api_key = process.env.PUBMED_API_KEY;
  if (process.env.PUBMED_EMAIL) query.email = process.env.PUBMED_EMAIL;
  const qs = Object.keys(query)
    .map((key) => `${encodeURIComponent(key)}=${encodeURIComponent(query[key])}`)
    .join("&");
  return `${EUTILS_PATH}${endpoint}?${qs}`;
}

// NCBI allows 3 requests/second without an API key, 10 with one.
function requestSpacingMs() {
  return process.env.PUBMED_API_KEY ? 110 : 350;
}

const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

async function eutilsJSON(request, endpoint, params) {
  await sleep(module.exports.spacingMs());
  let response = await request(eutilsPath(endpoint, params));
  if (response.statusCode === 429) {
    await sleep(1000);
    response = await request(eutilsPath(endpoint, params));
  }
  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw new Error(`NCBI ${endpoint} failed with status ${response.statusCode}`);
  }
  return JSON.parse(response.body);
}

/**
 * Keeps search phrases to plain words so AI-supplied text can't alter the NCBI query
 * syntax (field tags, boolean operators, quotes).
 */
function sanitizeTerms(terms) {
  if (!Array.isArray(terms)) return [];
  const seen = new Set();
  const clean = [];
  for (const term of terms) {
    if (typeof term !== "string") continue;
    const words = term
      .replace(/[^A-Za-z0-9\s'-]/g, " ")
      .split(/\s+/)
      .filter((w) => w && !/^(and|or|not)$/i.test(w));
    const phrase = words.join(" ").slice(0, 80).trim();
    const key = phrase.toLowerCase();
    if (phrase && !seen.has(key)) {
      seen.add(key);
      clean.push(phrase);
    }
    if (clean.length === MAX_TERMS) break;
  }
  return clean;
}

/**
 * Short search phrases from an operation's title: the name without any parenthetical or
 * "for…"/"with…" clause, plus the parenthetical itself — "Total Hip Arthroplasty (Total
 * Hip Replacement)" → ["Total Hip Arthroplasty", "Total Hip Replacement"]. Long titles
 * otherwise require every word to match and find nothing.
 */
function termsFromTitle(title) {
  if (typeof title !== "string") return [];
  const inner = [];
  const outer = title.replace(/\(([^)]*)\)/g, (_, text) => {
    inner.push(text);
    return " ";
  });
  const main = outer
    .split(/\s+(?:for|with)\s+/i)[0]
    .replace(/\s+(placement|creation|insertion)\s*$/i, "")
    .trim();
  return [main, ...inner.filter((t) => t.split(/\s+/).length > 1)];
}

/** Real, current StatPearls articles matching any of the terms, deduplicated. */
async function searchCandidates(terms, request) {
  const ids = [];
  for (const term of terms) {
    // All words in the title first (the best matches), then all words anywhere in the
    // title/abstract by relevance; the selection step filters what's left.
    // Small words ("the", "of") match poorly as required title words in PubMed.
    const words = term.split(" ").filter((w) => !/^(the|of|a|an|in|to|for|with|on|at|by)$/i.test(w));
    if (words.length === 0) continue;
    for (const field of ["ti", "tiab"]) {
      const allWords = words.map((w) => `${w}[${field}]`).join(" AND ");
      const result = await eutilsJSON(request, "esearch.fcgi", {
        term: `${allWords} AND statpearls[book]`,
        retmax: String(RESULTS_PER_TERM),
        sort: "relevance",
      });
      for (const id of (result.esearchresult && result.esearchresult.idlist) || []) {
        if (!ids.includes(id)) ids.push(id);
      }
    }
  }
  if (ids.length === 0) return [];

  const summary = await eutilsJSON(request, "esummary.fcgi", { id: ids.join(",") });
  const records = summary.result || {};
  const candidates = [];
  for (const id of records.uids || ids) {
    const record = records[id];
    if (!record || typeof record.title !== "string") continue;
    const accession = (record.articleids || []).find((a) => a.idtype === "bookaccession");
    if (!accession || !/^NBK\d+$/.test(accession.value)) continue;
    const title = record.title.replace(/\.$/, "").trim();
    if (/\(archived\)/i.test(title)) continue;
    const yearMatch = /\b(19|20)\d{2}\b/.exec(record.pubdate || "");
    candidates.push({ title, nbk: accession.value, year: yearMatch ? yearMatch[0] : null });
    if (candidates.length === MAX_CANDIDATES) break;
  }
  return candidates;
}

/** Asks the AI which candidates fit — it can only return indices into the real list. */
async function selectRelevant(caseTitle, candidates, generateJSON) {
  const list = candidates.map((c, i) => `${i}. ${c.title}`).join("\n");
  const raw = await generateJSON({
    systemPrompt: SELECTION_SYSTEM_PROMPT,
    userPrompt: `Operation: "${caseTitle}"\n\nArticles:\n${list}`,
    schemaName: "reference_selection",
    schema: SELECTION_SCHEMA,
    temperature: 0,
  });
  const picked = [];
  for (const index of (raw && Array.isArray(raw.selected) ? raw.selected : [])) {
    if (Number.isInteger(index) && index >= 0 && index < candidates.length && !picked.includes(index)) {
      picked.push(index);
    }
    if (picked.length === MAX_SELECTED) break;
  }
  return picked.map((i) => candidates[i]);
}

function toReference(candidate) {
  return {
    title: candidate.title,
    source: candidate.year ? `StatPearls, NCBI Bookshelf, ${candidate.year}` : "StatPearls, NCBI Bookshelf",
    url: `https://www.ncbi.nlm.nih.gov/books/${candidate.nbk}/`,
  };
}

/**
 * @param {{ caseTitle: string, terms: string[] }} params
 * @param {{ generateJSON: Function, requestImpl?: typeof httpsGet }} deps
 * @returns {Promise<{ ok: boolean, references: Array<{ title: string, source: string, url: string }> }>}
 *   `ok` is false only when the lookup itself failed (network, NCBI, or AI error) — an
 *   empty, successful result means nothing relevant was found.
 */
async function findReferences({ caseTitle, terms }, deps) {
  const request = deps.requestImpl || module.exports.httpsGet;
  const titleTerms = termsFromTitle(caseTitle);
  const cleanTerms = sanitizeTerms([titleTerms[0], ...(Array.isArray(terms) ? terms : []), ...titleTerms.slice(1)]);
  if (cleanTerms.length === 0) return { ok: true, references: [] };
  try {
    const candidates = await searchCandidates(cleanTerms, request);
    if (candidates.length === 0) return { ok: true, references: [] };
    const selected = await selectRelevant(caseTitle, candidates, deps.generateJSON);
    return { ok: true, references: selected.map(toReference) };
  } catch (err) {
    console.error("Reference lookup failed:", err);
    return { ok: false, references: [] };
  }
}

module.exports = {
  findReferences,
  sanitizeTerms,
  termsFromTitle,
  spacingMs: requestSpacingMs,
  searchCandidates,
  selectRelevant,
  httpsGet,
  SELECTION_SCHEMA,
};
