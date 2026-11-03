'use strict';
// Convoy routing service: the Convoy Pathfinder engine behind a small internal HTTP API for the Rails app.
//   POST /solve   { input }                       → engine result (road times from OSRM unless input.matrix is given)
//   POST /retime  { base, stops, school, params, vias, type } → a hand-edited route re-timed (type: change bus type)
//   POST /diff    { a, b }                        → plan comparison
//   GET  /meta                                    → engine defaults, bus types, priority presets, effort levels, engines
//   GET  /health                                  → { ok, running, queued, osrm }
// Every call except /health needs the header X-Routing-Secret = ROUTING_SECRET. Solves run in worker threads,
// SOLVE_CONCURRENCY at a time (the rest wait); the engine stops itself at its effort time (max 120 s).
const path = require('path');
const express = require('express');
const { Worker } = require('worker_threads');
const { load } = require('./lib/engine');
const { matrix, pointsOf } = require('./lib/matrix');

const PORT = +process.env.PORT || 4000;
const SECRET = process.env.ROUTING_SECRET || '';
const OSRM_URL = (process.env.OSRM_URL || 'https://router.project-osrm.org').replace(/\/+$/, '');
const CONCURRENCY = Math.max(1, +process.env.SOLVE_CONCURRENCY || 2);
const MAX_EFFORT = process.env.MAX_EFFORT || 'high';

const RE = load(OSRM_URL);
const app = express();
app.use(express.json({ limit: '20mb' }));

let running = 0;
const queue = [];

function runSolve(input) {
  return new Promise((resolve, reject) => {
    const start = () => {
      running++;
      const w = new Worker(path.join(__dirname, 'worker.js'), { workerData: { input, osrmBase: OSRM_URL } });
      const stop = setTimeout(() => w.terminate(), 125000);
      let settled = false;
      const done = fn => v => {
        if (settled) return;
        settled = true;
        clearTimeout(stop);
        running--;
        if (queue.length) queue.shift()();
        fn(v);
      };
      w.once('message', done(m => (m.ok ? resolve(m.res) : reject(new Error(m.err)))));
      w.once('error', done(reject));
      w.once('exit', code => done(reject)(new Error('Solver stopped (' + code + ')')));
    };
    running < CONCURRENCY ? start() : queue.push(start);
  });
}

app.get('/health', (req, res) => res.json({ ok: true, running, queued: queue.length, osrm: OSRM_URL }));

app.use((req, res, next) => {
  if (!SECRET || req.get('X-Routing-Secret') !== SECRET) return res.status(401).json({ error: 'Not allowed' });
  next();
});

app.post('/solve', async (req, res) => {
  const t0 = Date.now();
  try {
    const input = req.body.input || {};
    input.params = Object.assign({}, input.params, { maxEffort: MAX_EFFORT });
    if (input.matrix === undefined) input.matrix = await matrix(RE, pointsOf(input));
    const out = await runSolve(input);
    res.set('X-Solve-Ms', String(Date.now() - t0)).json(out);
  } catch (e) {
    console.error('[solve]', e);
    res.status(500).json({ error: String(e.message || e) });
  }
});

app.post('/retime', async (req, res) => {
  try {
    const { base, stops, school, params, vias, roadLegs, type } = req.body;
    const lls = [[school.lat, school.lng]].concat(stops.map(s => s.ll));
    const mx = await matrix(RE, lls);
    // A new bus type (or a route drawn by hand): seats, capacity, floor and attendant from the engine's bus types.
    const P = Object.assign({}, RE.DEFAULTS, params || {});
    const t = (type || !base.cls) && RE.prepTypes(P).find(x => x.type === (type || base.type));
    if ((type || !base.cls) && !t) return res.status(422).json({ error: 'Unknown or unavailable bus type ' + (type || base.type) });
    const sized = t ? { type: t.type, label: t.label, cls: t.cls, seats: t.seats, studentSeats: t.studentSeats, cap: t.cap, floor: t.floor, attendant: t.attendant,
                        cost: Object.assign({ fixed: t.fixed }, base.cost) } : {};
    const base2 = Object.assign({}, base, sized, { school: [school.lat, school.lng] });
    res.json(RE.retime(base2, stops, { params, matrix: mx, vias, roadLegs }));
  } catch (e) {
    console.error('[retime]', e);
    res.status(500).json({ error: String(e.message || e) });
  }
});

app.get('/meta', (req, res) => {
  res.json({ defaults: RE.DEFAULTS, types: RE.TYPES, presets: RE.PRESETS, effort: RE.EFFORT, effort_keys: RE.EFFORT_KEYS, max_effort: MAX_EFFORT,
             engines: RE.ENGINES });
});

app.post('/diff', (req, res) => {
  try {
    res.json(RE.diff(req.body.a, req.body.b));
  } catch (e) {
    res.status(500).json({ error: String(e.message || e) });
  }
});

if (require.main === module) app.listen(PORT, () => console.log('Convoy routing service on :' + PORT + ', OSRM ' + OSRM_URL));

module.exports = { app };
