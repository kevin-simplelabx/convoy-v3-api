'use strict';
// Road travel-time matrices from OSRM (engine roadMatrix: 45x45 table requests), kept in memory (LRU) by point set.
const MAX = 200;
const cache = new Map();

async function matrix(RE, lls) {
  const k = lls.map(RE.key).sort().join('|');
  if (cache.has(k)) {
    const hit = cache.get(k);
    cache.delete(k);
    cache.set(k, hit);
    return hit;
  }
  const mx = await RE.roadMatrix(lls);
  if (mx) {
    cache.set(k, mx);
    if (cache.size > MAX) cache.delete(cache.keys().next().value);
  }
  return mx;
}

// The school and every PUDO point of the input's groups (as the console's loadMatrix does).
function pointsOf(input) {
  const lls = [[input.school.lat, input.school.lng]];
  (input.groups || []).forEach(g => (g.points || []).forEach(p => lls.push([p.lat, p.lng])));
  return lls;
}

module.exports = { matrix, pointsOf };
