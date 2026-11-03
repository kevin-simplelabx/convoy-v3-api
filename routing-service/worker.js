'use strict';
// One Convoy Pathfinder solve off the main thread.
const { parentPort, workerData } = require('worker_threads');
const { load } = require('./lib/engine');

try {
  const RE = load(workerData.osrmBase);
  parentPort.postMessage({ ok: true, res: RE.solve(workerData.input) });
} catch (e) {
  parentPort.postMessage({ ok: false, err: String((e && e.stack) || e) });
}
