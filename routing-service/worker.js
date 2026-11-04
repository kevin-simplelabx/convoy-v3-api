'use strict';
// One Convoy Pathfinder solve off the main thread; progress goes to the main thread at most every half second.
const { parentPort, workerData } = require('worker_threads');
const { load } = require('./lib/engine');

try {
  const RE = load(workerData.osrmBase);
  let last = 0;
  const onProgress = p => {
    const now = Date.now();
    if (now - last < 500 && p.frac < 1) return;
    last = now;
    parentPort.postMessage({ prog: p });
  };
  parentPort.postMessage({ ok: true, res: RE.solve(workerData.input, onProgress) });
} catch (e) {
  parentPort.postMessage({ ok: false, err: String((e && e.stack) || e) });
}
