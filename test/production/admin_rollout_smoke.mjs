#!/usr/bin/env node
// Zero-dependency Node production smoke check for the Phase 01.8.1 rollout
// (staff admin, ludoteca shelves, curated destacados) — see
// .planning/phases/01.8.1-staff-admin-ludoteca-shelves-curated-destacados/01.8.1-14-PLAN.md.
// Extended by Phase 01.8.2 (admin UI/UX redesign) with the Estantes route and
// game-detail checks below.
//
// KNOWN GAP — Phase 01.8.2 has NO pre-deploy baseline file. The 01.8.2 deploy
// ran automatically on the PR #68 merge (run 36003197484, 2026-09-24T13:04Z)
// before its rollout plan's baseline task executed, so `--expect-baseline` has
// nothing to compare against for this phase and the sitemap check degrades to
// an absolute read. Do NOT capture a baseline now and pass it as `01.8.2`'s:
// a post-deploy capture compared against itself passes trivially and proves
// nothing — the exact near-miss recorded in CLAUDE.md for plan 01.8.1-14.
// The shelves/copies counts this phase's migration cleared are likewise
// unmeasured; they are DB-level and were never observable from this script.
//
// What it observes and why no existing gate can observe it: this phase ships
// several one-way migrations (games.status, sections backfill) against the
// real ~434-game production catalog. RESEARCH Pitfall 1 is explicit that a
// fixture-based test suite never catches a migration default bug against
// pre-existing production rows — only a live count comparison against a
// pre-deploy baseline can. This script has two modes for exactly that:
// `--baseline <file>` captures the pre-deploy sitemap count, and
// `--expect-baseline <file>` re-checks it post-deploy as a floor, alongside
// the auth/admin contract (D-31): anonymous /admin redirects to
// /admin/ingresar, and the generator's default /users/* paths are gone.
//
// Developer-invoked only. Deliberately NOT wired into `mix quality` or CI:
// it requires a reachable deployed host, which neither local dev nor CI has.
//
// Usage:
//   node test/production/admin_rollout_smoke.mjs <url> --baseline <file>
//   node test/production/admin_rollout_smoke.mjs <url> [--expect-baseline <file>]

function parseArgs(argv) {
  const positional = []
  let baselineFile = null
  let expectBaselineFile = null

  for (let i = 0; i < argv.length; i += 1) {
    const arg = argv[i]
    if (arg === "--baseline") {
      baselineFile = argv[i + 1]
      i += 1
    } else if (arg === "--expect-baseline") {
      expectBaselineFile = argv[i + 1]
      i += 1
    } else {
      positional.push(arg)
    }
  }

  return { url: positional[0], baselineFile, expectBaselineFile }
}

function countSitemapLocs(xml) {
  const matches = xml.match(/<loc>/g)
  return matches ? matches.length : 0
}

async function fetchSitemapCount(baseUrl) {
  const res = await fetch(new URL("/sitemap.xml", baseUrl))
  if (!res.ok) {
    return { ok: false, status: res.status, count: 0 }
  }
  const body = await res.text()
  return { ok: true, status: res.status, count: countSitemapLocs(body) }
}

// Baseline mode: writes { sitemap_count: N } to `file`, prints N, exits 0
// whenever the sitemap responds 200. No other checks run in this mode — the
// whole point is a cheap, narrowly-scoped pre-deploy snapshot.
async function runBaseline(baseUrl, file) {
  const { fs } = await import("node:fs/promises").then((mod) => ({ fs: mod }))
  const { ok, status, count } = await fetchSitemapCount(baseUrl)

  if (!ok) {
    console.log(`FAIL /sitemap.xml — HTTP ${status}`)
    process.exitCode = 1
    return
  }

  await fs.writeFile(file, JSON.stringify({ sitemap_count: count }, null, 2) + "\n")
  console.log(`PASS /sitemap.xml — sitemap_count=${count} (written to ${file})`)
  console.log(count)
  process.exitCode = 0
}

async function readExpectedBaseline(file) {
  if (!file) return null
  const { fs } = await import("node:fs/promises").then((mod) => ({ fs: mod }))
  const raw = await fs.readFile(file, "utf8")
  const parsed = JSON.parse(raw)
  return typeof parsed.sitemap_count === "number" ? parsed.sitemap_count : null
}

async function checkUp(baseUrl) {
  const res = await fetch(new URL("/up", baseUrl))
  const pass = res.status === 200
  return { name: "/up", pass, detail: `HTTP ${res.status}` }
}

async function checkHome(baseUrl) {
  const res = await fetch(new URL("/", baseUrl))
  const pass = res.status === 200
  return { name: "/", pass, detail: `HTTP ${res.status}` }
}

async function checkSitemap(baseUrl, expectedFloor) {
  const { ok, status, count } = await fetchSitemapCount(baseUrl)

  if (!ok) {
    return { name: "/sitemap.xml", pass: false, detail: `HTTP ${status}` }
  }

  if (expectedFloor !== null && count < expectedFloor) {
    return {
      name: "/sitemap.xml",
      pass: false,
      detail: `count=${count} is below baseline floor=${expectedFloor}`,
    }
  }

  return {
    name: "/sitemap.xml",
    pass: true,
    detail:
      expectedFloor !== null
        ? `count=${count} >= baseline floor=${expectedFloor}`
        : `count=${count}`,
  }
}

async function checkAdminRedirect(baseUrl, path = "/admin") {
  const res = await fetch(new URL(path, baseUrl), { redirect: "manual" })
  const location = res.headers.get("location") || ""
  const pass = res.status === 302 && location.endsWith("/admin/ingresar")
  return {
    name: path,
    pass,
    detail: `HTTP ${res.status}, Location=${location || "(none)"}`,
  }
}

// Phase 01.8.2: the three Estantes routes must exist and be staff-gated. A 404
// here is the D-07 failure this phase's rollout was built to make impossible —
// the clear-slate migration having run in a deploy that did NOT carry the
// rebuild screens, leaving production with no shelf map and no way to rebuild
// one. Anonymous-redirect (not 404) is therefore the load-bearing assertion.
async function checkEstanteRoutes(baseUrl) {
  return Promise.all(
    [
      "/admin/estantes",
      "/admin/estantes/pendientes",
      "/admin/estantes/administrar",
    ].map((path) => checkAdminRedirect(baseUrl, path)),
  )
}

// Phase 01.8.2: the migration touches games.shelf_id, so a public game detail
// page is the cheapest end-to-end proof the catalog still renders after it.
// The slug comes from the live sitemap rather than a hardcoded id, so this
// check cannot rot against catalog changes.
async function checkGameDetail(baseUrl) {
  const res = await fetch(new URL("/sitemap.xml", baseUrl))
  if (!res.ok) {
    return { name: "/juegos/:id", pass: false, detail: `sitemap HTTP ${res.status}` }
  }

  const body = await res.text()
  const match = body.match(/<loc>([^<]*\/juegos\/[^<]+)<\/loc>/)
  if (!match) {
    return { name: "/juegos/:id", pass: false, detail: "no /juegos/ URL in sitemap" }
  }

  const gameUrl = match[1]
  const gameRes = await fetch(gameUrl)
  return {
    name: "/juegos/:id",
    pass: gameRes.status === 200,
    detail: `HTTP ${gameRes.status} for ${gameUrl}`,
  }
}

async function checkAdminLogin(baseUrl) {
  const res = await fetch(new URL("/admin/ingresar", baseUrl))
  const pass = res.status === 200
  return { name: "/admin/ingresar", pass, detail: `HTTP ${res.status}` }
}

async function checkUsersRegisterGone(baseUrl) {
  const res = await fetch(new URL("/users/register", baseUrl), { redirect: "manual" })
  const pass = res.status === 404
  return { name: "/users/register", pass, detail: `HTTP ${res.status}` }
}

async function runChecks(baseUrl, expectBaselineFile) {
  const expectedFloor = await readExpectedBaseline(expectBaselineFile)

  const checks = [
    await checkUp(baseUrl),
    await checkHome(baseUrl),
    await checkSitemap(baseUrl, expectedFloor),
    await checkAdminRedirect(baseUrl),
    await checkAdminLogin(baseUrl),
    await checkUsersRegisterGone(baseUrl),
    ...(await checkEstanteRoutes(baseUrl)),
    await checkGameDetail(baseUrl),
  ]

  let anyFail = false
  for (const { name, pass, detail } of checks) {
    if (pass) {
      console.log(`PASS ${name} — ${detail}`)
    } else {
      anyFail = true
      console.log(`FAIL ${name} — ${detail}`)
    }
  }

  process.exitCode = anyFail ? 1 : 0
}

const args = process.argv.slice(2)
const { url, baselineFile, expectBaselineFile } = parseArgs(args)

if (!url) {
  console.error(
    "Usage: node test/production/admin_rollout_smoke.mjs <url> --baseline <file>\n" +
      "       node test/production/admin_rollout_smoke.mjs <url> [--expect-baseline <file>]",
  )
  process.exitCode = 1
} else if (baselineFile) {
  await runBaseline(url, baselineFile)
} else {
  await runChecks(url, expectBaselineFile)
}
