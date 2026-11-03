# Convoy routing service

The Convoy Pathfinder school bus routing engine (`engine/convoy-pathfinder.js`, the prototype's
`convoy-pathfinder-cf.js` unchanged) as an internal HTTP service for the Rails API (`../`). Rails calls it from
background jobs (`Routing::Client`); browsers never call it.

| Call | Body | Answer |
| --- | --- | --- |
| `POST /solve` | `{ input: { school, groups, current, params } }` | engine result (`routes`, `assign`, `unassigned`, `summary`, `validation`, …) |
| `POST /retime` | `{ base, stops, school, params, vias, roadLegs }` | the route re-timed after a hand edit |
| `POST /diff` | `{ a, b }` | plan comparison |
| `GET /meta` | | engine defaults, bus types, priority presets, effort levels |
| `GET /health` | | `{ ok, running, queued, osrm }` (no secret) |

Every call except `/health` needs `X-Routing-Secret: $ROUTING_SECRET`. Road travel times come from OSRM (`OSRM_URL`,
default `https://router.project-osrm.org`, as the prototype; matrices cached in memory). The engine refuses to plan
without road times. Solves run in worker threads, `SOLVE_CONCURRENCY` at a time; effort is capped at `MAX_EFFORT`.

```
npm install
ROUTING_SECRET=dev npm start        # :4000
npm test
```

Deploy: `bin/routing-image` (build amd64 + push to GHCR), then `bin/kamal accessory boot routing` the first time or
`bin/kamal accessory reboot routing` after. Rails reaches it at `ROUTING_URL` (`http://convoy_v3-routing:4000`).
