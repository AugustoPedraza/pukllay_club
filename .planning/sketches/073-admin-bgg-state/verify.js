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

const VARIANTS = ['A', 'B', 'C', 'D'];
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
  const set = async (v, s) => {
    await J(([vv, ss]) => {
      document.querySelector(`[data-var="${vv}"]`).click();
      document.querySelector(`[data-st="${ss}"]`).click();
      document.getElementById('scroller').scrollTop = 0;
    }, [v, s]);
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

  /* ================= 5. the key/value pair actually stacks =================
     072's real lesson: its harness was fully green while the page read "NombreBrass: Birmingham", because
     height/contrast/hit-box checks never ask where ink sits RELATIVE to its neighbour. Measured as ink via
     Range rects, on A's new seventh row — the one row 072 never had. */
  {
    await set('A', 'no_bgg_id');
    const m = await J(() => {
      const row = [...document.querySelectorAll('.frow')].find(r => r.querySelector('.fr-k')?.textContent.trim() === 'ID de BGG');
      if (!row) return null;
      const ink = el => { const r = document.createRange(); r.selectNodeContents(el); const b = r.getBoundingClientRect(); return { top: b.top, bottom: b.bottom, left: b.left }; };
      const k = ink(row.querySelector('.fr-k')), v = ink(row.querySelector('.fr-v'));
      return { gap: +(v.top - k.bottom).toFixed(2), sameLeft: Math.abs(v.left - k.left) < 0.6, stacked: v.top >= k.bottom - 0.5 };
    });
    ok(m && m.stacked, `A: the id row's value sits BELOW its label, measured as ink (gap ${m ? m.gap : '?'}px)`);
    ok(m && m.sameLeft, `A: both lines start on the same 16 keyline`);
  }

  /* ================= 6. the publish gate =================
     "The app must avoid publishing uncompleted games." `publish_game/1` validates only `:status` today
     (catalog.ex:490), so this rule has no implementation — every variant must obey it identically. */
  {
    for (const v of VARIANTS) {
      let allBlocked = true, reasons = 0;
      for (const s of ['no_bgg_id', 'bgg_missing', 'failed', 'pending']) {
        await set(v, s);
        const r = await J(() => {
          const b = document.querySelector('.pubbar .btn');
          return { dis: !!b?.disabled, why: document.querySelector('.pubbar .why')?.textContent.trim() || '' };
        });
        if (!r.dis) allBlocked = false;
        if (r.why) reasons++;
      }
      await set(v, 'enriched');
      const open = await J(() => !document.querySelector('.pubbar .btn')?.disabled);
      ok(allBlocked && open, `${v}: Publicar is blocked in all 4 incomplete states and open once BGG answered`);
      ok(reasons === 4, `${v}: and every blocked state says WHY (${reasons}/4)`);
    }
  }

  /* ================= 7. the remedy fits the state =================
     The defect this round exists for: `Reintentar` is gated on `failed` (0 rows) while the 49 that are
     actually broken get nothing. Retry must NOT be the offer for `no_bgg_id` (nothing to retry — bgg_id is
     NULL) nor for `bgg_missing` (the id does not resolve; retrying fetches the same dead id again). */
  {
    const offer = () => J(() => {
      const t = (document.querySelector('#main .variant')?.textContent || '');
      return { retry: /Reintentar/.test(t), idWay: !!document.querySelector('[data-edit="bgg_id"], #idfield, [data-act="open-link"]') };
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
      const landed = await J(() => ({ st: !!document.querySelector('.st.wait'), id: /155426/.test(document.querySelector('.gh-meta')?.textContent || '') }));
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
      await set('A', 'bgg_missing');
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
    await theme('dark'); await set('D', 'bgg_missing');
    await p.screenshot({ path: path.join(OUT, 'D-bgg_missing-dark.png') });
    await theme('light');
    await set('D', 'no_bgg_id');
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
