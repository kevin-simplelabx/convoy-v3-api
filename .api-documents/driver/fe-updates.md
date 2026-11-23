# Convoy Driver app — notes for the front-end

Things the app does by itself (no server field or call) and changes the app has to act on. Newest first.

## 23/11/2026 — #15 fixed (seed only, no API change)

| # | Breaking | Change / answer | Doc |
| --- | --- | --- | --- |
| 15 | no | Fixed in the seed. Siti's ended runs are no longer tied to "yesterday" (a weekend or the school holidays has no school run): the School Bus record is on the **last school day before the seed**, the shuttle records on the **last day before the seed with her shuttles**. In the current holidays both are **Fri 20/11/2026**: St. Stephen's AM 1 → first point `record.left_early: { missing: 1 }`, second point skipped ("Passengers are late"), completed with feedback; MBC Campus Shuttle 07:45 force ended (Accident); 08:15 skipped (Traffic Congestion). Other sample data can no longer overwrite them. Live on staging after the next re-seed (announced here); then please re-check and close #15. | [README § Sample accounts](README.md#sample-accounts-staging-and-local-seed) |

## 23/11/2026 — Answers to API-ISSUES #15–#19

API-ISSUES.md re-checked 23/11 at 5bc9041. No API change in this entry.

| # | Breaking | Change / answer | Doc |
| --- | --- | --- | --- |
| 15 | no | **Re-opened: a seed bug, not test data.** Our 20/11 answer was wrong: Siti's SSS AM 1 is driven by the seed but nobody is left behind, so no point has `left_early`. Cause: the live simulator had already ticked every child on that run before the seed drove it, so no child was left to leave behind. Fix planned (seed only): clear the simulator's ticks on that run before driving it. We announce it here when staging is re-seeded; please keep #15 open until then. | [README § Sample accounts](README.md#sample-accounts-staging-and-local-seed) |
| 16 | — | Main contractor handover: planned, not built yet. Keep the phone-only choice (`extChoice`) meanwhile; the endpoint and its field on the run will be announced here. | [runs § 4](runs.md#4-trip-details-get-driverrunsid) |
| 17 | — | Update with Singpass: **not planned for now**. Keep the button hidden; fields already verified stay locked. You can move #17 to Closed ("not planned"). | [profile § 1](profile.md#1-the-profile-get-driverprofile) |
| 18 | — | Push notifications: planned, not built yet. WebSocket while open + reload on start / resume stays the contract until the device-token endpoint and push payloads are announced here. | [notifications.md](notifications.md), [../websocket.md](../websocket.md) |
| 19 | — | **Staging only; there is no production API yet.** Keep the prod flavor / `PRODUCTION_BASE_API_URL` on staging; the prod host will be announced here. You can move #19 to Closed. | [../integration.md § 2](../integration.md#2-environments-and-test-accounts) |
