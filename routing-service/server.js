'use strict';
// Convoy routing service: the Convoy Pathfinder engine behind a small internal HTTP API for the Rails app.
//   POST /solve   { input, key }                  → engine result (road times from OSRM unless input.matrix is given)
//   GET  /progress/:key                           → how a solve sent with that key is going (kept in memory, 10 min)
//   POST /retime  { base, stops, school, params, vias, type } → a hand-edited route re-timed (type: change bus type)
//   POST /optimise { routes: [{ id, base, stops }], school, params } → the best stop order of each route that can do better
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
const { bestOrder } = require('./lib/optimise');

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
// key → { step: queued | matrix | solving | done, frac, run, runs, elapsed, left, work: { phase, i, n, extra, evals }, log: [last 4 phases], at }
const progress = new Map();

function note(key, patch) {
  if (!key) return;
  const cur = progress.get(key) || { step: 'queued', log: [] };
  const work = patch.work, prev = cur.work;
  if (work && prev && prev.phase && (prev.phase !== work.phase || cur.run !== patch.run)) {
    cur.log = [{ run: cur.run, phase: prev.phase, i: prev.i, n: prev.n }].concat(cur.log).slice(0, 4);
  }
  progress.set(key, Object.assign(cur, patch, { at: Date.now() }));
  for (const [k, v] of progress) if (Date.now() - v.at > 600000) progress.delete(k);
}

function runSolve(input, key) {
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
      const finish = done(m => (m.ok ? resolve(m.res) : reject(new Error(m.err))));
      w.on('message', m => (m.prog ? note(key, Object.assign({ step: 'solving' }, m.prog)) : finish(m)));
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
    const input = req.body.input || {}, key = req.body.key && String(req.body.key);
    input.params = Object.assign({}, input.params, { maxEffort: MAX_EFFORT });
    note(key, { step: 'matrix' });
    if (input.matrix === undefined) input.matrix = await matrix(RE, pointsOf(input));
    note(key, { step: 'solving', frac: 0 });
    const out = await runSolve(input, key);
    note(key, { step: 'done', frac: 1, work: Object.assign({}, (progress.get(key) || {}).work, { evals: (out.search || {}).evals }) });
    res.set('X-Solve-Ms', String(Date.now() - t0)).json(out);
  } catch (e) {
    console.error('[solve]', e);
    res.status(500).json({ error: String(e.message || e) });
  }
});

app.get('/progress/:key', (req, res) => {
  const p = progress.get(req.params.key);
  p ? res.json(p) : res.status(404).json({ error: 'Not known' });
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

// One road matrix for every route's stops; routes already in their best order are left out of the answer.
app.post('/optimise', async (req, res) => {
  try {
    const { routes, school, params } = req.body;
    const lls = [[school.lat, school.lng]].concat((routes || []).flatMap(r => r.stops.map(s => s.ll)));
    const mx = await matrix(RE, lls);
    const out = (routes || []).map(r => {
      const base = Object.assign({}, r.base, { school: [school.lat, school.lng] });
      const best = bestOrder(RE, base, r.stops, { params, matrix: mx });
      return best && Object.assign({ id: r.id }, best);
    }).filter(Boolean);
    res.json({ routes: out });
  } catch (e) {
    console.error('[optimise]', e);
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
