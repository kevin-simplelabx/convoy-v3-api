// Convoy Pathfinder client helpers (browser only).
// The route search runs on the server only (POST /api/solve, engine in node-app/engine/convoy-pathfinder.js).
// This file holds settings, presets, bus types, re-timing for manual edits and the road matrix fetch.
// Built from convoy-pathfinder.js: if you change shared helpers there, copy them here too.
(function () {
  const TYPES = [
    { type: 'LARGE_45', label: '45-seater', cls: 'L', seats: 45, law: true, floorPct: 0.6, headroom: 0.10, fixed: 110, rpm: 1, max: null, on: true },
    { type: 'LARGE_40', label: '40-seater', cls: 'L', seats: 40, law: true, floorPct: 0.6, headroom: 0.10, fixed: 100, rpm: 1, max: null, on: true },
    { type: 'MEDIUM_23', label: '23-seater', cls: 'M', seats: 23, law: false, floorPct: 0.55, headroom: 0.10, fixed: 85, rpm: 1, max: null, on: true },
    { type: 'SMALL_13', label: '13-seater', cls: 'S', seats: 13, law: false, floorPct: 0.5, headroom: 0.05, fixed: 65, rpm: 1, max: null, on: true }
  ];
  // Search effort levels. Which levels a tenant may use is set by its Convoy plan (CONVOY_CONFIG.maxEffort / server MAX_EFFORT)
  const EFFORT = { low: { label: 'Low', runs: 1, sec: 15, use: 'Quick what-if checks' }, medium: { label: 'Med', runs: 2, sec: 30, use: 'Fast drafts' }, high: { label: 'High', runs: 3, sec: 60, use: 'Day-to-day planning' }, extra: { label: 'Extra', runs: 5, sec: 90, use: 'Final plans for large schools' }, max: { label: 'Max', runs: 8, sec: 120, use: 'The final plan of the term' } };
  const EFFORT_KEYS = Object.keys(EFFORT);
  const DEFAULTS = {
    session: 'AM', headroom: 0.10, hardCapacity: true, attendant: 'STATUTORY',
    targetCap: 50, hardCap: 75, overtime: 15, earliest: '05:35',
    amWin: ['06:45', '07:00'], amTarget: '06:50', pmWin: ['13:30', '13:45'], pmTarget: '13:45', asaWin: ['16:15', '16:30'], asaTarget: '16:30',
    baseDwell: 30, perStudent: 5, schoolDwell: 120, floorPenalty: 10, unassignedPenalty: 50000,
    stability: 'KEEP_CURRENT', pointPen: 3, tol: 5, timePen: 0.25, effort: 'high', timeLimit: 60, runs: 3, rrPerStop: 30, rrMaxIt: 6000, rrStall: 0,
    algorithm: 'SWEEP_ACO', ants: 14, acoIters: 100, sweepStarts: 8, rrMax: 12, maxSectorDeg: 40, sectorFromKm: 2, maxDetour: 2.5, detourGrace: 10, rideCost: 0.05, loopbackM: 500, gapPen: 12, gapMin: 4, gapMax: 12, denseRiders: 30,
    amTraffic: 1.4, pmTraffic: 1.2, asaTraffic: 1.25,
    types: TYPES
  };
  const SPEED = { S: [24, 50], M: [21, 45], L: [19, 42] }; // km/h door-to-door: short legs, long legs
  const DETOUR = 1.3;
  const toS = t => { const [h, m] = t.split(':').map(Number); return h * 3600 + m * 60; };
  const fmt = s => { s = Math.round(s / 60) * 60; return String(Math.floor(s / 3600)).padStart(2, '0') + ':' + String(Math.floor(s % 3600 / 60)).padStart(2, '0'); };
  function hav(a, b) {
    const R = 6371000, t = Math.PI / 180, dLat = (b[0] - a[0]) * t, dLng = (b[1] - a[1]) * t;
    const h = Math.sin(dLat / 2) ** 2 + Math.cos(a[0] * t) * Math.cos(b[0] * t) * Math.sin(dLng / 2) ** 2;
    return 2 * R * Math.asin(Math.sqrt(h));
  }
  function travel(cls, a, b) {
    const d = hav(a, b) * DETOUR; if (d < 1) return 0;
    const [v0, v1] = SPEED[cls], v = v0 + (v1 - v0) * Math.min(1, d / 8000);
    return d / (v / 3.6);
  }

  function prepTypes(P) {
    return P.types.filter(t => t.on).map(t => {
      const att = P.attendant === 'ALL_BUSES' || t.law ? 1 : 0, ss = t.seats - att;
      return Object.assign({}, t, { attendant: !!att, studentSeats: ss, cap: Math.floor((1 - (t.headroom != null ? t.headroom : (P.headroom || 0))) * ss), floor: Math.ceil(t.floorPct * ss) });
    });
  }

  const CLS_FACTOR = { S: 1.05, M: 1.15, L: 1.3 }; // bus vs car on the same road
  const key = ll => ll[0].toFixed(5) + ',' + ll[1].toFixed(5);
  const trafficOf = P => +(P.session === 'AM' ? P.amTraffic : P.session === 'PM' ? P.pmTraffic : P.asaTraffic) || 1; // peak-hour slowdown vs free-flow road times
  function diff(a, b) { // a = candidate, b = current
    const types = [...new Set(Object.keys(a.summary.byType).concat(Object.keys(b.summary.byType)))];
    const byType = types.map(t => ({ type: t, a: a.summary.byType[t] || 0, b: b.summary.byType[t] || 0 }));
    let moved = 0, shifted = 0; const movedList = [];
    Object.keys(a.assign).forEach(rid => { const x = a.assign[rid], y = b.assign[rid]; if (!y) return; if (x.pid !== y.pid) { moved++; movedList.push(rid); } const tm = s => { const [h, m] = s.split(':').map(Number); return h * 60 + m; }; if (Math.abs(tm(x.time) - tm(y.time)) > 5) shifted++; });
    return { byType, routes: [a.summary.routes, b.summary.routes], avg: [a.summary.avgJourney, b.summary.avgJourney], max: [a.summary.maxJourney, b.summary.maxJourney], cost: [a.summary.total, b.summary.total], fill: [a.summary.avgFill, b.summary.avgFill], unassigned: [a.summary.unassigned, b.summary.unassigned], moved, shifted, movedList };
  }

  async function roadMatrix(lls) {
    const keys = [], pts = [];
    lls.forEach(ll => { const k = key(ll); if (!keys.includes(k)) { keys.push(k); pts.push(ll); } });
    const n = pts.length, C = 45, dur = Array.from({ length: n }, () => new Array(n).fill(null));
    const chunks = []; for (let i = 0; i < n; i += C) chunks.push([...Array(Math.min(C, n - i)).keys()].map(x => x + i));
    for (const A of chunks) for (const B of chunks) {
      const ids = A === B ? A : A.concat(B), coords = ids.map(i => pts[i][1] + ',' + pts[i][0]).join(';');
      const src = A.map((_, x) => x).join(';'), dst = (A === B ? A.map((_, x) => x) : B.map((_, x) => A.length + x)).join(';');
      let ok = false;
      for (let t = 0; t < 3 && !ok; t++) {
        try { const res = await fetch(`${(typeof window !== 'undefined' && window.CONVOY_CONFIG && window.CONVOY_CONFIG.osrmBase) || 'https://router.project-osrm.org'}/table/v1/driving/${coords}?sources=${src}&destinations=${dst}&annotations=duration`);
          if (res.ok) { const j = await res.json(); if (j.code === 'Ok') { A.forEach((i, x) => B.forEach((k, y) => { dur[i][k] = j.durations[x][y]; })); ok = true; } } } catch (err) {}
        if (!ok) await new Promise(s => setTimeout(s, 1100));
      }
      if (!ok) return null;
    }
    return { keys, dur };
  }

  // Re-time a manually edited route. stops are in travel order. opt: { params, matrix, roadLegs[k] (car s), vias[k] ([[lat,lng]]) }
  function retime(base, stops, opt) {
    const P = Object.assign({}, DEFAULTS, opt.params || {}); P.types = (opt.params && opt.params.types) || TYPES;
    const MX = opt.matrix, IX = {}; if (MX) MX.keys.forEach((k, i) => { IX[k] = i; });
    const cls = base.cls, TF = trafficOf(P), F = CLS_FACTOR[cls] * TF, S = base.school, am = P.session === 'AM';
    const tv = (a, b) => { if (MX) { const i = IX[key(a)], j = IX[key(b)]; if (i != null && j != null && MX.dur[i][j] != null) return MX.dur[i][j] * F; } return travel(cls, a, b) * TF; };
    const leg = (k, a, b) => { const rl = opt.roadLegs && opt.roadLegs[k]; if (rl != null) return rl * F; const v = (opt.vias && opt.vias[k]) || []; if (!v.length) return tv(a, b); const ch = [a].concat(v, [b]); let t = 0; for (let i = 1; i < ch.length; i++) t += travel(cls, ch[i - 1], ch[i]) * TF; return t; };
    const dwell = n => P.baseDwell + P.perStudent * n;
    const t = prepTypes(P).find(x => x.type === base.type) || base, win = am ? P.amWin : P.session === 'PM' ? P.pmWin : P.asaWin;
    const target = toS(am ? P.amTarget : P.session === 'PM' ? P.pmTarget : P.asaTarget), earliest = toS(P.earliest), softS = P.targetCap * 60, hardS = P.hardCap * 60;
    const n = stops.length, load = stops.reduce((a, s) => a + s.n, 0), ts = [];
    let start, end, span, rideMin = 0;
    if (am) {
      const legs = stops.map((s, k) => dwell(s.n) + leg(k, s.ll, k + 1 < n ? stops[k + 1].ll : S));
      span = legs.reduce((a, b) => a + b, 0); end = target; start = end - span;
      if (start < earliest) { const sh = Math.min(earliest - start, toS(win[1]) - end); if (sh > 0) { start += sh; end += sh; } }
      let tt = start; stops.forEach((s, k) => { ts.push(tt); tt += legs[k]; });
      stops.forEach((s, k) => { rideMin += s.n * (end - ts[k]) / 60; });
    } else {
      start = target; let tt = target + P.schoolDwell;
      stops.forEach((s, k) => { tt += leg(k, k ? stops[k - 1].ll : S, s.ll) + (k ? dwell(stops[k - 1].n) : 0); ts.push(tt); });
      end = tt + dwell(stops[n - 1].n); span = end - start - P.schoolDwell;
      stops.forEach((s, k) => { rideMin += s.n * (ts[k] - start) / 60; });
    }
    const ord = am ? stops : stops.slice().reverse(); let mn = Infinity, back = 0;
    ord.forEach(s => { const r = hav(s.ll, S); back = Math.max(back, r - mn); mn = Math.min(mn, r); });
    const badges = ['Edited'];
    if (load > t.studentSeats) badges.push('Over capacity'); else if (load > t.cap) badges.push('Buffer used');
    if (span > hardS) badges.push('Over max journey'); else if (span > softS) badges.push('Over soft cap');
    if (load < t.floor) badges.push('Underfilled');
    if (P.loopbackM > 0 && back > P.loopbackM) badges.push(am ? 'Loop-back' : 'Not inside-out');
    const rpm = t.rpm != null ? t.rpm : 1, fixed = t.fixed != null ? t.fixed : base.cost.fixed;
    return Object.assign({}, base, {
      load, fill: load / base.studentSeats, spare: base.studentSeats - load, span, start, end, startT: fmt(start), endT: fmt(end), badges, rideMin: Math.round(rideMin), backM: Math.round(back),
      cost: { fixed, run: +(rpm * span / 60).toFixed(2), ride: +(P.rideCost * rideMin).toFixed(2), overtime: +(P.overtime * Math.max(0, span - softS) / 60).toFixed(2), floor: P.floorPenalty * Math.max(0, base.floor - load), stability: 0 },
      stops: stops.map((s, k) => Object.assign({}, s, { t: ts[k], time: fmt(ts[k]), dwell: dwell(s.n) }))
    });
  }
  function summarize(routes, session, riders, unassigned) {
    const am = session === 'AM', byType = {}, slots = {}, spans = routes.map(r => r.span / 60), sum = k => routes.reduce((t, r) => t + r.cost[k], 0);
    routes.forEach(r => { byType[r.type] = (byType[r.type] || 0) + 1; const k = fmt(Math.floor((am ? r.end : r.start) / 300) * 300); slots[k] = (slots[k] || 0) + 1; });
    const s = { riders, assigned: routes.reduce((t, r) => t + r.load, 0), unassigned, routes: routes.length, byType,
      avgJourney: spans.length ? spans.reduce((a, b) => a + b, 0) / spans.length : 0, maxJourney: spans.length ? Math.max(...spans) : 0,
      avgFill: routes.length ? routes.reduce((t, r) => t + r.fill, 0) / routes.length : 0,
      fixed: sum('fixed'), run: sum('run'), overtime: sum('overtime'), floor: sum('floor'), stability: sum('stability'), slots };
    s.total = s.fixed + s.run + s.overtime + s.floor; return s;
  }

  // Priority presets: only scoring weights and ride rules change; times, dwell, seats and fleet stay as set
  const PRESETS = {
    FEWEST_BUSES: { label: 'Fewest Buses', desc: 'Uses as few buses as possible. Rides and journeys can be longer, within the Max Journey limit.', v: { overtime: 8, floorPenalty: 5, rideCost: 0.02, maxDetour: 3.5, detourGrace: 15 }, fixed: { LARGE_45: 600, LARGE_40: 560, MEDIUM_23: 480, SMALL_13: 400 } },
    BALANCED: { label: 'Balanced', desc: 'Weighs bus count and ride time evenly.', v: { overtime: 15, floorPenalty: 10, rideCost: 0.05, maxDetour: 2.5, detourGrace: 10 }, fixed: { LARGE_45: 110, LARGE_40: 100, MEDIUM_23: 85, SMALL_13: 65 } },
    SHORTEST_RIDES: { label: 'Shortest Rides', desc: 'Keeps students on board for less time and journeys near the target. May need more buses.', v: { overtime: 30, floorPenalty: 10, rideCost: 0.15, maxDetour: 2, detourGrace: 8 }, fixed: { LARGE_45: 90, LARGE_40: 80, MEDIUM_23: 70, SMALL_13: 55 } }
  };
  function applyPreset(P, key) { const pr = PRESETS[key]; if (!pr) return P; return Object.assign({}, P, pr.v, { preset: key, types: P.types.map(t => Object.assign({}, t, pr.fixed[t.type] != null ? { fixed: pr.fixed[t.type] } : {})) }); }
  function presetOf(P) { return Object.keys(PRESETS).find(k => { const pr = PRESETS[k]; return Object.keys(pr.v).every(x => P[x] === pr.v[x]) && P.types.every(t => pr.fixed[t.type] == null || t.fixed === pr.fixed[t.type]); }) || null; }
  Object.assign(DEFAULTS, applyPreset(DEFAULTS, 'FEWEST_BUSES'));
  const ENGINES = { SWEEP_ACO: 'Convoy Pathfinder', RUIN_RECREATE: 'Ruin & Recreate only (jsprit method)' };
  function solve() { throw new Error('Convoy Pathfinder runs on the server. Check that /api/solve is reachable.'); }
  window.RoutingEngine = { EFFORT, EFFORT_KEYS, PRESETS, applyPreset, presetOf, ENGINES, prepTypes, trafficOf, CLS_FACTOR, solve, diff, DEFAULTS, TYPES, travel, fmt, roadMatrix, key, retime, summarize, serverOnly: true };
})();
