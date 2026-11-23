# Convoy Driver app — notes for the front-end

Things the app does by itself (no server field or call) and changes the app has to act on. Newest first.

## 23/11/2026 — #18 Push notifications (new endpoints, no breaking change)

**State: built on the server, not on staging yet.** This entry will say "Live on staging" once it is deployed. The
WebSocket and the reload on start / resume stay as they are; push is added on top for a closed or background app.

**Set up.** Firebase project `convoy-transport-company-stg` (the same one as the old Convoy apps). Register the Driver
app there (`google-services.json` / `GoogleService-Info.plist`). On iOS turn on Push Notifications and Background Modes →
Remote notifications. iOS needs no APNs setup from you: the server sends through Firebase only.

1. **After sign-in, and on every new token from Firebase**: `PUT /driver/device { device: { platform: "ios" | "android",
   push_token } }` → `204`. No company needs to be picked.
2. **Sign Out** removes the token by itself. `DELETE /driver/device` is for "notifications off on this phone".
3. **Every new bell line** (all 7 kinds, from **every** company the driver works for) arrives as a push: `title` / `body`
   as in the bell, `data` = `type: "driver_notification"`, `id`, `kind`, `company_id`, `membership`, and `run_id` /
   `run_date`, `notice_id` or `vehicle_id` (all strings).
4. **Tap**: Switch Company to `membership` if it is not the current one, fetch the bell, open line `id` as a tap there.

No badge count, and no sound per kind (not in the HTML): the default sound.

| # | Breaking | Change | Doc |
| --- | --- | --- | --- |
| 18 | no | `PUT` / `DELETE /driver/device`; push for each new bell line; Sign Out removes the token. | [notifications § 5](notifications.md#5-push-notifications) |

## 23/11/2026 — #16 Main contractor app (new endpoint and fields, no breaking change)

**State: built on the server, not on staging yet.** This entry will say "Live on staging" once it is deployed and
re-seeded. Until then keep the phone-only `extChoice`. After that, drop it and follow the flow below.

**How to use it.** It applies to runs where `contractor.requires_app` is `true`. `contractor` is on every run card.

1. **Start.** The driver swipes to start as usual (`POST /driver/runs/:id/start`). If `contractor.requires_app` is true
   and `contractor.choice` is null, show the "Continue on {`contractor.name`}" sheet.
2. **Stay on Convoy Driver App.** The driver ticks "I confirm to stay on Convoy Driver App", then Continue →
   `POST /driver/runs/:id/app_choice { client_id, at, choice: "stay" }`. They then drive as usual (arrive / leave / …)
   and end with the normal Complete Trip or Force End Trip.
3. **Continue on {name}.** The app sends `POST /driver/runs/:id/app_choice { client_id, at, choice: "contractor" }`
   right away. The driver works in the contractor's app; send no stops, counts or GPS for this run.
4. **Back in our app.** The driver ticks "I have completed my trip on {name}", then Continue →
   `POST /driver/runs/:id/complete { client_id, at, on_contractor_app: true }` (`feedback` optional). The run ends as
   completed. Career Metrics count it as usual.
5. **After a restart**, read `contractor.choice` from the run (`on_going` or Trip Details):
   - `contractor`: reopen the step 4 dialog.
   - `stay`: normal driving.
   - `null`: ask again (step 1).

Every call is queued and replayed by `client_id` like other driving actions. The answer is Trip Details with the
updated `contractor`.

| # | Breaking | Change | Doc |
| --- | --- | --- | --- |
| 16 | no | `contractor` is now on every run card (`GET /driver/runs`, `on_going`, Trip Details, driving answers), not only Trip Details: `{ name, requires_app, choice, chosen_at }` or null (not a sub-contracted trip). `name` = the main contractor = the app's name ("Continue on Eastern Coaches"); there is no separate app-name field. `choice`: null / `stay` / `contractor`. | [runs § 1](runs.md#1-drive-the-days-runs-get-driverruns) |
| 16 | no | New `POST /driver/runs/:id/app_choice`. The driver can change the choice (stay ↔ contractor) until the run ends. Errors: `not_required` (the run does not require the contractor's app), `not_started` (before Start), `ended`, `invalid` (`details.choice`). | [driving § 12](driving.md#12-main-contractor-app-post-driverrunsidapp_choice) |
| 16 | no | `complete` takes `on_contractor_app: true`. Before `choice: "contractor"`: `422 choose_contractor_first`. The answer: `status: "ended"`, `driver_end: { kind: "completed", on_board: null }`, every `points[].record` null, `driver_feedback.note` "Completed on {name}. Stops and counts recorded there." unless you send `feedback`. | [driving § 9, § 12](driving.md#12-main-contractor-app-post-driverrunsidapp_choice) |
| 16 | no | `driving.md` § 12 "Errors and reasons" is now § 13 (new codes `not_required`, `choose_contractor_first`). | [driving § 13](driving.md#13-errors-and-reasons) |

**To test** (once live): sign in as **Eric Pang** (`+65 9210 4100`, OTP `123456`). The run "NYP Industry Visit"
(Nanyang Polytechnic via Eastern Coaches) is every weekday 16:00–16:45 and can be started from 15:00. On the day after a
re-seed (the bus swap day) Frankie Ho (`+65 9247 4471`) has it instead. The office sees the choice in Ops Control (GPS
column "On Eastern Coaches' app", no alerts) and Trip History ("Completed on Eastern Coaches' app").

## 23/11/2026 — #15 fixed (seed only, no API change)

**Live on staging** (deployed `8c425ed`, re-seeded twice 23/11, checked with `GET /driver/runs/:id` as Siti).

| # | Breaking | Change / answer | Doc |
| --- | --- | --- | --- |
| 15 | no | Fixed in the seed. Siti's ended runs are no longer tied to "yesterday" (a weekend or the school holidays has no school run): the School Bus record is on the **last school day before the seed**, the shuttle records on the **last day before the seed with her shuttles**. In the current holidays both are **Fri 20/11/2026**: SSS AM 1 (run 1841) → first point `record.left_early: { missing: 1 }`, second point skipped ("Passengers are late"), completed with feedback; the first two of her MBC Campus Shuttles that day (on staging 08:15 = run 603 force ended (Accident), 08:45 = run 605 skipped (Traffic Congestion); 07:45 is a Replaced run). Other sample data can no longer overwrite them, and a run of hers left started on those days (a test that never ended) is cleared by the seed. Please re-check and close #15. | [README § Sample accounts](README.md#sample-accounts-staging-and-local-seed) |

## 23/11/2026 — Answers to API-ISSUES #15–#19

API-ISSUES.md re-checked 23/11 at 5bc9041. No API change in this entry.

| # | Breaking | Change / answer | Doc |
| --- | --- | --- | --- |
| 15 | no | **Re-opened: a seed bug, not test data.** Our 20/11 answer was wrong: Siti's SSS AM 1 is driven by the seed but nobody is left behind, so no point has `left_early`. Cause: the live simulator had already ticked every child on that run before the seed drove it, so no child was left to leave behind. **Fixed and live: see "#15 fixed" above.** | [README § Sample accounts](README.md#sample-accounts-staging-and-local-seed) |
| 16 | — | Main contractor handover: planned, not built yet. Keep the phone-only choice (`extChoice`) meanwhile; the endpoint and its field on the run will be announced here. **Built: see "#16 Main contractor app" above.** | [runs § 4](runs.md#4-trip-details-get-driverrunsid) |
| 17 | — | Update with Singpass: **not planned for now**. Keep the button hidden; fields already verified stay locked. You can move #17 to Closed ("not planned"). | [profile § 1](profile.md#1-the-profile-get-driverprofile) |
| 18 | — | Push notifications: planned, not built yet. WebSocket while open + reload on start / resume stays the contract until the device-token endpoint and push payloads are announced here. **To prepare now:** pushes go through Firebase Cloud Messaging for Android and iOS, Firebase project `convoy-transport-company-stg` (the same one as the old Convoy apps; iOS needs no APNs setup from you or us, the Apple key is already in that project). Register the Driver app there (`google-services.json` / `GoogleService-Info.plist`), turn on Push Notifications + Background Modes → Remote notifications on iOS, and get the FCM token. **Built: see "#18 Push notifications" above.** | [notifications.md](notifications.md), [../websocket.md](../websocket.md) |
| 19 | — | **Staging only; there is no production API yet.** Keep the prod flavor / `PRODUCTION_BASE_API_URL` on staging; the prod host will be announced here. You can move #19 to Closed. | [../integration.md § 2](../integration.md#2-environments-and-test-accounts) |
