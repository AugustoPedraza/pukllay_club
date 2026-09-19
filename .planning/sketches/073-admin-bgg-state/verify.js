/* Headless-Chrome checks for sketch 073 (the BGG state in the game editor). Run from the repo root:
     python3 -m http.server 8765 &
     node .planning/sketches/073-admin-bgg-state/verify.js
   Env: PLAYWRIGHT_CORE, SKETCH_URL, SHOTS_DIR (default <os tmp>/sketch-073-shots).

   The harness carries a `HOY` variant — what `form.ex` renders today — specifically so the guards can be
   NEGATIVE-TESTED. A guard that only ever sees passing input is not a guard; sketch 072 shipped one
   (distinguishability at >= 1.15) that scored the variant it was written to reject as a PASS. So every
   assertion below that claims "the variants do not do X" is paired with an assertion that HOY DOES do X. */
const fs = require('fs'), path = require('path'), os = require('os');
function loadPlaywright() {
  const tries = [process.env.PLAYWRIGHT_CORE, 'playwright-core'].filter(Boolean);
  const npx = path.join(os.homedir(), '.npm', '_npx');
  if (fs.existsSync(npx)) for (const d of fs.readdirSync(npx)) tries.push(path.join(npx, d, 'node_modules', 'playwright-core'));
  for (const t of tries) { try { return require(t); } catch (_) {} }
  console.error('playwright-core not found'); process.exit(2);
}
const { chromium } = loadPlaywright();
const URL = process.env.SKETCH_URL || 'http://127.0.0.1:8765/.planning/sketches/073-admin-bgg-state/index.html';
const OUT = process.env.SHOTS_DIR || path.join(os.tmpdir(), 'sketch-073-shots'); fs.mkdirSync(OUT, { recursive: true });
const log = []; const ok = (c, m) => log.push((c ? 'PASS ' : 'FAIL ') + m);

/* D2 won (decision 39); D1 and D3 are removed along with their comparison checks, per 072's rule that what
   is on screen is the decision and not a menu of them. Their measurements live in the README. HOY stays: it
   is the shipped baseline every negative test is written against. */
/* F2 won (decision 41). F1 is removed with its comparison checks, per 072's rule that what is on screen is
   the decision and not a menu of them; its measurements live in the README. */
const VARIANTS = ['F2'];
const STATES = ['no_bgg_id', 'bgg_missing', 'failed', 'pending', 'enriched'];

(async () => {
  const browser = await chromium.launch({ channel: 'chrome', headless: true });
  const errs = [];
  const ctx = await browser.newContext({ viewport: { width: 375, height: 740 }, deviceScaleFactor: 2 });
  const p = await ctx.newPage();
  p.on('pageerror', e => errs.push('pageerror: ' + e.message));
  p.on('console', m => m.type() === 'error' && !/404|favicon/.test(m.text()) && errs.push('console: ' + m.text()));
  await p.goto(URL); await p.evaluate(() => document.fonts.ready);
  await p.evaluate(() => { document.getElementById('tools').style.display = 'none'; });
  const J = (f, a) => p.evaluate(f, a);
  const cool = async () => { await p.mouse.move(-60, -60); await p.waitForTimeout(120); };

  /* drive the sketch through its own tools rather than by calling render() — a check that bypasses the
     control it is validating proves nothing about the control */
  /* The scroll reset is load-bearing, not tidiness. An earlier check calls `.focus()` on the id field, which
     scrolls it into view; without resetting, every later measurement and every screenshot is taken on a page
     the reader never sees at rest — and "what is on screen" is half of what this round is deciding. The
     first run of this harness produced exactly that: a baseline screenshot scrolled past its own heading. */
  const set = async (v, s, cy = 'published') => {
    await J(([vv, ss, cc]) => {
      document.querySelector(`[data-var="${vv}"]`).click();
      document.querySelector(`[data-st="${ss}"]`).click();
      document.querySelector(`[data-cy="${cc}"]`).click();
      document.getElementById('scroller').scrollTop = 0;
    }, [v, s, cy]);
    await p.waitForTimeout(90); await cool();
  };
  const theme = async t => { await J(tt => { document.querySelector(`[data-theme-set="${tt}"]`).click(); }, t); await p.waitForTimeout(80); };

  /* ================= 1. the wall of eleven em-dashes =================
     `form.ex:332-346` renders 11 rows through `value_or_dash/1`. For the 49 broken games every source column
     is NULL, so all 11 render "—". Counted as INK (the dd's text), not as markup, so a variant cannot pass
     by keeping the dash and hiding it. */
  {
    const dashesIn = () => J(() => {
      const dl = document.querySelector('.bgg');
      if (!dl) return 0;
      return [...dl.querySelectorAll('dd')].filter(d => d.textContent.trim() === '—').length;
    });
    await set('HOY', 'no_bgg_id');
    const hoy = await dashesIn();
    ok(hoy === 11, `NEGATIVE TEST — today's editor really does render ${hoy} em-dash rows for a game with no BGG data (expected 11)`);
    await p.screenshot({ path: path.join(OUT, '00-hoy-11-guiones.png') });
    for (const v of VARIANTS) {
      let worst = 0;
      for (const s of ['no_bgg_id', 'bgg_missing', 'failed']) { await set(v, s); worst = Math.max(worst, await dashesIn()); }
      ok(worst === 0, `${v}: no em-dash wall in any broken state (max ${worst} dash rows)`);
    }
  }

  /* ================= 2. the lock line only where it is true =================
     "Vienen de BoardGameGeek y se actualizan solos. No se editan acá." is FALSE for the 49: they did not
     update themselves, and there is something to do about it. It must appear for `enriched` and nowhere else. */
  {
    const lock = () => J(() => !!document.querySelector('.lock'));
    await set('HOY', 'no_bgg_id');
    ok(await lock() === true, `NEGATIVE TEST — today's editor does show "No se editan acá" over a game with no data (the claim this round removes)`);
    for (const v of VARIANTS) {
      await set(v, 'enriched');
      const onOk = await lock();
      let leaked = false;
      for (const s of ['no_bgg_id', 'bgg_missing', 'failed', 'pending']) { await set(v, s); if (await lock()) leaked = true; }
      ok(onOk && !leaked, `${v}: the lock line appears for "enriched" and for no other state`);
    }
  }

  /* ================= 3. D-19h — a status is a dot + text, never a pill =================
     The shipped editor uses `alert alert-error`, a filled red BOX. Detected by comparing the state element's
     own background against the page background: a dot+text carries none, a box carries one. */
  {
    const filled = sel => J(s => {
      const el = document.querySelector(s); if (!el) return null;
      const bg = getComputedStyle(el).backgroundColor;
      return !(bg === 'rgba(0, 0, 0, 0)' || bg === 'transparent');
    }, sel);
    await set('HOY', 'failed');
    /* The first draft of this check read `querySelectorAll('#main div').find(...)` and FAILED — because the
       outer `.variant` wrapper also contains that text and that button, and `.find` returns the first match
       in document order, which is the ancestor. It measured the page's background and concluded the shipped
       alert was not filled. Exactly sketch 072's trap in a new place: a guard that matches an ANCESTOR of
       its subject reports on something it was not asked about. Take the innermost match instead. */
    const hoyBox = await J(() => {
      const hits = [...document.querySelectorAll('#main div')].filter(d => /Error al traer datos/.test(d.textContent) && d.querySelector('button'));
      const el = hits[hits.length - 1];
      if (!el) return null;
      const bg = getComputedStyle(el).backgroundColor;
      return { filled: !(bg === 'rgba(0, 0, 0, 0)' || bg === 'transparent'), bg };
    });
    ok(hoyBox && hoyBox.filled, `NEGATIVE TEST — today's failed state really is a filled box, ${hoyBox ? hoyBox.bg : '?'} (the D-19h violation decision 24 recorded)`);
    for (const v of VARIANTS) {
      await set(v, 'bgg_missing');
      const box = await filled('.st');
      const dot = await J(() => { const d = document.querySelector('.st .dot'); if (!d) return null; const r = d.getBoundingClientRect(); return { w: +r.width.toFixed(1), h: +r.height.toFixed(1) }; });
      ok(box === false && dot && dot.w === 8 && dot.h === 8, `${v}: the state is an 8px dot + text with no fill (D-19h) — dot ${dot ? dot.w + '×' + dot.h : 'missing'}`);
    }
  }

  /* ================= 3b. IS THE STATE EVEN ON SCREEN? =================
     The check this suite did not have, and the reason it was 64/65 green while A, B and C were all wrong in
     the same way. Every other guard here asks what the BGG block CONTAINS; none asked whether a reader ever
     reaches it. Found by looking at the screenshots, not by measuring — sketch 072's lesson, repeated: the
     harness measured A's block as the SHORTEST of the three (156.5px) and would have read that as cheapest,
     when the reason it is short is that most of it is off the bottom of the phone.

     Measured at rest (scrollTop 0), against the tab bar rather than the viewport — the tab bar is opaque
     chrome pinned over the scroller, so anything under it is not on screen even though it is "in view". */
  {
    for (const v of VARIANTS) {
      await set(v, 'no_bgg_id');
      const m = await J(() => {
        const st = document.querySelector('.st');
        if (!st) return null;
        const fold = document.querySelector('.tabs').getBoundingClientRect().top;
        const r = st.getBoundingClientRect();
        return { past: +Math.max(0, r.bottom - fold).toFixed(0), top: +r.top.toFixed(0), fold: +fold.toFixed(0) };
      });
      ok(m && m.past === 0,
        `${v}: the reason the page was opened is on screen at rest` +
        (m && m.past ? ` — ${m.past}px BELOW THE FOLD (state at ${m.top}, fold at ${m.fold})` : ''));
    }
  }

  /* ================= 3c. a full-bleed row really is full-bleed =================
     Found by looking, not by measuring. The action row's hairlines stopped 32px short of the right edge
     because a <button> is shrink-to-fit even at `display: flex`, so its negative margins pulled it off the
     left but nothing stretched it to the right (343px against .frow's 375). Every other guard in this file
     asks what a row CONTAINS; none asked how wide its box is, so the suite was green over a visible seam.
     Asserted for every row that uses the -16px bleed, so the next one written fresh cannot repeat it. */
  {
    for (const v of VARIANTS) {
      await set(v, 'bgg_missing');
      const m = await J(() => {
        const bad = [];
        for (const el of document.querySelectorAll('.frow, .arow')) {
          const r = el.getBoundingClientRect();
          if (Math.abs(r.left) > 0.5 || Math.abs(r.right - 375) > 0.5) bad.push(`${el.className.split(' ')[0]} ${r.left.toFixed(0)}–${r.right.toFixed(0)}`);
        }
        return bad;
      });
      ok(m.length === 0, `${v}: every full-bleed row spans the whole 375 width${m.length ? ' — ' + [...new Set(m)].join(', ') : ''}`);
    }
  }

  /* ================= 4. the club spine survives (decision 33) =================
     A adds `ID de BGG` as a seventh row; B and C leave the spine at six. Whichever wins, the spine must still
     be ONE anatomy with no trailing glyph — that is what decision 33 chose it for and what decision 34 set. */
  {
    for (const v of VARIANTS) {
      await set(v, 'no_bgg_id');
      const m = await J(() => {
        const rows = [...document.querySelectorAll('.frow')];
        return {
          n: rows.length,
          tags: [...new Set(rows.map(r => r.tagName))],
          trailing: [...new Set(rows.map(r => r.querySelector('svg') ? 'glyph' : 'none'))],
          keys: rows.map(r => r.querySelector('.fr-k')?.textContent.trim())
        };
      });
      const want = v === 'A' ? 7 : 6;
      ok(m.n === want, `${v}: club spine has ${m.n} rows (expected ${want}${v === 'A' ? ' — the 7th is the cost of making bgg_id a club field' : ''})`);
      ok(m.tags.length === 1 && m.tags[0] === 'BUTTON', `${v}: ONE row anatomy — every club row is the same element (${m.tags.join(', ')})`);
      ok(m.trailing.length === 1 && m.trailing[0] === 'none', `${v}: no trailing glyph on any club row (decision 34)`);
      if (v === 'A') ok(m.keys.includes('ID de BGG'), `A: the id row is in the club block, labelled "ID de BGG"`);
      else ok(!m.keys.includes('ID de BGG'), `${v}: the id is NOT a club field — admin_changeset's 6 cast fields are untouched`);
    }
  }

  /* ================= 6. the publish gate, now in the action bar =================
     "The app must avoid publishing uncompleted games." `publish_game/1` validates only `:status` today
     (catalog.ex:490), so this rule has no implementation — every variant must obey it identically.
     Round 2 moved it out of an in-page block and into the bar's primary slot, which is also where the
     developer's "one primary that swaps" rule gets asserted. */
  {
    for (const v of VARIANTS) {
      let blocked = 0;
      for (const s2 of ['no_bgg_id', 'bgg_missing', 'failed']) {
        await set(v, s2, 'draft');
        const r = await J(() => {
          const b = document.querySelector('#savebar .btn:not(.ghost)');
          return { label: b ? b.textContent.trim() : null, dis: !!b?.disabled };
        });
        if (r.label === 'Publicar' && r.dis) blocked++;
      }
      ok(blocked === 3, `${v}: Publicar is present and disabled in all 3 broken states (${blocked}/3)`);
      await set(v, 'enriched', 'draft');
      const open = await J(() => {
        const b = document.querySelector('#savebar .btn:not(.ghost)');
        return b ? { label: b.textContent.trim(), dis: !!b.disabled } : null;
      });
      ok(open && open.label === 'Publicar' && !open.dis, `${v}: a clean enriched DRAFT offers Publicar, enabled`);
      /* and the counterpart round 3 added: an already-published game has no primary at all */
      await set(v, 'enriched', 'published');
      const pub = await J(() => ({ bar: document.querySelector('#savebar').classList.contains('on'),
                                   btn: !!document.querySelector('#savebar .btn') }));
      ok(!pub.bar && !pub.btn, `${v}: a clean PUBLISHED game has no bar — there is nothing to save and nothing to publish`);
    }
  }

  /* ================= 6b. ONE primary slot that swaps =================
     The developer's rule: `Guardar` while there are unsaved changes, `Publicar` when there are none — never
     two strong buttons at once, and the bar never changes size. Both halves are asserted, including the
     width, because "never changes size" is the part a later edit would silently break. */
  {
    for (const v of VARIANTS) {
      await set(v, 'enriched', 'draft');
      const clean = await J(() => {
        const bar = document.querySelector('#savebar');
        return { label: bar.querySelector('.btn:not(.ghost)')?.textContent.trim(),
                 strong: bar.querySelectorAll('.btn:not(.ghost)').length,
                 w: +bar.getBoundingClientRect().height.toFixed(1) };
      });
      /* make it dirty through the UI, not by poking state */
      await J(() => document.querySelector('[data-edit="units"]').click());
      await p.waitForTimeout(240);
      await J(() => document.querySelector('[data-step="1"]').click());
      await J(() => document.querySelector('[data-close]')?.click());
      await p.waitForTimeout(240);
      const dirtyState = await J(() => {
        const bar = document.querySelector('#savebar');
        return { label: bar.querySelector('.btn:not(.ghost)')?.textContent.trim(),
                 strong: bar.querySelectorAll('.btn:not(.ghost)').length,
                 w: +bar.getBoundingClientRect().height.toFixed(1) };
      });
      ok(clean.label === 'Publicar' && dirtyState.label === 'Guardar',
        `${v}: the one primary slot swaps — clean "${clean.label}" -> dirty "${dirtyState.label}"`);
      ok(clean.strong === 1 && dirtyState.strong === 1,
        `${v}: never two strong buttons at once (${clean.strong} clean, ${dirtyState.strong} dirty)`);
      ok(Math.abs(clean.w - dirtyState.w) < 0.6,
        `${v}: the bar does not change size when the primary swaps (${clean.w} vs ${dirtyState.w})`);
      await set(v, 'enriched', 'draft');
    }
  }

  /* ================= 6c. the CTA is reachable without scrolling =================
     The developer's actual complaint about round 1: "the CTA at the bottom is hidden, since it needs scroll
     down." Round 1 put the publish gate at the END of the page, so on a 49-game editor it sat ~772px down a
     740px screen. The bar is pinned above the tab bar, so this should now hold by construction — asserted
     anyway, because "by construction" is how the round-1 fold bug survived 64 green checks. */
  {
    /* Round 3 changed what this check must ask. A PUBLISHED broken game now has no bar at all — nothing to
       save, nothing to publish — and that is correct, not a regression, so asserting "the CTA is reachable"
       there would be asserting that the bar should exist when it has nothing in it. The claim that still
       matters is: WHEN there is a primary, it is reachable without scrolling. Checked on a draft, which is
       the case that has one. */
    for (const v of VARIANTS) {
      await set(v, 'no_bgg_id', 'draft');
      const m = await J(() => {
        const bar = document.querySelector('#savebar');
        const btn = bar.querySelector('.btn:not(.ghost)');
        if (!btn) return { none: true };
        const r = btn.getBoundingClientRect();
        const tabs = document.querySelector('.tabs').getBoundingClientRect();
        return { top: +r.top.toFixed(0), bottom: +r.bottom.toFixed(0), tabsTop: +tabs.top.toFixed(0),
                 onScreen: r.top >= 0 && r.bottom <= 740, clearsTabs: r.bottom <= tabs.top + 0.5 };
      });
      ok(!m.none && m.onScreen && m.clearsTabs,
        `${v}: the primary CTA is on screen at rest without scrolling (bottom ${m.bottom}, tab bar at ${m.tabsTop})`);
    }
  }

  /* ================= 6d. THE COLLISION: Descartar vs the remedy =================
     The round's deciding measurement, predicted before building rather than discovered after. While dirty,
     the secondary slot is already `Descartar`. A broken game with unsaved changes wants that one slot to be
     both `Descartar` and the remedy. D1 and D3 put the remedy in the bar and therefore have to give it up;
     D2 never had the problem, because its remedy lives beside the state up top.
     Measured as: with unsaved changes on a broken game, is the remedy reachable AT ALL without discarding? */
  {
    for (const v of VARIANTS) {
      await set(v, 'no_bgg_id');
      /* dirty it through the UI */
      await J(() => document.querySelector('[data-edit="units"]').click());
      await p.waitForTimeout(240);
      await J(() => document.querySelector('[data-step="1"]').click());
      await J(() => document.querySelector('[data-close]')?.click());
      await p.waitForTimeout(240);
      const m = await J(() => {
        const bar = document.querySelector('#savebar');
        const inBar = !!bar.querySelector('[data-act="open-link"]');
        const inPage = !!document.querySelector('#main [data-act="open-link"]');
        const el = document.querySelector('#main [data-act="open-link"]');
        const fold = document.querySelector('.tabs').getBoundingClientRect().top;
        return { inBar, inPage, dirty: /Cambios sin guardar/.test(bar.textContent),
                 discard: !!bar.querySelector('#discard'),
                 visible: el ? el.getBoundingClientRect().bottom <= fold : false };
      });
      ok(m.dirty && m.discard, `${v}: with unsaved changes the bar shows Descartar and says so`);
      ok(m.inBar || m.inPage,
        `${v}: and the remedy is still reachable${m.inBar ? ' (in the bar)' : m.inPage ? ' (up top, beside the state)' : ' — LOST: Descartar took the only slot'}`);
      if (m.inPage) ok(m.visible, `${v}: and it is still on screen while dirty`);
      await set(v, 'no_bgg_id');
    }
  }

  /* ================= 6e. a sheet's change reaches the row behind it =================
     Found in a screenshot: after stepping Copias up and closing the sheet, the row still read "Copias 1"
     while the bar already said "Cambios sin guardar". The stepper commits into G and refreshes only the bar
     (re-rendering under an open sheet would tear it out from under the finger); closing never re-rendered.
     Inherited verbatim from 072, whose own 49/49 harness did not assert it. Asserted here so it cannot
     return, and as INK rather than as state — the point is what the reader sees, not what G holds. */
  {
    for (const v of VARIANTS) {
      await set(v, 'no_bgg_id');
      const before = await J(() => [...document.querySelectorAll('.frow')]
        .find(r => r.querySelector('.fr-k')?.textContent.trim() === 'Copias')?.querySelector('.fr-v')?.textContent.trim());
      await J(() => document.querySelector('[data-edit="units"]').click());
      await p.waitForTimeout(240);
      await J(() => document.querySelector('[data-step="1"]').click());
      await J(() => document.querySelector('[data-close]').click());
      await p.waitForTimeout(240);
      const after = await J(() => [...document.querySelectorAll('.frow')]
        .find(r => r.querySelector('.fr-k')?.textContent.trim() === 'Copias')?.querySelector('.fr-v')?.textContent.trim());
      ok(before === '1' && after === '2',
        `${v}: a stepper change in the sheet reaches the row behind it (${before} -> ${after})`);
      await set(v, 'no_bgg_id');
    }
  }

  /* ================= 6f. the waiting screen lets you leave =================
     The developer's call, and its whole justification: enrichment is an Oban job on a queue with CONCURRENCY
     1 and `attempt * 30` backoff, so with 49 games to repair the wait is real AND it keeps running whether
     or not this page is open. The screen therefore owes three things — it must say so, it must not hold a
     save bar (there is nothing to save and nothing to discard), and the way out must be live, not merely
     present. The tab bar is that way out, so its buttons are checked for real hit area, not existence. */
  {
    for (const v of VARIANTS) {
      await set(v, 'pending');
      const m = await J(() => {
        const w = document.querySelector('.waiting');
        const bar = document.querySelector('#savebar');
        const tabs = [...document.querySelectorAll('.tabs .tab')];
        const covered = tabs.filter(t => {
          const r = t.getBoundingClientRect();
          const el = document.elementFromPoint(r.left + r.width / 2, r.top + r.height / 2);
          return !(el === t || t.contains(el));
        });
        return {
          hasWait: !!w,
          /* textContent carries the SOURCE's line breaks, so a phrase that wraps across two lines in the
             template contains "\n      " where the regex expects a space. Collapse whitespace first — a
             guard that reads rendered text must normalise it, or it is asserting about source formatting. */
          saysLeave: /salgas de esta pantalla/.test((w?.textContent || '').replace(/\s+/g, ' ')),
          barShown: bar.classList.contains('on'),
          noSkeleton: document.querySelectorAll('.sk').length === 0,
          tabsCovered: covered.length,
          editable: document.querySelectorAll('#main [data-edit]').length
        };
      });
      ok(m.hasWait && m.saysLeave, `${v}: the waiting screen says the work continues if you leave`);
      ok(!m.barShown, `${v}: no action bar while waiting — nothing to save, nothing to discard`);
      ok(m.noSkeleton, `${v}: and no skeleton imitating the eleven facts that do not exist yet`);
      ok(m.tabsCovered === 0, `${v}: all 5 tab-bar destinations are actually hittable, not just present (${m.tabsCovered} covered)`);
      ok(m.editable === 0, `${v}: nothing is editable mid-fetch — the incoming write would overwrite it`);
    }
  }

  /* ================= 6g. ONE "Guardar" in the editor, and it is the bar's =================
     Round 3's question, from the developer: "should I have bottom sheet AND save for fields? isn't that
     contradictory with the save at the bottom?" Probed on the built page before any variant existed:

       sheet button said:      "Guardar"
       bar immediately after:  "Cambios sin guardar · Descartar · Guardar"

     Pressing Guardar and being told "Cambios sin guardar" in the same breath. Asserted as a COUNT of the
     word across everything visible, because the defect is not which button is wrong — it is that the same
     word names two different operations on one screen. */
  {
    await set('HOY', 'enriched', 'draft');
    /* HOY has no sheets to open, so the baseline here is round 2's own behaviour, reproduced: the probe
       above is the negative test, and it is recorded in the README rather than re-run, since the losing
       wording no longer exists in the page to measure. */
    for (const v of VARIANTS) {
      await set(v, 'enriched', 'draft');
      await J(() => document.querySelector('[data-edit="name"]').click());
      await p.waitForTimeout(260);
      const m = await J(() => {
        const sheet = document.getElementById('sheet');
        const bar = document.getElementById('savebar');
        const count = t => ((t || '').match(/Guardar/g) || []).length;
        return { inSheet: count(sheet.textContent), inBar: count(bar.textContent),
                 sheetBtn: sheet.querySelector('[data-commit]')?.textContent.trim() || null };
      });
      ok(m.inSheet === 0, `${v}: the word "Guardar" appears 0 times inside a field sheet (${m.inSheet})`);
      ok(m.sheetBtn === null, `${v}: the sheet carries no commit button at all (${m.sheetBtn})`);
      await J(() => document.querySelector('[data-close]').click());
      await p.waitForTimeout(200);
    }
  }

  /* ================= 6h. how many commit anatomies do the six sheets have? =================
     Decision 33 chose the spine for having ONE row anatomy. The sheets had THREE ways to commit — a Guardar
     button (Nombre, Descripción), commit-on-tap (Nivel, Estante, Expansión), and a live stepper (Copias) —
     which is the same defect one level down. F2 collapses it to one; F1 leaves two. Counted, not asserted
     to a number, so whichever wins the count is on the record. */
  {
    for (const v of VARIANTS) {
      await set(v, 'enriched', 'draft');
      const kinds = await J(() => {
        const out = [];
        for (const k of ['name', 'weight_band', 'units', 'shelf_id', 'is_expansion', 'description']) {
          document.querySelector(`[data-edit="${k}"]`).click();
          const sh = document.getElementById('sheet');
          out.push(sh.querySelector('[data-commit]') ? 'button' : sh.querySelector('[data-step]') ? 'live' : 'tap');
          document.querySelector('[data-close]').click();
        }
        return out;
      });
      await p.waitForTimeout(200);
      /* The first version of this counted 'button' / 'tap' / 'live' as three commit anatomies and scored F2
         at 2, which is the wrong axis: 'tap' and 'live' differ in how the sheet CLOSES (an option picks and
         dismisses; the stepper stays open for a second press), not in how the value commits — neither has an
         explicit commit. The axis this round is actually about is whether a sheet carries a commit BUTTON,
         so that is what is asserted; the closing difference is logged, not scored. */
      const explicit = kinds.filter(k => k === 'button').length;
      const uniq = [...new Set(kinds)];
      log.push(`INFO ${v} sheets with an explicit commit button: ${explicit}/6 · closing styles: ${uniq.join(', ')}`);
      ok(explicit === 0,
        `${v}: ${explicit} of 6 sheets carry a commit button — one commit idiom, and one "Guardar" in the editor`);
    }
  }

  /* ================= 6i. D-19h in the head — a status is a dot, never a pill =================
     The shipped editor renders the lifecycle status as `badge badge-warning` / `badge-success` /
     `badge-neutral` (`form.ex:212-214, 253`) — daisyUI pills. D-19h forbids it in as many words, and this
     is the third instance of the same family after the list-row pill and the alert box.
     Also asserted: "sin guardar" does NOT join it. Lifecycle status is durable and shared; unsaved changes
     are transient and local, and the bar already says it. */
  {
    for (const v of VARIANTS) {
      for (const [cy, label] of [['published', 'Publicado'], ['draft', 'Borrador'], ['retired', 'Retirado']]) {
        await set(v, 'enriched', cy);
        const m = await J(() => {
          const st = document.querySelector('.gh-st');
          if (!st) return null;
          const dot = st.querySelector('.dot');
          const bg = getComputedStyle(st).backgroundColor;
          const r = dot?.getBoundingClientRect();
          return { text: st.textContent.replace(/\s+/g, ' ').trim(),
                   filled: !(bg === 'rgba(0, 0, 0, 0)' || bg === 'transparent'),
                   dot: r ? `${r.width}x${r.height}` : null,
                   radius: getComputedStyle(st).borderRadius };
        });
        ok(m && m.text.startsWith(label) && m.dot === '8x8' && !m.filled,
          `${v}/${cy}: the head reads "● ${label}" as a dot + text with no fill (D-19h), not a badge pill`);
      }
      /* and it stays a lifecycle status when the page is dirty */
      await set(v, 'enriched', 'published');
      await J(() => document.querySelector('[data-edit="units"]').click());
      await p.waitForTimeout(240);
      await J(() => document.querySelector('[data-step="1"]').click());
      await J(() => document.querySelector('[data-close]').click());
      await p.waitForTimeout(240);
      const m2 = await J(() => ({
        head: document.querySelector('.gh-st').textContent.replace(/\s+/g, ' ').trim(),
        bar: document.getElementById('savebar').textContent.replace(/\s+/g, ' ').trim()
      }));
      ok(!/sin guardar/i.test(m2.head) && /sin guardar/i.test(m2.bar),
        `${v}: "sin guardar" lives in the bar, not the head — one slot, one kind of thing ("${m2.head}")`);
      await set(v, 'enriched', 'published');
    }
  }

  /* ================= 7. the remedy fits the state =================
     The defect this round exists for: `Reintentar` is gated on `failed` (0 rows) while the 49 that are
     actually broken get nothing. Retry must NOT be the offer for `no_bgg_id` (nothing to retry — bgg_id is
     NULL) nor for `bgg_missing` (the id does not resolve; retrying fetches the same dead id again). */
  {
    /* The bar is a sibling of #main inside .device, not a child of it. Reading only #main's text made the
       remedy invisible in exactly the two variants that put it in the bar — the check was measuring the
       page and calling it the screen. Read both. */
    const offer = () => J(() => {
      const t = (document.querySelector('#main .variant')?.textContent || '') + ' ' + (document.querySelector('#savebar')?.textContent || '');
      return { retry: /Reintentar/.test(t), idWay: !!document.querySelector('[data-act="open-link"]') };
    });
    await set('HOY', 'no_bgg_id');
    const h = await offer();
    ok(!h.retry && !h.idWay, `NEGATIVE TEST — today a "sin ID" game is offered nothing at all: no retry, no way to set an id`);
    for (const v of VARIANTS) {
      await set(v, 'no_bgg_id');
      const a = await offer();
      ok(a.idWay && !a.retry, `${v}: "sin ID" offers a way to set the id, and does NOT offer a pointless Reintentar`);
      await set(v, 'bgg_missing');
      const b = await offer();
      ok(b.idWay && !b.retry, `${v}: "ID inválido" offers CORRECTING the id, not retrying a dead one`);
      await set(v, 'failed');
      const c = await offer();
      ok(c.retry, `${v}: "falló" — the one state where Reintentar is the right remedy — offers it`);
    }
  }

  /* ================= 8. the hint carries a real, reachable BGG link ================= */
  {
    for (const v of VARIANTS) {
      await set(v, 'no_bgg_id');
      if (v !== 'B') await J(() => document.querySelector('[data-edit="bgg_id"], [data-act="open-link"]')?.click());
      await p.waitForTimeout(280);
      const m = await J(() => {
        const a = document.querySelector('.hint a');
        if (!a) return null;
        const r = a.getBoundingClientRect();
        /* whatever is actually covering the bottom of the screen right now: the keyboard if it is up, the
           tab bar otherwise */
        const kb = document.querySelector('.kbd-sim');
        const kbUp = kb && getComputedStyle(kb).display !== 'none';
        const floor = kbUp ? kb.getBoundingClientRect().top : document.querySelector('.tabs').getBoundingClientRect().top;
        return { href: a.getAttribute('href'), blank: a.getAttribute('target') === '_blank',
          noopener: (a.getAttribute('rel') || '').includes('noopener'),
          h: +r.height.toFixed(1),
          /* THE FLOOR IS THE KEYBOARD, NOT THE VIEWPORT.
             The first version of this check read `r.bottom <= 740` and passed A and C — while the
             screenshot showed the number pad covering the field, the hint, the link and the commit button,
             with only the sheet's title still visible. Measuring against the viewport measures a phone
             nobody is holding: committing an id means typing, typing raises the keyboard, so the keyboard is
             up at the exact moment the hint is supposed to be read. 292px of it (the toolkit's number).
             Same failure shape as sketch 072's contrast guard — a bar set against the wrong reference
             passes the thing it was written to catch. */
          floor: +floor.toFixed(1),
          onScreen: r.top >= 0 && r.bottom <= floor,
          past: +Math.max(0, r.bottom - floor).toFixed(1),
          example: /155426/.test(document.querySelector('.ex')?.textContent || '') };
      });
      ok(m && /boardgamegeek\.com/.test(m.href || ''), `${v}: the hint links to boardgamegeek.com (${m ? m.href : 'no link'})`);
      ok(m && m.blank && m.noopener, `${v}: the link opens in a new tab with rel=noopener — the editor has unsaved state behind it`);
      ok(m && m.example, `${v}: and it SHOWS the operation with a real url → id example, rather than naming it`);
      /* This is the round's deciding measurement, so it is asserted rather than merely reported. A and C
         offer the hint INSIDE a sheet, which is anchored to the bottom of the viewport and therefore always
         on screen. B offers it inline, underneath a 6-row club spine — so the instruction a first-time user
         most needs sits below the fold on the device the admin is actually used on. */
      ok(m && m.onScreen, `${v}: the hint is on screen where it is offered${m && m.past ? ` — MISSES by ${m.past}px at 375×740` : ''}`);
      await J(() => { document.querySelector('[data-close]')?.click(); });
      await p.waitForTimeout(220);
    }
  }

  /* ================= 9. taps to fix, counted rather than reasoned about ================= */
  {
    const taps = {};
    for (const v of VARIANTS) {
      await set(v, 'no_bgg_id');
      let n = 0;
      if (v === 'B') {
        await J(() => { const i = document.querySelector('#idfield'); i.focus(); i.value = '155426'; i.dispatchEvent(new Event('input', { bubbles: true })); });
        n = 1; /* focus the field */
        await J(() => document.querySelector('[data-act="link"]').click()); n++;
      } else {
        await J(() => document.querySelector('[data-edit="bgg_id"], [data-act="open-link"]').click()); n++;
        await p.waitForTimeout(260);
        await J(() => { const i = document.querySelector('#s-bgg'); i.value = '155426'; i.dispatchEvent(new Event('input', { bubbles: true })); });
        await J(() => document.querySelector('[data-commit="bgg_id"]').click()); n++;
      }
      await p.waitForTimeout(160);
      const landed = await J(() => ({ st: !!document.querySelector('.waiting'), id: /155426/.test(document.querySelector('.gh-meta')?.textContent || '') }));
      taps[v] = n;
      ok(landed.st && landed.id, `${v}: committing an id lands on "trayendo datos" and the head shows BGG 155426 — the fetch is an Oban job, so pending is the honest response`);
    }
    log.push('INFO taps to fix a "sin ID" game — ' + VARIANTS.map(v => `${v} ${taps[v]}`).join(' · '));
  }

  /* ================= 10. what the block costs, per variant per state ================= */
  {
    const rows = [];
    for (const v of ['HOY', ...VARIANTS]) {
      for (const s of STATES) {
        await set(v, s);
        /* D drops the BGG block entirely when broken, so there is no "DATOS DE BGG" label to measure from.
           Measuring "the block" would then be measuring nothing and reporting 0 as if it were cheap. What is
           actually comparable across all four is the WHOLE PAGE: how tall the editor is in that state. */
        const h = await J(() => {
          const main = document.querySelector('#main .variant');
          return main ? +main.getBoundingClientRect().height.toFixed(1) : null;
        });
        rows.push([v, s, h]);
      }
    }
    const fmt = v => STATES.map(s => String(rows.find(r => r[0] === v && r[1] === s)[2]).padStart(7)).join('');
    log.push('INFO alto total de la página  ' + STATES.map(s => s.padStart(7).slice(0, 7)).join(''));
    for (const v of ['HOY', ...VARIANTS]) log.push(`INFO   ${v.padEnd(3)}                   ` + fmt(v));
    /* The 386 healthy editors must not pay for a feature only 49 need. This is where A's seventh row shows
       up as a cost rather than as a design choice: making `bgg_id` a club field puts it on EVERY editor,
       including the 386 where it is a number nobody will ever retype. B, C and D touch the enriched page not
       at all. */
    const base = rows.find(r => r[0] === 'HOY' && r[1] === 'enriched')[2];
    const pays = VARIANTS.filter(v => rows.find(r => r[0] === v && r[1] === 'enriched')[2] !== base)
      .map(v => `${v} +${(rows.find(r => r[0] === v && r[1] === 'enriched')[2] - base).toFixed(1)}px`);
    ok(pays.length === 0, `the 386 healthy editors pay nothing for this feature` + (pays.length ? ` — but ${pays.join(', ')}` : ''));
  }

  /* ================= 11. touch floor and overflow, both themes ================= */
  {
    for (const t of ['light', 'dark']) {
      await theme(t);
      let small = [], oflow = 0;
      for (const v of VARIANTS) for (const s of STATES) {
        await set(v, s);
        const m = await J(() => {
          const bad = [];
          for (const el of document.querySelectorAll('#main button, #main input, #main a')) {
            const r = el.getBoundingClientRect();
            if (r.width === 0) continue;
            /* an inline link inside a paragraph is text, not a control surface — it is exempt from the 44px
               floor by the same reasoning D-19 applies to a caption's caret, and it is the ONLY exemption */
            if (el.tagName === 'A' && el.closest('.hint')) continue;
            if (r.height < 44) bad.push(el.className || el.tagName);
          }
          return { bad, oflow: +(document.documentElement.scrollWidth - 375).toFixed(1) };
        });
        small.push(...m.bad); oflow = Math.max(oflow, m.oflow);
      }
      ok(small.length === 0, `${t}: every control in the BGG block clears the 44px touch floor (${small.length} under)`);
      ok(oflow <= 0, `${t}: no horizontal overflow at 375 across all 15 variant×state combinations (${oflow}px)`);
    }
    await theme('light');
  }

  /* ================= 12. the state reads in BOTH themes =================
     072's round 2 found that `--color-accent-text` resolves to #E3D9F9 in dark — 1.17:1 from body text — so a
     tint-based signal had no dark answer at all. The same trap applies to a coloured status dot: it must be
     distinguishable from the page it sits on, measured in both themes. Contrast ratio cannot see hue, so the
     dot is measured as CIE76 dE against the background, the bar decision 35 established. */
  {
    const dE = (a, b) => {
      const f = c => { c /= 255; return c > .04045 ? Math.pow((c + .055) / 1.055, 2.4) : c / 12.92; };
      const lab = ([r, g, bb]) => {
        const R = f(r), G2 = f(g), B = f(bb);
        let X = (R * .4124 + G2 * .3576 + B * .1805) / .95047, Y = R * .2126 + G2 * .7152 + B * .0722, Z = (R * .0193 + G2 * .1192 + B * .9505) / 1.08883;
        const k = t => t > .008856 ? Math.cbrt(t) : 7.787 * t + 16 / 116;
        X = k(X); Y = k(Y); Z = k(Z);
        return [116 * Y - 16, 500 * (X - Y), 200 * (Y - Z)];
      };
      const [l1, a1, b1] = lab(a), [l2, a2, b2] = lab(b);
      return Math.sqrt((l1 - l2) ** 2 + (a1 - a2) ** 2 + (b1 - b2) ** 2);
    };
    const px = s => s.match(/\d+/g).slice(0, 3).map(Number);
    for (const t of ['light', 'dark']) {
      await theme(t);
      await set('F2', 'bgg_missing');
      const c = await J(() => ({ dot: getComputedStyle(document.querySelector('.st .dot')).backgroundColor, bg: getComputedStyle(document.body).getPropertyValue('--color-bg') || getComputedStyle(document.querySelector('#main')).backgroundColor }));
      const bgc = await J(() => { const d = document.createElement('div'); d.style.background = 'var(--color-bg)'; document.body.appendChild(d); const v = getComputedStyle(d).backgroundColor; d.remove(); return v; });
      const d = +dE(px(c.dot), px(bgc)).toFixed(1);
      ok(d >= 20, `${t}: the danger dot separates from the page ground — dE ${d} (bar 20, decision 35)`);
    }
    await theme('light');
  }

  /* ================= shots ================= */
  {
    for (const v of ['HOY', ...VARIANTS]) {
      for (const s of ['no_bgg_id', 'bgg_missing']) {
        await set(v, s);
        await p.screenshot({ path: path.join(OUT, `${v}-${s}-375x740.png`) });
      }
    }
    await theme('dark'); await set('F2', 'bgg_missing');
    await p.screenshot({ path: path.join(OUT, 'D-bgg_missing-dark.png') });
    await theme('light');
    /* the waiting screen — the developer's call over a skeleton */
    for (const v of VARIANTS) { await set(v, 'pending'); await p.screenshot({ path: path.join(OUT, `${v}-esperando.png`) }); }
    /* the collision, drawn: a broken game with unsaved changes */
    for (const v of VARIANTS) {
      await set(v, 'no_bgg_id');
      await J(() => document.querySelector('[data-edit="units"]').click());
      await p.waitForTimeout(240);
      await J(() => document.querySelector('[data-step="1"]').click());
      await J(() => document.querySelector('[data-close]')?.click());
      await p.waitForTimeout(260);
      await p.screenshot({ path: path.join(OUT, `${v}-roto-con-cambios.png`) });
    }
    await set('F2', 'no_bgg_id');
    await J(() => document.querySelector('[data-act="open-link"]').click());
    await p.waitForTimeout(320);
    await p.screenshot({ path: path.join(OUT, 'C-hoja-del-id.png') });
  }

  ok(errs.length === 0, `no page errors (${errs.length})` + (errs.length ? ': ' + errs.join(' | ') : ''));
  await browser.close();

  const pass = log.filter(l => l.startsWith('PASS')).length, fail = log.filter(l => l.startsWith('FAIL')).length;
  console.log(log.join('\n'));
  console.log(`\n${pass}/${pass + fail} checks passed · shots in ${OUT}`);
  process.exit(fail ? 1 : 0);
})();
