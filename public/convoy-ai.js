// Convoy AI assistant for Route Plans and Stop Library.
// Scripted intent matching stands in for the chat model. Every proposal is built from existing
// actions (move stop, reorder, merge, add stop) and timed by RoutingEngine.retime with the OSRM road matrix.
(function () {
  const RE = () => window.RoutingEngine;
  const OSRM = () => (window.CONVOY_CONFIG && window.CONVOY_CONFIG.osrmBase) || 'https://router.project-osrm.org';
  const plural = (n, w) => `${n} ${w}${n === 1 ? '' : 's'}`;
  const M = s => Math.round(s / 60);
  const hv = (a, b) => { const E = 6371e3, r = Math.PI / 180, dl = (b[0] - a[0]) * r, dg = (b[1] - a[1]) * r; const x = Math.sin(dl / 2) ** 2 + Math.cos(a[0] * r) * Math.cos(b[0] * r) * Math.sin(dg / 2) ** 2; return 2 * E * Math.asin(Math.sqrt(x)); };
  const AREAS = { PR: 'Pasir Ris', TM: 'Tampines', BD: 'Bedok', HG: 'Hougang', PG: 'Punggol', MP: 'Marine Parade', GL: 'Geylang', KL: 'Kallang', SE: 'Serangoon', PL: 'Paya Lebar', TP: 'Toa Payoh', AM: 'Ang Mo Kio', SK: 'Sengkang', BS: 'Bishan', CH: 'Changi', RC: 'Rochor', NV: 'Novena', QT: 'Queenstown' };
  const sz = id => String(id || '').split('-')[0];
  const areaOf = id => AREAS[String(id || '').slice(0, 2)] || sz(id);

  function S(c) { return c.state.ai || { open: false, threads: { plans: [], library: [] }, props: {}, draft: '', busy: false, busyTxt: '' }; }
  function set(c, o, cb) { c.setState(st => { const a = st.ai || S(c); return { ai: Object.assign({}, a, typeof o === 'function' ? o(a) : o) }; }, cb); }
  function ctx(c) { return c.state.view === 'routing' ? 'plans' : 'library'; }
  function say(c, cx, lines, extra) { set(c, a => ({ busy: false, threads: Object.assign({}, a.threads, { [cx]: a.threads[cx].concat([Object.assign({ role: 'ai', lines: lines.map(l => typeof l === 'string' ? { t: l } : l) }, extra || {})]) }) })); }
  function addProp(c, p) {
    set(c, a => { const props = Object.assign({}, a.props); Object.values(props).forEach(x => { if (x.cx === p.cx && (x.status === 'pending' || x.status === 'editing')) props[x.id] = Object.assign({}, x, { status: 'replaced' }); }); props[p.id] = p; return { props }; });
  }
  function setP(c, id, o) { set(c, a => ({ props: Object.assign({}, a.props, { [id]: Object.assign({}, a.props[id], o) }) })); }
  function live(c, cx) { return Object.values(S(c).props).find(p => p.cx === cx && (p.status === 'pending' || p.status === 'editing')); }

  // ---------- route engine helpers ----------
  const mx = c => c.mxCache && c.mxCache.mx;
  const toEd = x => ({ gid: x.gid, uid: x.uid, stopId: x.stopId, name: x.name, part: x.part, pid: x.pid, sfx: x.sfx || '', ll: x.ll, riders: x.riders.slice() });
  const load = st => st.reduce((a, s) => a + s.riders.length, 0);
  function span(c, pl, r, stops) { if (!stops.length) return 0; return RE().retime(r, stops.map(x => Object.assign({}, x, { n: x.riders.length })), { params: pl.result.params, matrix: mx(c) }).span; }
  function ins(c, pl, r, st, s) { let bt = Infinity, bo = null; for (let i = 0; i <= st.length; i++) { const q = st.slice(0, i).concat([s], st.slice(i)); const t = span(c, pl, r, q); if (t < bt) { bt = t; bo = q; } } return bo; }
  function best(c, pl, r, stops) {
    let b = stops.slice(), bt = span(c, pl, r, b), imp = true, g = 0;
    while (imp && g++ < 6) { imp = false;
      for (let i = 0; i < b.length; i++) for (let j = 0; j < b.length; j++) { if (i === j) continue; const q = b.slice(); const [x] = q.splice(i, 1); q.splice(j, 0, x); const t = span(c, pl, r, q); if (t < bt - 5) { bt = t; b = q; imp = true; } }
      for (let i = 0; i < b.length - 1; i++) for (let j = i + 1; j < b.length; j++) { const q = b.slice(0, i).concat(b.slice(i, j + 1).reverse(), b.slice(j + 1)); const t = span(c, pl, r, q); if (t < bt - 5) { bt = t; b = q; imp = true; } }
    }
    return { stops: b, span: bt };
  }
  const near = (a, b, m) => a.some(x => b.some(y => hv(x.ll, y.ll) < m));
  function curOf(c, pl) { const cur = {}; c.res(pl).routes.forEach(r => { cur[r.id] = { r, stops: r.stops.map(toEd) }; }); return cur; }

  function shorten(c, pl, rid, tgt) {
    const lk = new Set(pl.locked || []), cur = curOf(c, pl), me = cur[rid], T = tgt * 60, base = {};
    Object.keys(cur).forEach(k => { base[k] = span(c, pl, cur[k].r, cur[k].stops); });
    const o0 = best(c, pl, me.r, me.stops), reordered = o0.span < base[rid] - 30; if (reordered) me.stops = o0.stops;
    let sp = reordered ? o0.span : base[rid]; const moves = [];
    for (let it = 0; it < 5 && sp > T; it++) {
      const groups = {}; me.stops.forEach(s => (groups[sz(s.stopId)] = groups[sz(s.stopId)] || []).push(s));
      const cands = Object.values(groups).filter(g => g.length > 1 && g.length < me.stops.length).concat(me.stops.map(s => [s]));
      let bc = null;
      for (const cand of cands) {
        const ids = new Set(cand.map(s => s.gid)), rest = me.stops.filter(s => !ids.has(s.gid)); if (!rest.length) continue;
        const tr = span(c, pl, me.r, rest); if (tr >= sp - 60) continue;
        const cn = load(cand);
        for (const oid of Object.keys(cur)) {
          const o = cur[oid]; if (oid === rid || lk.has(oid) || load(o.stops) + cn > o.r.studentSeats || !near(cand, o.stops, 3000)) continue;
          let q = o.stops; cand.forEach(s => { q = ins(c, pl, o.r, q, s); });
          const to = span(c, pl, o.r, q), t0 = span(c, pl, o.r, o.stops); if (to > T) continue;
          const score = Math.max(tr, T - 480) + (to - t0) * 0.6 + (tr > T ? 1200 : 0);
          if (!bc || score < bc.score) bc = { score, cand, oid, q, rest };
        }
      }
      if (!bc) break;
      bc.cand.forEach(s => moves.push({ gid: s.gid, label: s.stopId + s.sfx, name: s.name, n: s.riders.length, from: rid, to: bc.oid, on: true }));
      me.stops = best(c, pl, me.r, bc.rest).stops; cur[bc.oid].stops = best(c, pl, cur[bc.oid].r, bc.q).stops; sp = span(c, pl, me.r, me.stops);
    }
    return { moves, reordered };
  }
  function merge(c, pl, tgt) {
    const lk = new Set(pl.locked || []), R = c.res(pl).routes.filter(r => !lk.has(r.id)), T = tgt * 60, ctr = r => [r.stops.reduce((a, s) => a + s.ll[0], 0) / r.stops.length, r.stops.reduce((a, s) => a + s.ll[1], 0) / r.stops.length];
    let bb = null;
    R.slice().sort((a, b) => a.load - b.load).slice(0, 4).forEach(a => {
      R.filter(b => b !== a && a.load + b.load <= b.studentSeats).sort((x, y) => hv(ctr(a), ctr(x)) - hv(ctr(a), ctr(y))).slice(0, 3).forEach(b => {
        const q = best(c, pl, b, b.stops.map(toEd).concat(a.stops.map(toEd))); if (q.span > T) return;
        const d = q.span - b.span; if (!bb || d < bb.d) bb = { a, b, d, span: q.span };
      });
    });
    return bb;
  }
  const memo = {};
  function build(c, pl, p) {
    const k = p.id + '|' + p.moves.map(m => m.on ? 1 : 0).join('') + '|' + (pl.at || '') + JSON.stringify(pl.edits || {}).length;
    if (memo[p.id] && memo[p.id].k === k) return memo[p.id].v;
    const cur = curOf(c, pl), aff = new Set(p.reorder || []);
    p.moves.filter(m => m.on).forEach(m => { const f = cur[m.from], t = cur[m.to]; if (!f || !t) return; const i = f.stops.findIndex(s => s.gid === m.gid); if (i < 0) return; const [s] = f.stops.splice(i, 1); t.stops = ins(c, pl, t.r, t.stops, s); aff.add(m.from); aff.add(m.to); });
    const edits = {}; aff.forEach(id => { const x = cur[id]; if (x) edits[id] = { stops: x.stops.length ? best(c, pl, x.r, x.stops).stops : [], vias: {} }; });
    const np = Object.assign({}, pl, { id: pl.id + '~' + k, edits: Object.assign(JSON.parse(JSON.stringify(pl.edits || {})), edits), removed: (pl.removed || []).slice() });
    const v = { edits, np, aff }; memo[p.id] = { k, v }; return v;
  }

  // ---------- intents: Route Plans ----------
  function findRoute(R, t) { const m = t.match(/\br\s*-?\s*0*(\d{1,3})\b/i); if (!m) return null; return R.routes.find(r => +String(r.id).replace(/\D/g, '') === +m[1]) || { missing: 'R' + m[1] }; }
  function explain(c, pl, r, tgt) {
    const am = pl.session === 'AM', n = r.stops.length, legs = [];
    if (am) r.stops.forEach((s, k) => legs.push({ a: s.stopId + s.sfx + ' ' + s.name.split(/ [–-] /)[0], b: k < n - 1 ? r.stops[k + 1].stopId + r.stops[k + 1].sfx : 'school', s: (k < n - 1 ? r.stops[k + 1].t : r.end) - s.t - (s.dwell || 0) }));
    else r.stops.forEach((s, k) => legs.push({ a: k ? r.stops[k - 1].stopId + r.stops[k - 1].sfx : 'School', b: s.stopId + s.sfx + ' ' + s.name.split(/ [–-] /)[0], s: s.t - (k ? r.stops[k - 1].t + (r.stops[k - 1].dwell || 0) : r.start) }));
    const top = legs.filter(l => l.s >= 240).sort((x, y) => y.s - x.s).slice(0, 3), dw = r.stops.reduce((a, s) => a + (s.dwell || 0), 0), areas = [...new Set(r.stops.map(s => areaOf(s.stopId)))];
    const L = [{ t: `${r.id} takes ${M(r.span)} min for ${plural(r.load, 'rider')} at ${plural(n, 'stop')}. Target Journey is ${tgt} min.` }];
    if (top.length) { L.push({ t: 'Slowest legs (road time):', w: 700 }); top.forEach(l => L.push({ bullet: true, t: `${l.a} to ${l.b}: ${(l.s / 60).toFixed(1)} min` })); }
    if (r.backM > 300) L.push({ t: `It doubles back about ${(r.backM / 1000).toFixed(1)} km${areas.length > 2 ? ` across ${areas.join(', ')}` : ''}.` });
    else if (areas.length > 2) L.push({ t: `It covers ${areas.join(', ')}.` });
    L.push({ t: `Stopping and boarding add ${M(dw)} min. Driving is ${M(r.span - dw)} min.` });
    return L;
  }
  function planIntent(c, cx, text) {
    const pl = c.curPlan(), t = text.toLowerCase();
    if (!pl || !pl.result || !pl.result.routes) return say(c, cx, ['Open a route plan first, then ask me about it.']);
    if (!mx(c)) { if (c.mxFailK) return say(c, cx, ["Road times from OSRM couldn't be loaded, so I can't time any change. I won't use straight-line estimates."], { chips: ['Retry road times'] }); c.ensureRoadTimes(); const n = (planIntent.w = (planIntent.w || 0) + 1); set(c, { busyTxt: 'Waiting for OSRM road times' }); if (n > 45) { planIntent.w = 0; return say(c, cx, ['Road times from OSRM are taking too long. Try again shortly.']); } return setTimeout(() => planIntent(c, cx, text), 1000); }
    planIntent.w = 0;
    const R = c.res(pl), P = pl.result.params || {}, tg0 = P.targetCap || 60, tm = t.match(/(\d{2,3})\s*(min|m\b)/), tgt = tm ? +tm[1] : tg0;
    const rr = findRoute(R, t); if (rr && rr.missing) return say(c, cx, [`There is no ${rr.missing} in ${pl.name}.`]);
    const slow = R.routes.slice().sort((a, b) => b.span - a.span)[0], lk = new Set(pl.locked || []);
    if (/retry/.test(t)) { c.mxFailK = null; c.ensureRoadTimes(); return say(c, cx, ['Loading road times again.']); }
    if (/why|slow|long/.test(t)) { const r = rr || slow; return say(c, cx, explain(c, pl, r, tg0), { chips: M(r.span) > tgt ? [`Cut ${r.id} under ${tgt} min`] : [] }); }
    if (/cut|under|shorten|faster|reduce|quicker/.test(t)) {
      const r = rr || slow;
      if (lk.has(r.id)) return say(c, cx, [`${r.id} is locked, so I left it alone. Unlock it first.`]);
      if (M(r.span) <= tgt) return say(c, cx, [`${r.id} is already ${M(r.span)} min, within ${tgt} min.`]);
      const res = shorten(c, pl, r.id, tgt);
      if (!res.moves.length && !res.reordered) return say(c, cx, [`No change brings ${r.id} under ${tgt} min without pushing another route over ${tgt} min or over its seats.`]);
      const p = { id: 'ai' + Date.now(), cx, kind: 'shorten', planId: pl.id, rid: r.id, target: tgt, moves: res.moves, reorder: [r.id], status: 'pending' };
      const nr = c.res(build(c, pl, p).np).routes.find(x => x.id === r.id); p.title = `Cut ${r.id} to ${M(nr.span)} min`;
      addProp(c, p); fit(c, p);
      return say(c, cx, [M(nr.span) <= tgt ? `Here's a way to get ${r.id} to ${M(nr.span)} min. It's on the map as a preview.` : `The best I found gets ${r.id} to ${M(nr.span)} min, still over ${tgt}. It's on the map as a preview.`], { pid: p.id });
    }
    if (/save a bus|fewer bus|less bus|merge|drop a bus|one less/.test(t)) {
      const lim = tm ? tgt : (P.hardCap || tgt), b = merge(c, pl, lim);
      if (!b) return say(c, cx, [`No saving found. Every pair of routes that fits on one bus comes out over ${lim} min${tm ? '' : ' (Max Journey)'}.`], { chips: ['What needs attention?'] });
      const p = { id: 'ai' + Date.now(), cx, kind: 'merge', planId: pl.id, target: lim, title: `Merge ${b.a.id} into ${b.b.id}`, moves: b.a.stops.map(s => ({ gid: s.gid, label: s.stopId + (s.sfx || ''), name: s.name, n: s.riders.length, from: b.a.id, to: b.b.id, on: true })), reorder: [], status: 'pending' };
      addProp(c, p); fit(c, p);
      return say(c, cx, [`${b.a.id} carries ${plural(b.a.load, 'rider')}. They fit on ${b.b.id}, which goes to ${M(b.span)} min.`], { pid: p.id });
    }
    if (/attention|problem|issue|highlight|check|wrong/.test(t)) {
      const FLAG = ['Over max journey', 'Over soft cap', 'Loop-back', 'Not inside-out', 'Underfilled'];
      const bad = R.routes.map(r => ({ r, f: (r.badges || []).filter(b => FLAG.includes(b)) })).filter(x => x.f.length).sort((a, b) => b.r.span - a.r.span);
      const L = bad.length ? [{ t: `${plural(bad.length, 'route')} to look at:`, w: 700 }].concat(bad.slice(0, 8).map(x => ({ bullet: true, t: `${x.r.id}: ${x.f.join(', ')}. ${M(x.r.span)} min, ${x.r.load}/${x.r.studentSeats} seats`, go: () => c.engSet({ selRoute: x.r.id }), goLabel: 'Show' }))) : [{ t: 'No route is over target, looping back or underfilled.' }];
      const un = R.unassigned || [], nu = un.reduce((a, u) => a + u.n, 0);
      if (nu) { const by = {}; un.forEach(u => { by[u.reason] = (by[u.reason] || 0) + u.n; }); L.push({ t: `${plural(nu, 'rider')} not on a route:`, w: 700 }); Object.keys(by).forEach(k => L.push({ bullet: true, t: `${(c.REASONS && c.REASONS[k]) || k}: ${by[k]}` })); }
      return say(c, cx, L, { chips: bad.length ? [`Why is ${bad[0].r.id} ${M(bad[0].r.span)} min?`] : [] });
    }
    if (/over|which|list/.test(t)) {
      const over = R.routes.filter(r => M(r.span) > tgt).sort((a, b) => b.span - a.span);
      return say(c, cx, over.length ? [`${plural(over.length, 'route')} over ${tgt} min:`].concat(over.map(r => ({ bullet: true, t: `${r.id}: ${M(r.span)} min, ${r.load}/${r.studentSeats} seats`, go: () => c.engSet({ selRoute: r.id }), goLabel: 'Show' }))) : [`No routes over ${tgt} min.`], { chips: over.length ? [`Cut ${over[0].id} under ${tgt} min`] : [] });
    }
    if (/how many|riders|buses|average|avg|total|summary/.test(t)) {
      const sm = R.summary, nu = (R.unassigned || []).reduce((a, u) => a + u.n, 0);
      return say(c, cx, [`${pl.name}: ${plural(sm.routes, 'bus')}, ${sm.assigned} riders on routes${nu ? `, ${nu} not on a route` : ''}.`, `Average journey ${Math.round(sm.avgJourney)} min, longest ${Math.round(sm.maxJourney)} min. Average fill ${Math.round(sm.avgFill * 100)}%.`]);
    }
    say(c, cx, ['I can help with things like:', { bullet: true, t: `Why is ${slow.id} ${M(slow.span)} min?` }, { bullet: true, t: `Cut ${slow.id} under ${tg0} min` }, { bullet: true, t: 'Can we save a bus?' }, { bullet: true, t: 'What needs attention?' }]);
  }

  // ---------- intents: Stop Library ----------
  function cov(c) {
    const k = [c.state.stops, c.state.links];
    if (c._aiCov && c._aiCov.k[0] === k[0] && c._aiCov.k[1] === k[1]) return c._aiCov.v;
    const linked = c.state.stops.filter(s => s.linked), none = [], far = [], walk = [];
    c.D.riders.forEach(r => {
      const hs = linked.filter(st => c.linkedTo(st, r)); if (!hs.length) return none.push(r);
      let d = Infinity, at = null; hs.forEach(st => st.points.filter(p => !(st.off || []).includes(p.pid)).forEach(p => { const x = hv([r.lat, r.lng], [p.lat, p.lng]); if (x < d) { d = x; at = st; } }));
      if (at) { walk.push({ r, d, st: at }); if (d > 400) far.push({ r, d, st: at }); }
    });
    const v = { none, far: far.sort((a, b) => b.d - a.d), walk: walk.sort((a, b) => b.d - a.d) }; c._aiCov = { k, v }; return v;
  }
  const zoneOf = (c, r) => { const z = c.subzoneAt && c.subzoneAt(r.lat, r.lng); return z ? z.name : 'Unknown area'; };
  async function snap(ll) {
    try { const res = await fetch(`${OSRM()}/nearest/v1/driving/${ll[1]},${ll[0]}?number=1`); if (res.ok) { const j = await res.json(); const w = j.code === 'Ok' && j.waypoints && j.waypoints[0]; if (w) return { ll: [+w.location[1].toFixed(6), +w.location[0].toFixed(6)], road: w.name || '' }; } } catch (e) {}
    return null;
  }
  async function suggestStop(c, cx, text) {
    const C = cov(c), w250 = C.walk.filter(x => x.d > 250), pc = (String(text || '').match(/\b\d{6}\b/) || [])[0];
    let pool, why;
    if (pc) { pool = c.D.riders.filter(r => r.postal === pc); why = `postal code ${pc}`; if (!pool.length) return say(c, cx, [`No rider for this school lives at ${pc}.`]); }
    else { pool = C.none.length ? C.none : C.far.length ? C.far.map(x => x.r) : w250.map(x => x.r); why = C.none.length ? 'no stop' : C.far.length ? 'more than 400 m to walk' : 'a 250 to 400 m walk to their stop'; }
    const ex = C.walk[0] && C.walk[0].r.postal;
    if (!pool.length) return say(c, cx, ['Every rider has a stop within 250 m. No new stop needed.'], ex ? { chips: [`Suggest a stop near ${ex}`] } : {});
    let bestG = null; pool.forEach(r => { const g = pool.filter(x => hv([r.lat, r.lng], [x.lat, x.lng]) < 350); if (!bestG || g.length > bestG.length) bestG = g; });
    if (!pc && !C.none.length && bestG.length < 2) return say(c, cx, [`Every rider is within 400 m of a stop, and no two riders with a longer walk live close together. No new stop is needed.`, 'You can still ask for a stop near a postal code.'], ex ? { chips: [`Suggest a stop near ${ex}`] } : {});
    const ctr = [bestG.reduce((a, r) => a + r.lat, 0) / bestG.length, bestG.reduce((a, r) => a + r.lng, 0) / bestG.length];
    const sn = await snap(ctr); if (!sn) return say(c, cx, ["Couldn't reach OSRM to place the stop on a road. Try again."], { chips: ['Suggest a new stop'] });
    const zone = zoneOf(c, bestG[0]), p = { id: 'ai' + Date.now(), cx, kind: 'stop', status: 'pending', ll: sn.ll, road: sn.road, zone, riders: bestG.map(r => r.rid), why: pc ? `their home at ${why}` : why, title: sn.road ? `New stop on ${sn.road}` : `New stop in ${zone}` };
    if (c.map) c.map.setView(sn.ll, 17, { animate: false }); addProp(c, p);
    say(c, cx, [pc ? `${plural(bestG.length, 'rider')} live at ${pc} in ${zone}. Here's a spot on a public road next to them.` : `${plural(bestG.length, 'rider')} in ${zone} ${bestG.length === 1 ? 'has' : 'have'} ${why}. Here's a spot on a public road that covers them.`], { pid: p.id });
  }
  function libIntent(c, cx, text) {
    const t = text.toLowerCase(), C = cov(c);
    if (/suggest|new stop|create|add a stop|place a stop/.test(t)) return suggestStop(c, cx, text);
    if (/no stop|without a stop|uncovered|not covered/.test(t)) {
      if (!C.none.length) return say(c, cx, ['Every rider is covered by at least one stop.']);
      const by = {}; C.none.forEach(r => { const z = zoneOf(c, r); by[z] = (by[z] || 0) + 1; });
      return say(c, cx, [`${plural(C.none.length, 'rider')} have no stop:`].concat(Object.keys(by).sort((a, b) => by[b] - by[a]).map(z => ({ bullet: true, t: `${z}: ${by[z]}` }))), { chips: ['Suggest a new stop'] });
    }
    if (/far|400|walk|distance/.test(t)) {
      if (!C.far.length) return say(c, cx, ['No rider is more than 400 m from their nearest stop point.']);
      return say(c, cx, [`${plural(C.far.length, 'rider')} are more than 400 m from their nearest stop point (straight line):`].concat(C.far.slice(0, 8).map(x => ({ bullet: true, t: `${x.r.name}, ${x.r.postal}: ${Math.round(x.d)} m to ${x.st.id}`, go: () => c.select(x.st.uid), goLabel: 'Open' })), C.far.length > 8 ? [{ t: `and ${C.far.length - 8} more.` }] : []), { chips: ['Suggest a new stop'] });
    }
    if (/attention|missing|bus size|no point|gaps|problem|issue/.test(t)) {
      const g = c.state.stops.filter(s => s.linked).map(s => ({ s, w: c.coverage(s).warnings })).filter(x => x.w.length);
      if (!g.length) return say(c, cx, ['No school stop is missing a point or bus size.']);
      return say(c, cx, [`${plural(g.length, 'stop')} need attention:`].concat(g.slice(0, 10).map(x => ({ bullet: true, t: `${x.s.id} ${x.s.name}: ${x.w.map(w => typeof w === 'string' ? w : (w.text || w.msg || w.label || '')).filter(Boolean).join(', ') || 'check points'}`, go: () => c.select(x.s.uid), goLabel: 'Open' }))));
    }
    if (/unused|no riders|empty/.test(t)) {
      const u = c.state.stops.filter(s => !c.ridersOf(s).length);
      return say(c, cx, [`${plural(u.length, 'stop')} in the library have no riders for this school.`].concat(u.slice(0, 8).map(s => ({ bullet: true, t: `${s.id} ${s.name}`, go: () => c.select(s.uid), goLabel: 'Open' }))));
    }
    if (/how many|count|total|summary/.test(t)) {
      const L = c.state.stops.length, n = c.state.stops.filter(s => s.linked).length;
      return say(c, cx, [`${plural(L, 'stop')} in the library, ${n} used by this school.`, `${c.D.riders.length} riders: ${C.none.length} with no stop, ${C.far.length} more than 400 m away.`]);
    }
    say(c, cx, ['I can help with things like:', { bullet: true, t: 'Which riders have no stop?' }, { bullet: true, t: 'Suggest a new stop' }, { bullet: true, t: 'Riders more than 400 m from their stop' }, { bullet: true, t: 'Stops that need attention' }]);
  }

  // ---------- actions ----------
  function ask(c, text) {
    const q = (text || '').trim(), a = S(c), cx = ctx(c); if (!q || a.busy) return;
    const heavy = /cut|under|shorten|faster|reduce|save|merge|bus|suggest|new stop|create/.test(q.toLowerCase());
    set(c, x => ({ draft: '', busy: true, busyTxt: heavy ? (cx === 'plans' ? 'Timing options with the routing engine' : 'Finding a spot on a road') : 'Reading the data', threads: Object.assign({}, x.threads, { [cx]: x.threads[cx].concat([{ role: 'user', text: q }]) }) }));
    setTimeout(() => { try { cx === 'plans' ? planIntent(c, cx, q) : libIntent(c, cx, q); } catch (e) { console.error(e); say(c, cx, ['Something went wrong working that out. Nothing was changed.']); } }, 60);
  }
  function fit(c, p) {
    const pl = c.curPlan(); if (!c.map || !pl) return; const b = build(c, pl, p), pts = [];
    c.res(b.np).routes.concat(c.res(pl).routes).filter(r => b.aff.has(r.id)).forEach(r => r.stops.forEach(s => pts.push(s.ll)));
    if (pts.length) c.map.fitBounds(pts, { padding: [80, 80] });
  }
  function apply(c, id) {
    const p = S(c).props[id]; if (!p) return;
    if (p.kind === 'stop') {
      const riders = p.riders.map(r => c.riderById ? c.riderById(r) : null).filter(Boolean), postals = [...new Set(riders.map(r => r.postal).filter(Boolean))];
      const draft = { uid: 'n' + Date.now(), id: null, name: p.road || '', points: [{ pid: 'p' + Date.now(), sfx: 'A', name: '', lat: p.ll[0], lng: p.ll[1], usage: 'both', sizes: ['S', 'M', 'L'], primary: true, streetView: '' }], postalCodes: postals, areas: [], idHistory: [], retired: [], off: [], linked: true, bySchool: {} };
      c.leaveTool && c.leaveTool('add a stop');
      c.setState(Object.assign({ view: 'edit', isNew: true, draft, catchTab: 'postal', mode: null, hoverUid: null }, c.resetEdit()));
      setP(c, id, { status: 'applied', note: `Opened in Add Stop with ${plural(postals.length, 'postal code')}. Check and save it there.` });
      return;
    }
    const pl = c.engState().plans.find(x => x.id === p.planId); if (!pl) return;
    const E = build(c, pl, p).edits;
    c.editPlan(np => { Object.keys(E).forEach(k => { np.edits[k] = JSON.parse(JSON.stringify(E[k])); }); }, `Convoy AI: ${p.title}`);
    setP(c, id, { status: 'applied', undoAt: (c.state.undo || []).length + 1 });
  }

  // ---------- map overlay (preview) ----------
  function previewPlan(c, pl) {
    if (!S(c).open) return null; const p = live(c, 'plans'); if (!p || p.planId !== pl.id || !mx(c)) return null;
    const b = build(c, pl, p); return { np: b.np, aff: b.aff, p };
  }
  function draw(c) {
    if (!c.map || !window.L) return; const L = window.L, p = S(c).open && ctx(c) === 'library' ? live(c, 'library') : null;
    const sig = p ? p.id + p.status + p.ll.join(',') : '';
    if (sig === c._aiSig) return; c._aiSig = sig;
    if (c._aiG) c._aiG.remove(); c._aiG = null; if (!p) return;
    const g = c._aiG = L.layerGroup().addTo(c.map);
    setTimeout(() => { if (c._aiG !== g) return; try { drawStop(c, L, g, p); } catch (e) { console.error('ConvoyAI draw', e && e.message); } }, 80);
  }
  function drawStop(c, L, g, p) {
    p.riders.forEach(rid => { const r = c.riderById(rid); if (!r) return; L.marker([r.lat, r.lng], { zIndexOffset: 2900, icon: L.divIcon({ className: '', iconSize: [12, 12], iconAnchor: [6, 6], html: '<div style="width:12px;height:12px;border-radius:50%;background:#008C95;border:2px solid #fff;box-sizing:border-box;box-shadow:0 1px 3px rgba(22,22,22,.35)"></div>' }) }).bindTooltip(`<b>${r.name}</b><br>${r.postal} | ${Math.round(hv([r.lat, r.lng], p.ll))} m to the new stop`).addTo(g); });
    const ed = p.status === 'editing';
    const m = L.marker(p.ll, { draggable: ed, zIndexOffset: 3000, icon: L.divIcon({ className: '', iconSize: [34, 34], iconAnchor: [17, 17], html: `<div style="width:34px;height:34px;border-radius:50%;background:#fff;border:3px dashed #004F59;box-sizing:border-box;display:flex;align-items:center;justify-content:center;box-shadow:0 2px 8px rgba(22,22,22,.3);cursor:${ed ? 'grab' : 'default'}"><span style="font-family:'Material Symbols Rounded';font-size:18px;color:#004F59;font-variation-settings:'FILL' 1">add_location_alt</span></div>` }) }).addTo(g);
    m.bindTooltip(ed ? 'Drag to move. It snaps to the nearest road' : `Proposed stop | ${p.road || 'road'}`, { direction: 'top', offset: [0, -18] });
    if (ed) m.on('dragend', async () => { const q = m.getLatLng(), sn = await snap([q.lat, q.lng]); setP(c, p.id, sn ? { ll: sn.ll, road: sn.road, title: sn.road ? `New stop on ${sn.road}` : `New stop in ${p.zone}`, moved: true } : { ll: [q.lat, q.lng], moved: true }); });
  }

  // ---------- view values ----------
  function card(c, p) {
    const ST = { pending: ['Preview', 'info'], editing: ['Editing', 'info'], applied: ['Applied', 'success'], discarded: ['Discarded', 'neutral'], replaced: ['Replaced', 'neutral'], undone: ['Undone', 'neutral'] }[p.status] || ['', 'neutral'];
    const act = p.status === 'pending' || p.status === 'editing', G = 'var(--green-700, #00873A)', O = 'var(--orange-600, #C76800)', INK = 'var(--ink-800)';
    const base = { title: p.title, status: ST[0], tone: ST[1], headBg: act ? 'var(--teal-050, #E5F3F4)' : 'var(--white)', actionable: act, isEditing: p.status === 'editing', note: p.note || '', hasNote: !!p.note,
      apply: () => apply(c, p.id), edit: () => setP(c, p.id, { status: 'editing' }), discard: () => { setP(c, p.id, { status: 'discarded' }); }, moveRows: [], hasMoveRows: false };
    if (p.kind === 'stop') {
      const rs = p.riders.map(r => c.riderById(r)).filter(Boolean), ds = rs.map(r => hv([r.lat, r.lng], p.ll)), mxD = ds.length ? Math.round(Math.max(...ds)) : 0;
      return Object.assign(base, { icon: 'add_location_alt', applyLabel: 'Open in Add Stop', editLabel: 'Move Pin',
        metrics: [{ l: 'Riders Covered', v: `${rs.length}`, fg: INK, bl: 'none' }, { l: 'Farthest Walk', v: `${mxD} m`, fg: mxD > 400 ? O : G, bl: '1px solid var(--ink-100)' }, { l: 'Postal Codes', v: `${new Set(rs.map(r => r.postal)).size}`, fg: INK, bl: '1px solid var(--ink-100)' }],
        hasRows: false, rows: [],
        why: [`These riders have ${p.why}. The point sits at their centre, snapped to ${p.road || 'the nearest drivable road'}.`].concat(p.moved ? ['Moved by you.'] : []).concat(p.status === 'editing' ? ['Drag the pin on the map, then open it in Add Stop.'] : []),
        checks: [{ icon: 'verified', color: 'var(--green-600, #00A844)', t: 'Point placed on a road by OSRM. Walk distances are straight line.' }, { icon: 'shield_person', color: 'var(--ink-500)', t: 'Saved through Add Stop, so your Stop Library permissions and approvals apply.' }] });
    }
    const pl = c.engState().plans.find(x => x.id === p.planId); if (!pl || !mx(c)) return Object.assign(base, { icon: 'timer', applyLabel: 'Apply', editLabel: 'Edit', metrics: [], hasRows: false, rows: [], why: ['Plan not available.'], checks: [], actionable: false });
    const b = build(c, pl, p), R0 = c.res(pl), R1 = c.res(b.np), tg = p.target, ord = [...b.aff].sort();
    const mx0 = Math.max(...R0.routes.map(r => M(r.span))), mx1 = Math.max(...R1.routes.map(r => M(r.span)));
    const onM = p.moves.filter(m => m.on), nMv = onM.reduce((a, m) => a + m.n, 0), nAff = R1.routes.filter(r => b.aff.has(r.id)).reduce((a, r) => a + r.load, 0);
    const rows = ord.map(id => { const x = R0.routes.find(r => r.id === id), y = R1.routes.find(r => r.id === id); return { id, color: c.colOf(pl, id), nB: `${x.load}/${x.studentSeats}`, nA: y ? `${y.load}/${y.studentSeats}` : 'Removed', jB: `${M(x.span)} min`, jA: y ? `${M(y.span)} min` : 'N/A', jFg: y && M(y.span) > tg ? O : y ? G : INK }; });
    const why = [], grp = {};
    if (p.reorder && p.reorder.length) { const rk = p.id + '|' + (pl.at || '') + JSON.stringify(pl.edits || {}).length; if (!memo['w' + p.id] || memo['w' + p.id].k !== rk) { const w = []; p.reorder.forEach(id => { const x = R0.routes.find(r => r.id === id); if (!x) return; const o = best(c, pl, x, x.stops.map(toEd)); if (o.span < x.span - 30) w.push(`Re-ordered ${id} to stop doubling back: ${M(x.span)} to ${M(o.span)} min on its own.`); }); memo['w' + p.id] = { k: rk, v: w }; } why.push(...memo['w' + p.id].v); }
    onM.forEach(m => { const k = m.from + '>' + m.to; (grp[k] = grp[k] || []).push(m); });
    Object.keys(grp).forEach(k => { const ms = grp[k], [f, to] = k.split('>'), fa = R1.routes.find(r => r.id === f), fb = R0.routes.find(r => r.id === f), ta = R1.routes.find(r => r.id === to), tb = R0.routes.find(r => r.id === to), n = ms.reduce((a, m) => a + m.n, 0);
      const what = ms.length === 1 ? ms[0].label : `${ms.length} ${[...new Set(ms.map(m => areaOf(m.label)))].join(' and ')} stops`;
      why.push(fa ? `Moved ${what} (${plural(n, 'rider')}) from ${f} to ${to}. ${f} ${M(fb.span)} to ${M(fa.span)} min. ${to} ${M(tb.span)} to ${M(ta.span)} min, ${ta.load}/${ta.studentSeats} seats.` : `Moved all of ${f} (${plural(n, 'rider')}) to ${to}: one bus fewer. ${to} ${M(tb.span)} to ${M(ta.span)} min, ${ta.load}/${ta.studentSeats} seats.`); });
    if (!why.length) why.push('No changes left. Turn a move back on or discard.');
    const checks = [{ icon: 'verified', color: 'var(--green-600, #00A844)', t: `Timed by the routing engine on OSRM road times. Seats and Max Journey ${pl.result.params.hardCap || ''} min checked.` }];
    R1.routes.filter(r => b.aff.has(r.id) && M(r.span) > tg).forEach(r => checks.push({ icon: 'warning', color: 'var(--orange-500)', t: `${r.id} is ${M(r.span)} min, over ${tg} min.` }));
    const lk = pl.locked || []; if (lk.length) checks.push({ icon: 'lock', color: 'var(--ink-500)', t: `${lk.join(', ')} locked, left as is.` });
    if (Object.keys(b.edits).some(k => (pl.edits && pl.edits[k] && Object.keys(pl.edits[k].vias || {}).length))) checks.push({ icon: 'info', color: 'var(--teal-600)', t: 'Via points on changed routes are cleared.' });
    const lastUndo = p.status === 'applied' && p.undoAt && (c.state.undo || []).length === p.undoAt;
    return Object.assign(base, { icon: p.kind === 'merge' ? 'call_merge' : 'timer', applyLabel: 'Apply', editLabel: 'Edit',
      metrics: [{ l: 'Buses', v: R0.routes.length === R1.routes.length ? `${R1.routes.length}` : `${R0.routes.length} to ${R1.routes.length}`, fg: R1.routes.length < R0.routes.length ? G : INK, bl: 'none' },
        { l: 'Longest Journey', v: `${mx0} to ${mx1} min`, fg: mx1 < mx0 ? G : mx1 > mx0 ? O : INK, bl: '1px solid var(--ink-100)' },
        { l: `Riders Affected, ${nMv} change bus`, v: `${nAff}`, fg: INK, bl: '1px solid var(--ink-100)' }],
      hasRows: true, rows, why, checks, canUndo: !!lastUndo, undo: () => { c.undo(); setP(c, p.id, { status: 'undone' }); },
      moveRows: p.status === 'editing' ? p.moves.map((m, i) => ({ t: `${m.label} ${m.name.split(/ [–-] /)[0]}: ${m.from} to ${m.to}, ${plural(m.n, 'rider')}`, icon: m.on ? 'check_box' : 'check_box_outline_blank', color: m.on ? 'var(--teal-800)' : 'var(--ink-400)', toggle: () => setP(c, p.id, { moves: p.moves.map((x, j) => j === i ? Object.assign({}, x, { on: !x.on }) : x) }) })) : [],
      hasMoveRows: p.status === 'editing' && p.moves.length > 0 });
  }
  function vals(c, v) {
    const a = S(c), cx = ctx(c), pl = c.curPlan && c.curPlan(), plans = cx === 'plans';
    let chips = [];
    if (plans && pl && pl.result && pl.result.routes && mx(c)) { const R = c.res(pl), sl = R.routes.slice().sort((x, y) => y.span - x.span)[0], tg = (pl.result.params || {}).targetCap || 60; if (sl) chips = [`Why is ${sl.id} ${M(sl.span)} min?`, `Cut ${sl.id} under ${tg} min`]; chips = chips.concat(['Can we save a bus?', 'What needs attention?']); }
    else if (plans) chips = ['What needs attention?'];
    else chips = ['Which riders have no stop?', 'Suggest a new stop', 'Riders more than 400 m from their stop', 'Stops that need attention'];
    const welcome = { role: 'ai', lines: plans ? [{ t: `Ask about ${pl ? pl.name : 'a route plan'} or ask for a change.` }, { t: 'Changes show on the map as a preview first. Nothing changes until you press Apply, and Apply goes into undo history.' }] : [{ t: 'Ask about stops and riders for this school, or ask me to suggest a new stop.' }, { t: 'New stops open in Add Stop for you to check and save.' }] };
    const msgs = [welcome].concat(a.threads[cx] || []).map(m => ({ isUser: m.role === 'user', isAi: m.role === 'ai', text: m.text || '',
      lines: (m.lines || []).map(l => ({ t: l.t, bullet: !!l.bullet, w: l.w || 400, hasGo: !!l.go, go: l.go || null, goLabel: l.goLabel || '' })),
      hasP: !!(m.pid && a.props[m.pid]), p: m.pid && a.props[m.pid] ? card(c, a.props[m.pid]) : {},
      hasChips: !!(m.chips && m.chips.length), chips: (m.chips || []).map(label => ({ label, on: () => ask(c, label) })) }));
    const lp = live(c, cx);
    return { open: a.open, toggle: () => set(c, { open: !a.open }, () => setTimeout(() => c.map && c.map.invalidateSize(), 60)), close: () => set(c, { open: false }, () => setTimeout(() => c.map && c.map.invalidateSize(), 60)),
      sub: plans ? `Working on ${pl ? pl.name : 'Route Plans'}. Nothing changes until you apply.` : 'Working on the Stop Library. Nothing changes until you apply.',
      msgs, busy: a.busy, busyTxt: a.busyTxt, chips: chips.map(label => ({ label, on: () => ask(c, label) })),
      draft: a.draft, onDraft: e => set(c, { draft: e.target.value }), onKey: e => { if (e.key === 'Enter' && !e.shiftKey) { e.preventDefault(); ask(c, a.draft); } }, send: () => ask(c, a.draft), cannotSend: !a.draft.trim() || a.busy,
      foot: plans ? 'Uses only existing actions: move stop, reorder, merge. Locked routes are left alone.' : 'Uses only existing actions: add stop. Approvals still apply.',
      prevOn: !!(a.open && lp && (plans ? (pl && lp.planId === pl.id) : true)), prevTitle: lp ? (lp.status === 'editing' ? 'Editing: ' : 'Preview: ') + lp.title : '', prevBefore: plans };
  }
  function scrollRef(c) { return c._aiScrollRef || (c._aiScrollRef = el => { c._aiScrollEl = el; }); }
  function tick(c) {
    draw(c); const el = c._aiScrollEl, a = S(c), n = (a.threads[ctx(c)] || []).length + (a.busy ? 1 : 0);
    if (el && n !== c._aiN) { c._aiN = n; setTimeout(() => { el.scrollTop = el.scrollHeight; }, 30); }
  }
  window.ConvoyAI = { vals, previewPlan, tick, scrollRef, ask };
})();
