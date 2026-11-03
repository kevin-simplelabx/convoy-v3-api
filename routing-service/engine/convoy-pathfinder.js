// Convoy Pathfinder routing engine, Calendar and Fares version (adds the 9-seater). Trial versions use convoy-pathfinder.js.
// Heuristic stand-in for OR-Tools: savings construction + relocate / reorder local search.
// Travel times are straight-line x detour / class speed (stand-in for the OSRM matrices).
(function () {
  const TYPES = [
    { type: 'LARGE_45', label: '45-seater', cls: 'L', seats: 45, law: true, floorPct: 0.6, headroom: 0.10, fixed: 110, rpm: 1, max: null, on: true },
    { type: 'LARGE_40', label: '40-seater', cls: 'L', seats: 40, law: true, floorPct: 0.6, headroom: 0.10, fixed: 100, rpm: 1, max: null, on: true },
    { type: 'MEDIUM_23', label: '23-seater', cls: 'M', seats: 23, law: false, floorPct: 0.55, headroom: 0.10, fixed: 85, rpm: 1, max: null, on: true },
    { type: 'SMALL_13', label: '13-seater', cls: 'S', seats: 13, law: false, floorPct: 0.5, headroom: 0.05, fixed: 65, rpm: 1, max: null, on: true },
    { type: 'SMALL_9', label: '9-seater', cls: 'S', seats: 9, law: false, floorPct: 0.5, headroom: 0, fixed: 55, rpm: 1, max: null, on: true }
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
    algorithm: 'SWEEP_ACO', ants: 14, acoIters: 100, sweepStarts: 8, rrMax: 12, maxSectorDeg: 40, sectorFromKm: 2, maxDetour: 2.5, detourGrace: 10, rideCost: 0.05, loopbackM: 500, detourPen: 15, detourFree: 3, areaM: 300, areaPen: 0, chainMoves: true, gapPen: 12, gapMin: 4, gapMax: 12, denseRiders: 30,
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
      const att = P.attendant === 'ALL_BUSES' || t.law || (Array.isArray(P.attSizes) && P.attSizes.includes(t.label)) ? 1 : 0, ss = t.seats - att;
      return Object.assign({}, t, { attendant: !!att, studentSeats: ss, cap: Math.floor((1 - (t.headroom != null ? t.headroom : (P.headroom || 0))) * ss), floor: Math.ceil(t.floorPct * ss) });
    });
  }

  const CLS_FACTOR = { S: 1.05, M: 1.15, L: 1.3 }; // bus vs car on the same road
  const key = ll => ll[0].toFixed(5) + ',' + ll[1].toFixed(5);
  const trafficOf = P => +(P.session === 'AM' ? P.amTraffic : P.session === 'PM' ? P.pmTraffic : P.asaTraffic) || 1; // peak-hour slowdown vs free-flow road times
  function solveOnce(input, ctx) {
    const t0 = performance.now(), DL = (ctx && ctx.deadline) || t0 + 60000, prog0 = (ctx && ctx.prog) || (() => {});
    const W = { phase: 'Grouping stops', i: 0, n: 0, extra: '', evals: 0 }, prog = f => prog0(f, W), work = (phase, i, n, extra) => { W.phase = phase; W.i = i; W.n = n; W.extra = extra || ''; };
    const MX = input.matrix, IX = {};
    if (MX) MX.keys.forEach((k, i) => { IX[k] = i; });
    const P = Object.assign({}, DEFAULTS, input.params || {}); P.types = (input.params && input.params.types) || TYPES;
    const TF = trafficOf(P);
    const tv = (cls, a, b) => { if (MX) { const i = IX[key(a)], j = IX[key(b)]; if (i != null && j != null && MX.dur[i][j] != null) return MX.dur[i][j] * CLS_FACTOR[cls] * TF; } return travel(cls, a, b) * TF; };
    const dir = P.session === 'AM' ? 'pickup' : 'dropoff';
    const S = [input.school.lat, input.school.lng];
    const types = prepTypes(P);
    const validation = [], unassigned = [];
    const maxCapBy = cls => Math.max(0, ...types.filter(t => t.cls === cls).map(t => t.cap));
    const classes = ['L', 'M', 'S'].filter(c => types.some(t => t.cls === c));
    if (!types.length) return { status: 'FAILED', validation: [{ code: 'NO_BUS_TYPES', level: 'Error', msg: 'Turn on at least one bus type' }] };

    // ---- groups + candidate points (pre-run validation, section 9)
    (input.noStop || []).forEach(r => { unassigned.push({ gid: null, riders: [r.rid], n: 1, reason: 'RIDER_NO_STOP', label: r.name }); });
    if ((input.noStop || []).length) validation.push({ code: 'RIDER_NO_STOP', level: 'Warning', msg: `${input.noStop.length} rider${input.noStop.length === 1 ? ' has' : 's have'} no stop. Excluded from this run` });
    if ((input.conflicts || []).length) validation.push({ code: 'RIDER_IN_CONFLICT', level: 'Warning', msg: `${input.conflicts.length} rider${input.conflicts.length === 1 ? ' is' : 's are'} covered by more than one stop. Excluded until resolved` });
    (input.conflicts || []).forEach(r => unassigned.push({ gid: null, riders: [r.rid], n: 1, reason: 'RIDER_IN_CONFLICT', label: r.name }));
    const groups = [];
    let errors = 0;
    input.groups.forEach(g0 => {
      const cands = g0.points.filter(p => p.usage === dir || p.usage === 'both');
      if (!cands.length) { errors++; validation.push({ code: 'NO_POINT_FOR_DIRECTION', level: 'Error', msg: `${g0.stopId} has no ${dir === 'pickup' ? 'pick-up' : 'drop-off'} point`, uid: g0.uid }); return; }
      const noSize = cands.filter(p => !p.sizes.length);
      if (noSize.length) { errors++; validation.push({ code: 'NO_BUS_SIZE_ON_POINT', level: 'Error', msg: `${g0.stopId}${noSize[0].sfx} has no bus size`, uid: g0.uid }); return; }
      const cp = cands.map(p => ({ pid: p.pid, sfx: p.sfx, label: p.label, ll: [p.lat, p.lng], sizes: p.sizes.filter(z => classes.includes(z)) })).filter(p => p.sizes.length);
      if (!cp.length) { unassigned.push({ gid: g0.uid, riders: g0.riders, n: g0.riders.length, reason: 'NO_BUS_TYPE_FOR_POINT', label: g0.stopId }); validation.push({ code: 'NO_BUS_TYPE_FOR_POINT', level: 'Warning', msg: `${g0.stopId} only allows bus sizes that are turned off`, uid: g0.uid }); return; }
      const big = Math.max(...cp.map(p => Math.max(...p.sizes.map(maxCapBy))));
      const rs = g0.riders.slice(), parts = Math.ceil(rs.length / big);
      if (parts > 1) validation.push({ code: 'CLUSTER_EXCEEDS_CAPACITY', level: 'Warning', msg: `${g0.stopId} has ${rs.length} riders, more than the largest bus allowed (${big}). Split into ${parts} boarding groups`, uid: g0.uid });
      for (let k = 0; k < parts; k++) {
        const mine = rs.slice(Math.floor(k * rs.length / parts), Math.floor((k + 1) * rs.length / parts));
        groups.push({ gid: g0.uid + (parts > 1 ? '#' + (k + 1) : ''), uid: g0.uid, stopId: g0.stopId, name: g0.name, riders: mine, n: mine.length, cands: cp, part: parts > 1 ? k + 1 : 0 });
      }
    });
    if (!MX) { errors++; validation.push({ code: 'ROAD_TIMES_UNAVAILABLE', level: 'Error', msg: 'Road travel times could not be loaded from the routing server. Nothing was planned. Try again in a minute' }); }
    if (errors) return { status: 'FAILED', validation, params: P, ms: Math.round(performance.now() - t0) };

    const dwell = g => P.baseDwell + P.perStudent * g.n;
    const hardS = P.hardCap * 60, softS = P.targetCap * 60;
    // HARD_CAP_UNREACHABLE
    const live = [];
    groups.forEach(g => {
      const best = Math.min(...g.cands.map(p => Math.min(...p.sizes.map(c => tv(c, p.ll, S)))));
      if (best + dwell(g) > hardS) { unassigned.push({ gid: g.gid, riders: g.riders, n: g.n, reason: 'HARD_CAP_UNREACHABLE', label: g.stopId }); validation.push({ code: 'HARD_CAP_UNREACHABLE', level: 'Warning', msg: `${g.stopId} is more than ${P.hardCap} min from school`, uid: g.uid }); }
      else live.push(g);
    });

    // polar coordinates relative to the school (origin)
    const kx = Math.cos(S[0] * Math.PI / 180);
    live.forEach(g => { const p = g.cands[0].ll, dx = (p[1] - S[1]) * 111320 * kx, dy = (p[0] - S[0]) * 110540; g.r = Math.hypot(dx, dy); g.th = Math.atan2(dy, dx); });
    // local density: riders within 1.5 km. Dense stops allow a short empty leg to the next pick-up, sparse stops a longer one
    live.forEach(g => { const p = g.cands[0].ll; let d = 0; live.forEach(o => { if (hav(p, o.cands[0].ll) < 1500) d += o.n; }); g.dens = d; g.gapOK = 60 * (P.gapMax - (P.gapMax - P.gapMin) * Math.min(1, d / (P.denseRiders || 30))); });
    // areas (option): stops within areaM of each other form one area. A bus is penalised for each area it shares with another bus, unless the area is too big for one bus
    const AREA = {}; if (P.areaPen > 0) { const par = live.map((_, i) => i), fd = i => { while (par[i] !== i) { par[i] = par[par[i]]; i = par[i]; } return i; };
      for (let i = 0; i < live.length; i++) for (let j = i + 1; j < live.length; j++) if (hav(live[i].cands[0].ll, live[j].cands[0].ll) < (P.areaM || 300)) par[fd(i)] = fd(j);
      const bigCap = Math.max(0, ...types.map(t => P.hardCapacity ? t.cap : t.studentSeats)); live.forEach((g, i) => { g.area = fd(i); AREA[g.area] = (AREA[g.area] || 0) + g.n; }); Object.keys(AREA).forEach(k => { if (AREA[k] > bigCap) AREA[k] = 0; }); }
    const outsideIn = seq => seq.slice().sort((a, b) => b.r - a.r);
    const cur = input.current && P.stability === 'KEEP_CURRENT' ? input.current : null;
    const curPoint = {}, curTime = {};
    if (cur) cur.routes.forEach(r => r.stops.forEach(st => { curPoint[st.gid] = st.pid; curTime[st.gid] = st.t; }));

    // ---- route evaluation: pick points + bus type for an ordered group list
    // angular width of a route around the school; stops within 800 m of school don't count
    // adaptive: stops within sectorFromKm of school are ignored, and the limit widens for routes nearer school (set at 10 km, up to 3x wider)
    function sectorLimit(seq) { const rs = seq.map(g => g.r).filter(r => r > (P.sectorFromKm ?? 2) * 1000).sort((a, b) => a - b); if (!rs.length) return Infinity; const med = rs[Math.floor(rs.length / 2)]; return P.maxSectorDeg * Math.min(3, Math.max(1, 10000 / med)); }
    function angSpan(seq) {
      const a = seq.filter(g => g.r == null || g.r > (P.sectorFromKm ?? 2) * 1000).map(g => g.th).filter(x => x != null).sort((x, y) => x - y);
      if (a.length < 2) return 0;
      let gap = a[0] + 2 * Math.PI - a[a.length - 1];
      for (let i = 1; i < a.length; i++) gap = Math.max(gap, a[i] - a[i - 1]);
      return (2 * Math.PI - gap) * 180 / Math.PI;
    }
    const LIM = {}, SUR = {}; types.forEach(t => { if (t.max != null && t.max !== '') LIM[t.type] = +t.max; });
    const hasLim = Object.keys(LIM).length > 0;
    function steer(rs) { if (!hasLim) return false; const c = {}; rs.forEach(r => { const k = r.ev.type.type; c[k] = (c[k] || 0) + 1; }); let ch = false;
      Object.keys(LIM).forEach(k => { const o = (c[k] || 0) - LIM[k], v0 = SUR[k] || 0, v = o > 0 ? Math.min(4000, v0 + 120 * o) : o < 0 ? Math.max(0, v0 - 120 * -o) : v0; if (v !== v0) { SUR[k] = v; ch = true; } }); return ch; }
    function evalRoute(seq) {
      W.evals++;
      const load = seq.reduce((t, g) => t + g.n, 0);
      if (seq.length > 1 && P.maxSectorDeg > 0 && angSpan(seq) > sectorLimit(seq)) return null;
      let best = null;
      for (const cls of classes) {
        const pts = [];
        let ok = true;
        for (const g of seq) {
          const c = g.cands.filter(p => p.sizes.includes(cls));
          if (!c.length) { ok = false; break; }
          let pick = c[0];
          if (c.length > 1) { const keep = cur && c.find(p => p.pid === curPoint[g.gid]); pick = keep || c.slice().sort((a, b) => tv(cls, a.ll, S) - tv(cls, b.ll, S))[0]; }
          pts.push(pick);
        }
        if (!ok) continue;
        let span = 0; const legT = [];
        for (let i = 0; i < seq.length; i++) { const l = dwell(seq[i]) + tv(cls, pts[i].ll, i + 1 < seq.length ? pts[i + 1].ll : S); legT.push(l); span += l; }
        let rideMin = 0, acc = 0, longRide = false; for (let i = seq.length - 1; i >= 0; i--) { acc += legT[i]; rideMin += seq[i].n * acc / 60; if (P.maxDetour > 0 && acc - dwell(seq[i]) > tv(cls, pts[i].ll, S) * P.maxDetour + (P.detourGrace || 0) * 60) longRide = true; }
        if (longRide && seq.length > 1) continue;
        if (span > hardS) continue;
        let detX = 0; if (P.detourPen > 0) for (let i = 1; i < seq.length; i++) { const a = pts[i - 1].ll, s = pts[i].ll, b = i + 1 < seq.length ? pts[i + 1].ll : S, dt = (tv(cls, a, s) + tv(cls, s, b) - tv(cls, a, b)) / 60; if (dt > (P.detourFree ?? 3)) detX += dt - (P.detourFree ?? 3); }
        let areaX = 0; if (P.areaPen > 0) { const on = {}; seq.forEach(g => { if (AREA[g.area]) on[g.area] = (on[g.area] || 0) + g.n; }); Object.keys(on).forEach(k => { areaX += (P.areaPen || 0) * (1 - on[k] / AREA[k]); }); }
        let gapX = 0; if (P.gapPen > 0) for (let i = 0; i + 1 < seq.length; i++) { const tr = legT[i] - dwell(seq[i]), al = Math.min(seq[i].gapOK ?? Infinity, seq[i + 1].gapOK ?? Infinity); if (tr > al) gapX += (tr - al) / 60; }
        for (const t of types) {
          if (t.cls !== cls) continue;
          if (P.hardCapacity && load > t.cap) continue;
          if (load > t.studentSeats) continue;
          const over = Math.max(0, span - softS) / 60, under = Math.max(0, t.floor - load);
          let stab = 0;
          if (cur) seq.forEach((g, i) => { if (curPoint[g.gid] && curPoint[g.gid] !== pts[i].pid) stab += P.pointPen * g.n; });
          const ride = P.rideCost * rideMin;
          const cost = t.fixed + (SUR[t.type] || 0) + t.rpm * span / 60 + P.overtime * over + P.floorPenalty * under + stab + ride + P.gapPen * gapX + (P.detourPen || 0) * detX + areaX;
          if (!best || cost < best.cost) best = { cost, type: t, cls, pts, span, load, over, under, stab, ride, rideMin, gapX, detX, areaX };
        }
      }
      return best;
    }
    // order: farthest first, then nearest-neighbour towards school, then or-opt
    function order(seq) {
      if (seq.length < 3) return seq.slice().sort((a, b) => hav(b.cands[0].ll, S) - hav(a.cands[0].ll, S));
      const rest = seq.slice(); rest.sort((a, b) => hav(b.cands[0].ll, S) - hav(a.cands[0].ll, S));
      const out = [rest.shift()];
      while (rest.length) {
        const last = out[out.length - 1].cands[0].ll;
        let bi = 0, bv = Infinity;
        rest.forEach((g, i) => { const v = hav(last, g.cands[0].ll) + 0.35 * hav(g.cands[0].ll, S); if (v < bv) { bv = v; bi = i; } });
        out.push(rest.splice(bi, 1)[0]);
      }
      return out;
    }
    function improveOrder(seq) {
      let cur0 = evalRoute(seq); if (!cur0) return { seq, ev: null };
      let improved = true, guard = 0;
      while (improved && guard++ < 20) {
        improved = false;
        for (let i = 0; i < seq.length; i++) for (let j = 0; j < seq.length; j++) {
          if (i === j) continue;
          const s2 = seq.slice(); const [g] = s2.splice(i, 1); s2.splice(j, 0, g);
          const e = evalRoute(s2);
          if (e && e.cost < cur0.cost - 0.01) { seq = s2; cur0 = e; improved = true; }
        }
      }
      return { seq, ev: cur0 };
    }

    // ---- initial solution
    let routes = [];
    const byGid = {}; live.forEach(g => { byGid[g.gid] = g; });
    if (cur) {
      cur.routes.forEach(r => { const seq = r.stops.map(st => byGid[st.gid]).filter(Boolean); if (!seq.length) return; const e = evalRoute(seq); if (e) { routes.push({ seq, ev: e }); seq.forEach(g => { g.done = true; }); } });
    }
    const rest0 = live.filter(g => !g.done).filter(g => { if (evalRoute([g])) return true; unassigned.push({ gid: g.gid, riders: g.riders, n: g.n, reason: 'NO_FEASIBLE_ROUTE', label: g.stopId }); return false; });
    live.forEach(g => { delete g.done; });
    const useSweep = P.algorithm !== 'SAVINGS' && !cur;
    if (useSweep && rest0.length) {
      // Cluster first: polar sweep around the school, sectors close when the next stop breaks capacity or journey limits
      const pol = rest0.slice().sort((a, b) => a.th - b.th), n = pol.length;
      let gi = 0, gmax = -1;
      for (let i = 0; i < n; i++) { const a = pol[i].th, b = i + 1 < n ? pol[i + 1].th : pol[0].th + 2 * Math.PI; if (b - a > gmax) { gmax = b - a; gi = (i + 1) % n; } }
      let bestSet = null;
      const starts = Math.max(1, Math.min(P.sweepStarts, n));
      for (let s = 0; s < starts; s++) for (const dirn of [1, -1]) {
        work('Sweep start angle', s * 2 + (dirn > 0 ? 1 : 2), starts * 2, dirn > 0 ? 'Clockwise' : 'Anticlockwise'); prog(0.005);
        const st = (gi + Math.floor(s * n / starts)) % n, ring = [];
        for (let k = 0; k < n; k++) ring.push(pol[((st + dirn * k) % n + n) % n]);
        const set = []; let curS = [];
        for (const g of ring) {
          const trial = curS.concat([g]), e = evalRoute(outsideIn(trial));
          if (e) curS = trial; else { if (curS.length) set.push(curS); curS = [g]; }
        }
        if (curS.length) set.push(curS);
        const rs = set.map(sec => { const seq = outsideIn(sec); return { seq, ev: evalRoute(seq) }; });
        const cost = rs.reduce((t, x) => t + x.ev.cost, 0);
        if (!bestSet || cost < bestSet.cost) bestSet = { rs, cost };
      }
      routes = routes.concat(bestSet.rs);
    } else rest0.forEach(g => routes.push({ seq: [g], ev: evalRoute([g]) }));

    // savings merge (end of A -> start of B)
    const cands = [];
    for (let a = 0; a < routes.length; a++) for (let b = 0; b < routes.length; b++) {
      if (a === b) continue;
      const A = routes[a], B = routes[b], la = A.seq[A.seq.length - 1].cands[0].ll, fb = B.seq[0].cands[0].ll;
      const d = hav(la, fb); if (d > 9000) continue;
      cands.push({ a: A, b: B, s: hav(la, S) - d });
    }
    cands.sort((x, y) => y.s - x.s);
    for (const c of (useSweep ? [] : cands)) {
      if (performance.now() > DL) break;
      if (c.a.dead || c.b.dead || c.a === c.b) continue;
      const seq = c.a.seq.concat(c.b.seq), e = evalRoute(seq);
      if (e && e.cost < c.a.ev.cost + c.b.ev.cost - 0.01) {
        const nr = { seq, ev: e };
        c.a.dead = c.b.dead = true; c.a.fwd = c.b.fwd = nr; routes.push(nr);
        // re-point pending candidates to merged route
        for (const d2 of cands) { while (d2.a.fwd) d2.a = d2.a.fwd; while (d2.b.fwd) d2.b = d2.b.fwd; }
      }
    }
    routes = routes.filter(r => !r.dead);

    const PURE_RR = P.algorithm === 'RUIN_RECREATE', RR = true;
    // ---- local search: relocate group to best position in another route
    const total = () => routes.reduce((t, r) => t + r.ev.cost, 0);
    const bestAt = (seq, g) => { let b = null; for (let k = 0; k <= seq.length; k++) { const s2 = seq.slice(); s2.splice(k, 0, g); const e2 = evalRoute(s2); if (e2 && (!b || e2.cost < b.ev.cost)) b = { seq: s2, ev: e2 }; } return b; };
    // swap: exchange one stop between two nearby routes. Lets a full bus that passes a stop take it by giving up a stop that suits the other bus better
    function swapPass(until, p0, p1) {
      let moved = false; const ll = g => g.cands[0].ll, nR = routes.length, near = (A, B) => A.seq.some(x => B.seq.some(y => hav(ll(x), ll(y)) < 2500)), tS = performance.now(), span = Math.max(1, until - tS);
      for (let a = 0; a < nR; a++) { prog(p0 + (p1 - p0) * Math.min(1, Math.max(a / nR, (performance.now() - tS) / span)));
      for (let b = a + 1; b < nR; b++) {
        if (performance.now() > until) return moved; const A = routes[a], B = routes[b]; if (!A || !B || !near(A, B)) continue;
        for (let i = 0; i < A.seq.length; i++) for (let j = 0; j < B.seq.length; j++) {
          if (performance.now() > until) return moved;
          const g = A.seq[i], h = B.seq[j]; if (!g || !h || hav(ll(g), ll(h)) > 2500) continue;
          const nA = bestAt(A.seq.filter(x => x !== g), h); if (!nA) continue;
          const nB = bestAt(B.seq.filter(x => x !== h), g); if (!nB) continue;
          if (nA.ev.cost + nB.ev.cost < A.ev.cost + B.ev.cost - 0.5) { A.seq = nA.seq; A.ev = nA.ev; B.seq = nB.seq; B.ev = nB.ev; moved = true; }
        }
      } }
      return moved;
    }
    // pool: take a route and its nearest neighbours, pool their stops and re-split them into fewer buses. Lets several full small buses become fewer larger ones
    function poolPass(until, lim) {
      if (routes.length < 3) return false; let moved = false; const tcount = () => { const c = {}; routes.forEach(r => { const k = r.ev.type.type; c[k] = (c[k] || 0) + 1; }); return c; };
      const cen = r => { let a = 0, b = 0; r.seq.forEach(g => { a += g.cands[0].ll[0]; b += g.cands[0].ll[1]; }); return [a / r.seq.length, b / r.seq.length]; };
      for (let a = 0; a < routes.length && performance.now() < until; a++) {
        const A = routes[a], cA = cen(A);
        const nb = routes.filter(r => r !== A).map(r => ({ r, d: hav(cA, cen(r)) })).filter(x => x.d < 6000).sort((x, y) => x.d - y.d).slice(0, 5).map(x => x.r);
        let done = false;
        for (let k = 2; k <= nb.length && !done && performance.now() < until; k++) {
          const grp = [A].concat(nb.slice(0, k)), pool = grp.flatMap(r => r.seq), old = grp.reduce((t, r) => t + r.ev.cost, 0);
          const pol = pool.slice().sort((x, y) => (x.th || 0) - (y.th || 0)), n = pol.length; let bestRs = null, bestC = old - 0.5;
          for (let s = 0; s < Math.min(n, 4); s++) for (const dir of [1, -1]) {
            const ring = []; for (let i = 0; i < n; i++) ring.push(pol[((Math.floor(s * n / 4) + dir * i) % n + n) % n]);
            const set = []; let cs = [], fail = false;
            for (const g of ring) { const tr = cs.concat([g]); if (evalRoute(outsideIn(tr))) cs = tr; else { if (cs.length) set.push(cs); cs = [g]; } }
            if (cs.length) set.push(cs); if (set.length >= grp.length) continue;
            const rs = set.map(sec => { const o = improveOrder(order(sec)); if (o.ev) return o; const q = outsideIn(sec); return { seq: q, ev: evalRoute(q) }; });
            if (rs.some(x => !x.ev)) continue;
            if (lim) { const c0 = tcount(), c1 = Object.assign({}, c0); grp.forEach(r => c1[r.ev.type.type]--); rs.forEach(x => c1[x.ev.type.type] = (c1[x.ev.type.type] || 0) + 1); if (Object.keys(LIM).some(k => (c1[k] || 0) > LIM[k] && (c1[k] || 0) > (c0[k] || 0))) continue; }
            const c = rs.reduce((t, x) => t + x.ev.cost, 0); if (c < bestC) { bestC = c; bestRs = rs; }
          }
          if (bestRs) { grp.forEach(r => routes.splice(routes.indexOf(r), 1)); bestRs.forEach(x => routes.push({ seq: x.seq, ev: x.ev })); moved = done = true; a = -1; }
        }
      }
      return moved;
    }
    // chain: stop g moves A -> B, and B makes room by passing one of its stops h to a third bus C. Fixes a full bus detouring for a rider the next bus passes
    function chainPass(until) {
      let moved = false; const ll = g => g.cands[0].ll;
      for (let a = 0; a < routes.length; a++) {
        const A = routes[a];
        for (const g of A.seq.slice()) {
          if (performance.now() > until) return moved;
          if (!routes.includes(A) || !A.seq.includes(g)) continue;
          const restA = A.seq.filter(x => x !== g), eA = restA.length ? evalRoute(restA) : { cost: 0 }; if (!eA) continue;
          let best = null;
          for (const B of routes) {
            if (B === A || !B.seq.some(x => hav(ll(x), ll(g)) < 1500)) continue;
            for (const h of B.seq) {
              if (performance.now() > until) break;
              const nB = bestAt(B.seq.filter(x => x !== h), g); if (!nB) continue;
              const base = eA.cost + nB.ev.cost - A.ev.cost - B.ev.cost; if (best && base - 0 >= best.delta + 400) continue;
              for (const C of routes) {
                if (C === A || C === B || !C.seq.some(x => hav(ll(x), ll(h)) < 1500)) continue;
                const nC = bestAt(C.seq, h); if (!nC) continue;
                const d = base + nC.ev.cost - C.ev.cost;
                if (d < -0.5 && (!best || d < best.delta)) best = { delta: d, B, C, nB, nC };
              }
            }
          }
          if (best) { best.B.seq = best.nB.seq; best.B.ev = best.nB.ev; best.C.seq = best.nC.seq; best.C.ev = best.nC.ev; if (restA.length) { A.seq = restA; A.ev = eA; } else { routes.splice(routes.indexOf(A), 1); a--; } moved = true; if (!restA.length) break; }
        }
      }
      return moved;
    }
    function localSearch(until, maxPass, p0, p1, label) {
    let pass = 0;
    while (performance.now() < until && pass++ < maxPass) {
      work(label || 'Swap and relocate pass', pass, maxPass, routes.length + ' buses');
      const f = k => p0 + (p1 - p0) * Math.min(1, (pass - 1 + k) / maxPass);
      let moved = swapPass(until, f(0), f(0.5)); prog(f(0.5)); if (P.chainMoves !== false && chainPass(until)) moved = true;
      for (const R of routes.slice()) {
        for (const g of R.seq.slice()) {
          if (performance.now() > until) break;
          if (!routes.includes(R) || !R.seq.includes(g)) continue;
          const rest = R.seq.filter(x => x !== g), eR = rest.length ? evalRoute(rest) : { cost: 0 };
          if (!eR) continue;
          let best = null;
          for (const T of routes) {
            if (T === R) continue;
            if (hav(T.seq[0].cands[0].ll, g.cands[0].ll) > 12000 && hav(T.seq[T.seq.length - 1].cands[0].ll, g.cands[0].ll) > 8000) continue;
            for (let k = 0; k <= T.seq.length; k++) {
              const s2 = T.seq.slice(); s2.splice(k, 0, g);
              const e = evalRoute(s2);
              if (!e) continue;
              const delta = e.cost + eR.cost - T.ev.cost - R.ev.cost;
              if (delta < -0.5 && (!best || delta < best.delta)) best = { T, s2, e, delta };
            }
          }
          if (best) {
            best.T.seq = best.s2; best.T.ev = best.e;
            if (rest.length) { R.seq = rest; R.ev = eR; } else routes.splice(routes.indexOf(R), 1);
            moved = true;
          }
        }
      }
      routes.forEach(r => { const o = improveOrder(r.seq); if (o.ev) { r.seq = o.seq; r.ev = o.ev; } });
      // merge two routes into one bus when cheaper
      for (let a = 0; a < routes.length && performance.now() < until; a++) for (let b = a + 1; b < routes.length; b++) {
        const A = routes[a], B = routes[b];
        if (hav(A.seq[0].cands[0].ll, B.seq[0].cands[0].ll) > 10000) continue;
        const o = improveOrder(order(A.seq.concat(B.seq)));
        if (o.ev && o.ev.cost < A.ev.cost + B.ev.cost - 0.5) { A.seq = o.seq; A.ev = o.ev; routes.splice(b, 1); b--; moved = true; }
      }
      if (poolPass(until)) moved = true;
      if (!moved) break;
    }
    }
    if (steer(routes)) routes.forEach(r => { const v = evalRoute(r.seq); if (v) r.ev = v; });
    localSearch(Math.min(DL, t0 + (DL - t0) * 0.15), 6, 0.01, 0.1);
    prog(0.1);
    // ---- Ruin & Recreate (jsprit method, Schrimpf et al. 2000 + Pisinger & Ropke 2007): remove a few stops, re-insert them with regret insertion, accept by threshold
    if (RR && routes.length) {
      const tRR = performance.now(), rrEnd = PURE_RR ? DL - (DL - t0) * 0.05 : t0 + (DL - t0) * 0.8, tSpan = Math.max(1, rrEnd - tRR), maxIt = Math.min(P.rrMaxIt || 3000, Math.max(200, Math.round((P.rrPerStop || 15) * live.length))), stall = P.rrStall || Math.max(1500, 8 * live.length), rrTo = PURE_RR ? 0.95 : 0.83, clone = rs => rs.map(r => ({ seq: r.seq.slice(), ev: r.ev })), costOf = rs => rs.reduce((t, r) => t + r.ev.cost, 0);
      const ll = g => g.cands[0].ll, near = (g, r) => r.seq.some(x => hav(ll(x), ll(g)) < 7000);
      const insertOpts = (rs, g) => { const out = []; rs.forEach((r, ri) => { if (!near(g, r)) return; for (let k = 0; k <= r.seq.length; k++) { const s2 = r.seq.slice(); s2.splice(k, 0, g); const ev = evalRoute(s2); if (ev) out.push({ ri, s2, ev, d: ev.cost - r.ev.cost }); } }); const solo = evalRoute([g]); if (solo) out.push({ ri: -1, s2: [g], ev: solo, d: solo.cost }); return out.sort((a, b) => a.d - b.d); };
      const recreate = (rs, rem, regret) => {
        rem = rem.slice();
        while (rem.length) {
          let pickI = 0, pickO = null;
          if (regret) { let bestR = -Infinity; rem.forEach((g, i) => { const o = insertOpts(rs, g); if (!o.length) return; const rg = (o[1] ? o[1].d : o[0].d + 1e4) - o[0].d; if (rg > bestR) { bestR = rg; pickI = i; pickO = o[0]; } }); }
          else { pickI = Math.floor(Math.random() * rem.length); pickO = insertOpts(rs, rem[pickI])[0]; }
          const g = rem.splice(pickI, 1)[0]; if (!pickO) { const ev = evalRoute([g]); if (ev) rs.push({ seq: [g], ev }); continue; }
          if (pickO.ri < 0) rs.push({ seq: pickO.s2, ev: pickO.ev }); else { rs[pickO.ri].seq = pickO.s2; rs[pickO.ri].ev = pickO.ev; }
        }
        return rs;
      };
      const ruin = rs => {
        const all = rs.flatMap(r => r.seq), n = all.length; if (n < 2) return [];
        const k = Math.max(2, Math.min(P.rrMax || 12, Math.round(n * 0.3), 2 + Math.floor(Math.random() * (P.rrMax || 12)))), x = Math.random(); let pick;
        if (x < 0.45) { const c = all[Math.floor(Math.random() * n)]; pick = all.slice().sort((a, b) => hav(ll(a), ll(c)) - hav(ll(b), ll(c))).slice(0, k); }
        else if (x < 0.75) pick = all.slice().sort(() => Math.random() - 0.5).slice(0, k);
        else if (x < 0.9) { const sc = all.map(g => { const r = rs.find(z => z.seq.includes(g)), rest = r.seq.filter(z => z !== g), e2 = rest.length ? evalRoute(rest) : { cost: 0 }; return { g, gain: e2 ? r.ev.cost - e2.cost : -1e9 }; }); pick = sc.sort((a, b) => b.gain - a.gain).slice(0, k).map(z => z.g); }
        else { const r = rs[Math.floor(Math.random() * rs.length)]; pick = r.seq.slice(); }
        const set = new Set(pick);
        for (let i = rs.length - 1; i >= 0; i--) { const r = rs[i], rest = r.seq.filter(g => !set.has(g)); if (rest.length === r.seq.length) continue; if (!rest.length) { rs.splice(i, 1); continue; } let ev = evalRoute(rest), sq = rest; if (!ev) { sq = order(rest); ev = evalRoute(sq); } if (!ev) { r.seq.filter(g => set.has(g)).forEach(g => set.delete(g)); continue; } r.seq = sq; r.ev = ev; }
        return [...set];
      };
      let cur = clone(routes), curC = costOf(cur), best = clone(cur), bestC = curC; const T0 = 0.015 * curC; let it = 0, since = 0;
      // count-based: stop after maxIt iterations, or after 'stall' iterations with no new best, or at the safety deadline
      while (it < maxIt && since < stall && performance.now() < rrEnd) {
        it++; since++; if (it % 5 === 0) work('Ruin and Recreate iteration', it, maxIt, 'Best ' + Math.round(bestC).toLocaleString() + ' pts');
        if (hasLim && it % 40 === 1 && steer(cur)) { const re = rs => rs.forEach(r => { const v = evalRoute(r.seq); if (v) r.ev = v; }); re(cur); re(best); curC = costOf(cur); bestC = costOf(best); since = 0; }
        const nx = clone(cur), rem = ruin(nx); if (!rem.length) break;
        recreate(nx, rem, Math.random() < 0.6); const c = costOf(nx), T = T0 * Math.max(0, 1 - it / maxIt);
        if (c < curC + T) { cur = nx; curC = c; } if (c < bestC - 0.01) { best = clone(nx); bestC = c; since = 0; }
        if (it % 10 === 0) prog(0.1 + (rrTo - 0.1) * Math.min(1, Math.max(it / maxIt, (performance.now() - tRR) / tSpan)));
      }
      prog(rrTo);
      routes = best; routes.forEach(r => { const o = improveOrder(r.seq); if (o.ev) { r.seq = o.seq; r.ev = o.ev; } }); routes.rrIters = it;
    }
    // Route second: Ant Colony Optimisation per route. Outside-in order seeds the pheromone; ants may break it (loop-backs, zig-zags)
    function aco(seq0) {
      const n = seq0.length;
      const cands0 = [outsideIn(seq0), seq0].map(s => ({ seq: s, ev: evalRoute(s) })).filter(x => x.ev);
      let best = cands0.sort((a, b) => a.ev.cost - b.ev.cost)[0];
      if (!best || n < 3) return best || { seq: seq0, ev: evalRoute(seq0) };
      const G = seq0, idx = new Map(G.map((g, i) => [g, i])), rmax = Math.max(...G.map(g => g.r)) || 1;
      const oi = outsideIn(G).map(g => idx.get(g));
      const tau = Array.from({ length: n }, () => new Array(n).fill(1)), tau0 = new Array(n).fill(1);
      for (let k = 0; k + 1 < n; k++) tau[oi[k]][oi[k + 1]] = 3;
      tau0[oi[0]] = 3;
      const eta = G.map(a => G.map(b => a === b ? 0 : 1 / (tv('L', a.cands[0].ll, b.cands[0].ll) + 30)));
      const pick = w => { let t = w.reduce((a, b) => a + b, 0), x = Math.random() * t; for (let i = 0; i < w.length; i++) { x -= w[i]; if (x <= 0) return i; } return w.length - 1; };
      for (let it = 0; it < P.acoIters && performance.now() < DL; it++) {
        W.i = it + 1; W.n = P.acoIters; prog(W.fr || 0.83);
        let iterBest = null;
        for (let a = 0; a < P.ants; a++) {
          const left = new Set(G.map((_, i) => i)), path = [];
          let i0 = pick(G.map((g, i) => tau0[i] * Math.pow(g.r / rmax + 0.05, 2)));
          path.push(i0); left.delete(i0);
          while (left.size) { const L = [...left], j = L[pick(L.map(j => tau[i0][j] * Math.pow(eta[i0][j] * 600, 2)))]; path.push(j); left.delete(j); i0 = j; }
          const seq = path.map(i => G[i]), ev = evalRoute(seq);
          if (ev && (!iterBest || ev.cost < iterBest.ev.cost)) iterBest = { seq, ev, path };
        }
        for (let i = 0; i < n; i++) { tau0[i] *= 0.7; for (let j = 0; j < n; j++) tau[i][j] = Math.max(0.05, tau[i][j] * 0.7); }
        const dep = x => { const q = best.ev.cost / x.ev.cost; tau0[x.path[0]] += q; for (let k = 0; k + 1 < x.path.length; k++) tau[x.path[k]][x.path[k + 1]] += q; };
        if (iterBest) { if (iterBest.ev.cost < best.ev.cost) best = iterBest; dep(iterBest); }
        if (best.path) dep(best);
      }
      const pol2 = improveOrder(best.seq);
      return pol2.ev && pol2.ev.cost < best.ev.cost ? pol2 : { seq: best.seq, ev: best.ev };
    }
    if (P.algorithm !== 'SAVINGS' && !PURE_RR) { const tA = performance.now(), aSpan = Math.max(1, DL - tA); routes.forEach((rt, k) => { work(`Ant Colony | Route ${k + 1} of ${routes.length} | Iteration`, 0, P.acoIters, P.ants + ' ants each'); W.fr = 0.83 + 0.14 * k / routes.length; const o = aco(rt.seq); if (o && o.ev) { rt.seq = o.seq; rt.ev = o.ev; } prog(0.83 + 0.14 * Math.min(1, Math.max((k + 1) / routes.length, (performance.now() - tA) / aSpan))); }); }
    localSearch(Math.min(DL, performance.now() + Math.max(400, (DL - t0) * 0.05)), 3, 0.97, 1, 'Final polish pass'); // final polish after ACO: relocate, swap, merge
    if (P.chainMoves !== false) { work('Three-bus exchanges', 1, 1, routes.length + ' buses'); if (chainPass(performance.now() + Math.max(2000, (DL - t0) * 0.1))) routes.forEach(r => { const o = improveOrder(r.seq); if (o.ev) { r.seq = o.seq; r.ev = o.ev; } }); }
    routes.forEach(rt => { let mn = Infinity, back = 0; rt.seq.forEach(g => { if (g.r == null) return; back = Math.max(back, g.r - mn); mn = Math.min(mn, g.r); }); rt.backM = Math.round(back); rt.broken = P.loopbackM > 0 && back > P.loopbackM; });
    // use spare allowance of limited bus types: the surcharge can overshoot during search and leave allowed larger buses unused
    if (hasLim) { Object.keys(SUR).forEach(k => { SUR[k] = 0; }); routes.forEach(r => { const v = evalRoute(r.seq); if (v) r.ev = v; }); work('Filling spare larger buses', 1, 1, routes.length + ' buses'); poolPass(performance.now() + Math.max(1500, (DL - t0) * 0.05), true); }
    // fleet limits per type (max_vehicle_limit): downgrade surplus routes to next best feasible type or drop
    types.forEach(t => {
      if (t.max == null || t.max === '') return;
      const mine = routes.filter(r => r.ev.type.type === t.type).sort((a, b) => a.ev.load - b.ev.load);
      while (mine.length > +t.max) {
        const r = mine.shift();
        const alt = types.filter(x => x.type !== t.type && x.cls === r.ev.cls && x.cap >= r.ev.load);
        if (alt.length) { const x = alt.sort((a, b) => a.fixed - b.fixed)[0]; r.ev = Object.assign({}, r.ev, { type: x, under: Math.max(0, x.floor - r.ev.load) }); }
        else { routes.splice(routes.indexOf(r), 1); r.seq.forEach(g => unassigned.push({ gid: g.gid, riders: g.riders, n: g.n, reason: 'FLEET_LIMIT', label: g.stopId })); }
      }
    });

    // ---- schedule + outputs
    const am = P.session === 'AM';
    const win = am ? P.amWin : P.session === 'PM' ? P.pmWin : P.asaWin;
    const target = toS(am ? P.amTarget : P.session === 'PM' ? P.pmTarget : P.asaTarget), earliest = toS(P.earliest);
    routes.sort((a, b) => b.ev.span - a.ev.span);
    const outRoutes = routes.map((r, i) => {
      const ev = r.ev, t = ev.type;
      let seq = r.seq.map((g, k) => ({ g, p: ev.pts[k] }));
      const legs = [];
      for (let k = 0; k < seq.length; k++) legs.push(dwell(seq[k].g) + tv(ev.cls, seq[k].p.ll, k + 1 < seq.length ? seq[k + 1].p.ll : S));
      let stops;
      let start, end;
      if (am) {
        end = target; start = end - ev.span;
        if (start < earliest) { const shift = Math.min(earliest - start, toS(win[1]) - end); start += shift; end += shift; }
        let tt = start; stops = seq.map((x, k) => { const o = { t: tt }; tt += legs[k]; return Object.assign(o, x); });
      } else {
        // PM: school -> reverse order
        seq = seq.slice().reverse();
        const back = legs.slice().reverse();
        start = target + P.schoolDwell; let tt = start;
        stops = seq.map((x, k) => { const leg = k === 0 ? tv(ev.cls, S, x.p.ll) : tv(ev.cls, seq[k - 1].p.ll, x.p.ll) + dwell(seq[k - 1].g); tt += leg; return Object.assign({ t: tt }, x); });
        end = tt + dwell(seq[seq.length - 1].g);
        start = target; 
      }
      const span = am ? ev.span : end - start - P.schoolDwell;
      const badges = [];
      if (ev.load < t.floor) badges.push('Underfilled');
      if (span > softS) badges.push('Over soft cap');
      if (ev.load > t.cap) badges.push('Buffer used');
      if (am && start < earliest) badges.push('Before earliest pick-up');
      if (r.broken) badges.push(am ? 'Loop-back' : 'Not inside-out');
      if ((ev.gapX || 0) >= 3) badges.push('Long empty leg');
      let timeShift = 0;
      if (cur) stops.forEach(s => { const t0 = curTime[s.g.gid]; if (t0 != null) timeShift += Math.max(0, Math.abs(s.t - t0) / 60 - P.tol) * s.g.n; });
      return {
        id: 'R' + String(i + 1).padStart(2, '0'), type: t.type, label: t.label, cls: ev.cls, seats: t.seats, attendant: t.attendant, studentSeats: t.studentSeats, cap: t.cap, floor: t.floor,
        load: ev.load, fill: ev.load / t.studentSeats, spare: t.studentSeats - ev.load, span, start, end, startT: fmt(start), endT: fmt(end), badges,
        rideMin: Math.round(ev.rideMin), gapMin: Math.round(ev.gapX || 0), backM: r.backM || 0, sector: Math.round(angSpan(r.seq)), cost: { fixed: t.fixed, run: +(t.rpm * span / 60).toFixed(2), ride: +(ev.ride || 0).toFixed(2), overtime: +(P.overtime * Math.max(0, span - softS) / 60).toFixed(2), floor: P.floorPenalty * Math.max(0, t.floor - ev.load), stability: +(ev.stab + timeShift * P.timePen).toFixed(2) },
        stops: stops.map(s => ({ gid: s.g.gid, uid: s.g.uid, stopId: s.g.stopId, name: s.g.name, part: s.g.part, pid: s.p.pid, sfx: s.p.sfx, ll: s.p.ll, n: s.g.n, riders: s.g.riders, t: s.t, time: fmt(s.t), dwell: dwell(s.g) })),
        school: S
      };
    });
    const assign = {};
    outRoutes.forEach(r => r.stops.forEach(s => s.riders.forEach(rid => { assign[rid] = { uid: s.uid, pid: s.pid, route: r.id, time: s.time, ride: Math.round((am ? r.end - s.t : s.t - r.start) / 60) }; })));
    const riders = input.groups.reduce((t, g) => t + g.riders.length, 0) + (input.noStop || []).length + (input.conflicts || []).length;
    const byType = {}; outRoutes.forEach(r => { byType[r.type] = (byType[r.type] || 0) + 1; });
    const spans = outRoutes.map(r => r.span / 60);
    const sum = k => outRoutes.reduce((t, r) => t + r.cost[k], 0);
    const slots = {}; outRoutes.forEach(r => { const k = fmt(Math.floor((am ? r.end : r.start) / 300) * 300); slots[k] = (slots[k] || 0) + 1; });
    const summary = {
      riders, assigned: Object.keys(assign).length, unassigned: unassigned.reduce((t, u) => t + u.n, 0), routes: outRoutes.length, byType,
      avgJourney: spans.length ? spans.reduce((a, b) => a + b, 0) / spans.length : 0, maxJourney: spans.length ? Math.max(...spans) : 0,
      avgFill: outRoutes.length ? outRoutes.reduce((t, r) => t + r.fill, 0) / outRoutes.length : 0,
      fixed: sum('fixed'), run: sum('run'), overtime: sum('overtime'), floor: sum('floor'), stability: sum('stability'),
      slots
    };
    summary.total = summary.fixed + summary.run + summary.overtime + summary.floor;
    return { status: unassigned.length ? 'COMPLETED_WITH_UNASSIGNED' : 'COMPLETED', road: !!MX, validation, routes: outRoutes, assign, unassigned, summary, params: P, ms: Math.round(performance.now() - t0), dir, obj: routes.reduce((t, r) => t + r.ev.cost, 0) };
  }

  // Multi-start: 'runs' independent searches, keep the lowest-cost plan. timeLimit is only a safety cut-off shared across runs
  function solve(input, onProgress) {
    const t0 = performance.now(), P = Object.assign({}, DEFAULTS, input.params || {});
    if (P.effort && EFFORT[P.effort]) { let ek = P.effort; if (P.maxEffort && EFFORT_KEYS.indexOf(ek) > EFFORT_KEYS.indexOf(P.maxEffort)) ek = P.maxEffort; P.runs = EFFORT[ek].runs; P.timeLimit = EFFORT[ek].sec; }
    const runs = Math.max(1, Math.min(20, Math.round(+P.runs || 1))), DL = t0 + Math.min(120, Math.max(5, +P.timeLimit || 60)) * 1000 - 400; // hard cap 120 s (Max effort)
    let best = null, bestS = Infinity, done = 0, cut = false, last = 0, evBase = 0, lastW = null;
    const rep = (f, k, w) => { if (w) lastW = w; const now = performance.now(); if (!onProgress || (now - last < 60 && f < 1)) return; last = now; const W = lastW || {}; onProgress({ frac: Math.min(1, f), run: k, runs, elapsed: now - t0, left: Math.max(0, DL - now), work: { phase: W.phase || '', i: W.i || 0, n: W.n || 0, extra: W.extra || '', evals: evBase + (W.evals || 0) } }); };
    for (let k = 0; k < runs; k++) {
      const now = performance.now(); if (k && now >= DL) { cut = true; break; }
      const dl = now + (DL - now) / (runs - k), r = solveOnce(input, { deadline: dl, prog: (f, w) => rep((k + f) / runs, k + 1, w) }); if (lastW) { evBase += lastW.evals || 0; lastW = Object.assign({}, lastW, { evals: 0 }); }
      if (r.status === 'FAILED') return r;
      if (performance.now() >= dl - 5) cut = true;
      const sc = (r.obj != null ? r.obj : r.summary.total) + (+P.unassignedPenalty || 50000) * r.summary.unassigned;
      done++; if (sc < bestS - 0.01) { best = r; bestS = sc; r.bestRun = k + 1; }
    }
    rep(1, done);
    best.search = { runs, done, bestRun: best.bestRun, cut, evals: evBase + ((lastW && lastW.evals) || 0) }; best.ms = Math.round(performance.now() - t0);
    return best;
  }

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
    FEWEST_BUSES: { label: 'Fewest Buses', desc: 'Uses as few buses as possible. Rides and journeys can be longer, within the Max Journey limit.', v: { overtime: 8, floorPenalty: 5, rideCost: 0.02, maxDetour: 3.5, detourGrace: 15 }, fixed: { LARGE_45: 600, LARGE_40: 560, MEDIUM_23: 480, SMALL_13: 400, SMALL_9: 360 } },
    BALANCED: { label: 'Balanced', desc: 'Weighs bus count and ride time evenly.', v: { overtime: 15, floorPenalty: 10, rideCost: 0.05, maxDetour: 2.5, detourGrace: 10 }, fixed: { LARGE_45: 110, LARGE_40: 100, MEDIUM_23: 85, SMALL_13: 65, SMALL_9: 55 } },
    SHORTEST_RIDES: { label: 'Shortest Rides', desc: 'Keeps students on board for less time and journeys near the target. May need more buses.', v: { overtime: 30, floorPenalty: 10, rideCost: 0.15, maxDetour: 2, detourGrace: 8 }, fixed: { LARGE_45: 90, LARGE_40: 80, MEDIUM_23: 70, SMALL_13: 55, SMALL_9: 45 } }
  };
  function applyPreset(P, key) { const pr = PRESETS[key]; if (!pr) return P; return Object.assign({}, P, pr.v, { preset: key, types: P.types.map(t => Object.assign({}, t, pr.fixed[t.type] != null ? { fixed: pr.fixed[t.type] } : {})) }); }
  function presetOf(P) { return Object.keys(PRESETS).find(k => { const pr = PRESETS[k]; return Object.keys(pr.v).every(x => P[x] === pr.v[x]) && P.types.every(t => pr.fixed[t.type] == null || t.fixed === pr.fixed[t.type]); }) || null; }
  Object.assign(DEFAULTS, applyPreset(DEFAULTS, 'FEWEST_BUSES'));
  const ENGINES = { SWEEP_ACO: 'Convoy Pathfinder', RUIN_RECREATE: 'Ruin & Recreate only (jsprit method)' };
  window.RoutingEngine = { EFFORT, EFFORT_KEYS, PRESETS, applyPreset, presetOf, ENGINES, prepTypes, trafficOf, CLS_FACTOR, solve, diff, DEFAULTS, TYPES, travel, fmt, roadMatrix, key, retime, summarize };
})();
