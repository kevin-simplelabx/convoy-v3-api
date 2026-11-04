'use strict';
// Optimise (port of Convoy OS bestOrder): the stop order of a route that costs least for its passengers and the bus —
// run + ride + overtime of the re-timed route, a big penalty past the hard cap. Up to 7 stops every order is tried;
// longer routes improve by 2-opt (reverse a stretch) and or-opt (move one stop), at most 60 rounds. null = already best.
function bestOrder(RE, base, stops, opt) {
  if (!stops || stops.length < 2) return null;
  const P = Object.assign({}, RE.DEFAULTS, opt.params || {});
  const score = ord => {
    const o = RE.retime(base, ord, { params: opt.params, matrix: opt.matrix });
    return { c: o.cost.run + o.cost.ride + o.cost.overtime + (o.span > P.hardCap * 60 ? 1e5 : 0), span: o.span, ride: o.rideMin };
  };
  const first = stops.slice(), n = first.length, s0 = score(first);
  let best = first, bs = s0;
  if (n <= 7) {
    const perm = (a, k) => {
      if (k === a.length) { const sc = score(a); if (sc.c < bs.c - 1e-6) { bs = sc; best = a.slice(); } return; }
      for (let i = k; i < a.length; i++) { [a[k], a[i]] = [a[i], a[k]]; perm(a, k + 1); [a[k], a[i]] = [a[i], a[k]]; }
    };
    perm(first.slice(), 0);
  } else {
    let cur = first.slice(), cs = s0, imp = true, guard = 0;
    while (imp && guard++ < 60) {
      imp = false;
      for (let i = 0; i < n - 1 && !imp; i++) for (let j = i + 1; j < n && !imp; j++) {
        const c = cur.slice(0, i).concat(cur.slice(i, j + 1).reverse(), cur.slice(j + 1)), sc = score(c);
        if (sc.c < cs.c - 1e-6) { cur = c; cs = sc; imp = true; }
      }
      for (let i = 0; i < n && !imp; i++) for (let j = 0; j < n && !imp; j++) {
        if (i === j) continue;
        const c = cur.slice(), [m] = c.splice(i, 1);
        c.splice(j, 0, m);
        const sc = score(c);
        if (sc.c < cs.c - 1e-6) { cur = c; cs = sc; imp = true; }
      }
    }
    best = cur; bs = cs;
  }
  if (best.every((x, i) => x === first[i])) return null;
  return { order: best.map(s => first.indexOf(s)), before: { span: s0.span, ride: s0.ride }, after: { span: bs.span, ride: bs.ride } };
}

module.exports = { bestOrder };
