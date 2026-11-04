'use strict';
// Solve / retime / diff through the HTTP API with a made-up road matrix (30 km/h straight line), so no OSRM call.
process.env.ROUTING_SECRET = 'test-secret';
const test = require('node:test');
const assert = require('node:assert');
const { app } = require('../server');
const RE = globalThis.RoutingEngine;

const school = { lat: 1.3138, lng: 103.9283, name: "St. Stephen's School", short: 'SSS' };
const groups = [0, 1, 2, 3, 4, 5].map(i => ({
  uid: 'u' + i, stopId: 'BDSZ03-000' + i, name: 'Stop ' + i, riders: Array.from({ length: 6 }, (_, k) => 'R' + i + k),
  points: [{ pid: 'p' + i, sfx: 'A', label: 'BDSZ03-000' + i + 'A', lat: 1.32 + i * 0.004, lng: 103.92 + i * 0.003, usage: 'both', sizes: ['S', 'M', 'L'] }]
}));

function fakeMatrix(lls) {
  const keys = lls.map(RE.key), m = (a, b) => Math.hypot((a[0] - b[0]) * 111000, (a[1] - b[1]) * 111000);
  return { keys, dur: lls.map(a => lls.map(b => m(a, b) / 8.3)) };
}
const lls = [[school.lat, school.lng]].concat(groups.map(g => [g.points[0].lat, g.points[0].lng]));

let server, base;
test.before(() => new Promise(r => { server = app.listen(0, () => { base = 'http://127.0.0.1:' + server.address().port; r(); }); }));
test.after(() => server.close());

const post = (path, body, secret = 'test-secret') =>
  fetch(base + path, { method: 'POST', headers: { 'Content-Type': 'application/json', 'X-Routing-Secret': secret }, body: JSON.stringify(body) });

test('refuses calls without the secret', async () => {
  const r = await post('/solve', {}, 'wrong');
  assert.strictEqual(r.status, 401);
});

test('solves, re-times a route and compares plans', { timeout: 60000 }, async () => {
  const r = await post('/solve', { key: 'run-1', input: { school, groups, matrix: fakeMatrix(lls), params: { session: 'AM', runs: 1, timeLimit: 5 } } });
  assert.strictEqual(r.status, 200);
  const res = await r.json();
  assert.ok(res.routes.length >= 1);
  assert.strictEqual(res.summary.assigned, 36);
  assert.ok(res.assign.R00);

  // Progress of a solve sent with a key: done, with the route options checked.
  const p = await (await fetch(base + '/progress/run-1', { headers: { 'X-Routing-Secret': 'test-secret' } })).json();
  assert.strictEqual(p.step, 'done');
  assert.strictEqual(p.frac, 1);
  assert.ok(p.work.evals > 0);

  const route = res.routes[0];
  const t = await (await post('/retime', { base: route, stops: route.stops.slice().reverse(), school, params: res.params })).json();
  assert.ok(t.badges.includes('Edited'));
  assert.strictEqual(t.stops.length, route.stops.length);

  const small = await (await post('/retime', { base: { id: 'R09', type: 'SMALL_13' }, stops: route.stops.slice(0, 1), school, params: res.params })).json();
  assert.strictEqual(small.cls, 'S');
  assert.strictEqual(small.seats, 13);

  // Optimise: a route turned back to front is re-ordered; one already in its best order is left out.
  const twisted = route.stops.slice().reverse();
  if (twisted.length > 1) {
    const o = await (await post('/optimise', { routes: [{ id: route.id, base: route, stops: twisted }], school, params: res.params })).json();
    assert.strictEqual(o.routes.length, 1);
    assert.strictEqual(o.routes[0].order.length, twisted.length);
    assert.ok(o.routes[0].after.span <= o.routes[0].before.span || o.routes[0].after.ride <= o.routes[0].before.ride);
  }

  const d = await (await post('/diff', { a: res, b: res })).json();
  assert.deepStrictEqual(d.routes, [res.summary.routes, res.summary.routes]);
});
