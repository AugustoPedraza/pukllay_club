#!/usr/bin/env node
// Zero-dependency Node production smoke oracle reproducing a strict
// link-preview crawler's own view of a served page's Open Graph/Twitter
// Card head block (G-01.8-3 gap closure, plan 01.8-06 — see
// .planning/debug/whatsapp-og-image-preview.md).
//
// What it observes and why no existing gate can observe it: this phase's
// entire social-verification method went through TOLERANT parsers only —
// Facebook Sharing Debugger and Twitter Card Validator both accept an
// attribute interposed between a tag's name and its identifying
// property=/name= key, and Google's Rich Results Test never evaluates
// og:image at all. WhatsApp's own link-preview crawler does NOT tolerate
// that interposed attribute (LiveView's `phx-r` root-tag attribute,
// config/config.exs:31, Phoenix.LiveView.ColocatedCSS) — which is exactly
// how G-01.8-3 shipped to production while every other social validator
// passed. This script sends the request with a WhatsApp User-Agent,
// executes no JavaScript, and reads only the initial server response
// body — the same surface WhatsApp's crawler sees — so it is the one gate
// in this repo that can catch this class of defect again.
//
// Developer-invoked only. Deliberately NOT wired into `mix quality` or CI:
// it requires a reachable deployed host, which neither local dev nor CI
// has.
//
// Usage:
//   node test/production/og_tags_whatsapp_ua.mjs <url> [<url> ...]
//   node test/production/og_tags_whatsapp_ua.mjs --self-test
//
// AGENTS.md requires running this against the deployed host after any
// change to the meta/Open Graph/Twitter head block — passing Facebook
// Sharing Debugger, Twitter Card Validator or Google Rich Results Test
// does NOT substitute for it.

// A real WhatsApp client UA string, matching the one used to confirm the
// root cause in the debug session (curl -A "WhatsApp/2.23.20.0 A" ...).
const WHATSAPP_USER_AGENT = "WhatsApp/2.23.20.0 A"

// The 13 keys `PukllayClubWeb.SEOTags.seo_tags/1` emits, in its documented
// fixed order, each paired with the element name and the attribute that
// identifies it. Kept in sync with that module's moduledoc rather than
// freshly guessed — see seo_tags.ex and seo_tags_test.exs's own
// `@expected_keys`.
const EXPECTED_KEYS = [
  { element: "meta", attr: "name", key: "description" },
  { element: "link", attr: "rel", key: "canonical" },
  { element: "meta", attr: "property", key: "og:type" },
  { element: "meta", attr: "property", key: "og:title" },
  { element: "meta", attr: "property", key: "og:description" },
  { element: "meta", attr: "property", key: "og:url" },
  { element: "meta", attr: "property", key: "og:image" },
  { element: "meta", attr: "property", key: "og:image:width" },
  { element: "meta", attr: "property", key: "og:image:height" },
  { element: "meta", attr: "name", key: "twitter:card" },
  { element: "meta", attr: "name", key: "twitter:title" },
  { element: "meta", attr: "name", key: "twitter:description" },
  { element: "meta", attr: "name", key: "twitter:image" },
]

function escapeRegex(value) {
  return value.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")
}

function extractHead(html) {
  const match = /<head[^>]*>([\s\S]*?)<\/head>/i.exec(html)
  return match ? match[1] : html
}

// Classifies one { element, attr, key } spec against a head-block string.
// Two independent regexes, both anchored on the closing quote so
// "og:image" can never falsely match inside "og:image:width"/"og:image:height":
//   - anyPattern: the element exists ANYWHERE with this identifying
//     attribute somewhere in its attribute list (order-agnostic presence).
//   - strictPattern: the identifying attribute is the FIRST attribute
//     immediately after the tag name — the property a strict crawler
//     requires.
function classifyKey(head, { element, attr, key }) {
  const anyPattern = new RegExp(`<${element}\\b[^>]*\\b${attr}="${escapeRegex(key)}"[^>]*>`)
  const strictPattern = new RegExp(`<${element}\\s+${attr}="${escapeRegex(key)}"`)

  const anyMatch = anyPattern.exec(head)
  const found = anyMatch !== null
  const strict = found && strictPattern.test(head)

  return {
    element,
    attr,
    key,
    found,
    strict,
    pass: found && strict,
    offendingElement: found ? anyMatch[0] : null,
  }
}

// Runs the full 13-key classifier over one head-block string, returning an
// array of per-key results (see classifyKey/2).
function classifyHead(head) {
  return EXPECTED_KEYS.map((spec) => classifyKey(head, spec))
}

function formatResults(url, results) {
  const failures = results.filter((r) => !r.pass)
  const lines = []

  lines.push(`\n${url}`)

  for (const r of results) {
    if (r.pass) {
      lines.push(`  PASS  ${r.key}`)
    } else if (!r.found) {
      lines.push(`  FAIL  ${r.key} — element not found (expected <${r.element} ${r.attr}="${r.key}" ...>)`)
    } else {
      lines.push(`  FAIL  ${r.key} — found but not strict-clean (an attribute is interposed before ${r.attr}=)`)
      lines.push(`        offending element: ${r.offendingElement}`)
    }
  }

  return { lines, failures }
}

async function checkUrl(url) {
  const res = await fetch(url, {
    headers: { "User-Agent": WHATSAPP_USER_AGENT },
  })

  if (!res.ok) {
    return {
      url,
      lines: [`\n${url}`, `  FAIL  HTTP ${res.status} — could not fetch page`],
      failures: [{ key: "(fetch)" }],
    }
  }

  const html = await res.text()
  const head = extractHead(html)
  const results = classifyHead(head)
  const { lines, failures } = formatResults(url, results)

  return { url, lines, failures }
}

async function runUrls(urls) {
  let anyFailures = false
  const failureSummary = []

  for (const url of urls) {
    const { lines, failures } = await checkUrl(url)
    console.log(lines.join("\n"))

    if (failures.length > 0) {
      anyFailures = true
      for (const f of failures) {
        failureSummary.push(`${url} — ${f.key}`)
      }
    }
  }

  if (anyFailures) {
    console.log("\nFAILED — strict-crawler-clean tags missing or malformed:")
    for (const line of failureSummary) {
      console.log(`  - ${line}`)
    }
    process.exitCode = 1
  } else {
    console.log(`\nOK — all ${EXPECTED_KEYS.length} keys strict-clean on ${urls.length} URL(s).`)
    process.exitCode = 0
  }
}

// Self-test: proves the classifier itself is red on an interposed-attribute
// fixture and green on a strict-clean one, entirely in-memory (no network).
// Without this, a classifier that silently matched nothing (e.g. a typo in
// one of the regexes above) would report every real page as passing — the
// same failure mode as the loosened order-agnostic regex this plan reverses
// on the Elixir test side.
function buildStrictCleanFixture() {
  const tags = EXPECTED_KEYS.map(({ element, attr, key }) => {
    const valueAttr = attr === "rel" ? "href" : "content"
    return `<${element} ${attr}="${key}" ${valueAttr}="https://pukllay.club/example">`
  })

  return `<html><head>${tags.join("\n")}</head><body></body></html>`
}

function buildInterposedAttributeFixture() {
  const tags = EXPECTED_KEYS.map(({ element, attr, key }) => {
    const valueAttr = attr === "rel" ? "href" : "content"
    // phx-r as the FIRST attribute — the exact production defect G-01.8-3
    // diagnosed (config/config.exs:31's root_tag_attribute).
    return `<${element} phx-r="abc123" ${attr}="${key}" ${valueAttr}="https://pukllay.club/example">`
  })

  return `<html><head>${tags.join("\n")}</head><body></body></html>`
}

function runSelfTest() {
  const cleanHead = extractHead(buildStrictCleanFixture())
  const interposedHead = extractHead(buildInterposedAttributeFixture())

  const cleanResults = classifyHead(cleanHead)
  const interposedResults = classifyHead(interposedHead)

  const cleanFailures = cleanResults.filter((r) => !r.pass)
  const interposedFailures = interposedResults.filter((r) => !r.pass)

  const cleanOk = cleanFailures.length === 0
  const interposedCorrectlyFailed = interposedFailures.length === EXPECTED_KEYS.length

  console.log(`self-test: strict-clean fixture classifies as passing: ${cleanOk ? "PASS" : "FAIL"}`)
  if (!cleanOk) {
    for (const r of cleanFailures) {
      console.log(`  unexpected failure: ${r.key} (found=${r.found}, strict=${r.strict})`)
    }
  }

  console.log(
    `self-test: interposed-attribute fixture classifies as failing: ${interposedCorrectlyFailed ? "PASS" : "FAIL"}`,
  )
  if (!interposedCorrectlyFailed) {
    for (const r of interposedResults) {
      if (r.pass) {
        console.log(`  unexpectedly passed: ${r.key} (should have been rejected as non-strict)`)
      }
    }
  }

  if (cleanOk && interposedCorrectlyFailed) {
    console.log("\nself-test OK — classifier is red on interposed attributes, green on strict-clean markup.")
    process.exitCode = 0
  } else {
    console.log("\nself-test FAILED — the classifier itself is broken, do not trust a green run against real URLs.")
    process.exitCode = 1
  }
}

const args = process.argv.slice(2)

if (args.includes("--self-test")) {
  runSelfTest()
} else if (args.length === 0) {
  console.error("Usage: node test/production/og_tags_whatsapp_ua.mjs <url> [<url> ...]")
  console.error("       node test/production/og_tags_whatsapp_ua.mjs --self-test")
  process.exitCode = 1
} else {
  await runUrls(args)
}
