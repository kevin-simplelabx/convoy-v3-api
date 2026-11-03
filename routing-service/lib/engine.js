'use strict';
// Loads the Convoy Pathfinder engine (engine/convoy-pathfinder.js, the prototype's convoy-pathfinder-cf.js unchanged) in
// this thread. The engine registers itself on window and reads window.CONVOY_CONFIG.osrmBase for road travel times.
const path = require('path');

function load(osrmBase) {
  globalThis.window = globalThis;
  globalThis.CONVOY_CONFIG = Object.assign({}, globalThis.CONVOY_CONFIG, { osrmBase });
  if (!globalThis.RoutingEngine) require(path.join(__dirname, '..', 'engine', 'convoy-pathfinder.js'));
  return globalThis.RoutingEngine;
}

module.exports = { load };
