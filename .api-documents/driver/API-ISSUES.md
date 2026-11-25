# API issues found while wiring the Driver app

Mismatches between the Driver app API on staging (https://convoy-api-staging.convoy.sg) and its docs
(convoy-v3-api/.api-documents/driver/). Each endpoint is called on staging before it is wired; the scrubbed answers are
kept as test fixtures in test/fixtures/. The backend answers in fe-updates.md.

Last re-checked 2026-11-25 against convoy-v3-api a904f35. **Open: 2 (#20, #21).** The next issue is #22.

## Open

New issues go here, newest on top, in the integration.md § 9 format:

    ## N. <Area> (dd/mm)
    ```
    Endpoint: METHOD /driver/...   (sample account)
    Got:      what staging answered
    Doc says: <doc>.md § x — what the doc says, and what the app does meanwhile
    ```

### 21. Push: two token registrations at once answer 500 (25/11)
```
Endpoint: PATCH /driver/device { device: { platform: "android", push_token } }   (Eric, same token, 3 calls at once)
Got:      204, 500, 500 (internal_server_error "Something went wrong"); the same calls one after another: 204, 204
Doc says: notifications.md § 5.1 — "a second call replaces it"; nothing about a 500
App:      sends one registration at a time (Push._register), since Android gives the token at start-up and through
          onTokenRefresh together. The server should make the upsert safe (unique push_token / driver_jwt_id).
```

### 20. Push: which Firebase project? (25/11)
```
Endpoint: PATCH /driver/device { device: { platform, push_token } }   (Eric: 204; DELETE 204; platform "web" 422)
Got:      the server sends Driver pushes from Firebase project convoy-transport-company-stg, but the Driver app (ids
          com.simplelabx.convoydriver / .staging) is registered in convoy-1131e, as the old Convoy Driver app was. A
          token from one project cannot be sent to from another.
Doc says: notifications.md § 5, fe-updates 23/11 #18 — convoy-transport-company-stg, "the same one as the old Convoy
          apps": not true for the Driver app.
App:      push is wired on convoy-1131e (lib/configs/firebase_options.dart, lib/services/push.dart). 25/11, Tony:
          iOS simulator and Android emulator register their token (PATCH /device 204); on iOS a tapped push opens
          the bell. Nothing arrives from staging until the server sends through convoy-1131e.
Needs:    the server to send Driver app pushes through convoy-1131e (its service account), for staging and prod.
```
Fixed on our side 25/11: the Android API key in convoy-1131e had no Android apps in its application restrictions
(Firebase Installations answered 403 ACCESS_DENIED, so no FCM token). Both packages with the debug and release SHA-1s
were added.

## Closed

All checked on staging. Numbers are kept so `API-ISSUES #N` references in old commits still match.

| # | Area | Outcome |
| --- | --- | --- |
| 1 | Session | `account.photo` documented |
| 2 | Session | Seed: `invited_at` = `joined_at` |
| 3 | Companies | Wrong-status messages name the company ("You already work with SimpleDrive") |
| 4 | Runs | `ended` with no times = not driven; the app shows "Ended" alone |
| 5 | Runs | Seed: sample runs from today |
| 6 | Trip Details | `points[].note` null on School Bus; `parent_phone2` documented |
| 7 | Trip Details | `driver_end`, `driver_feedback`, contact roles and notes documented |
| 8 | Session | `account.name` null until filled in; the app falls back to `name_on_record` |
| 9 | Trip Details | Point record fields and `left_early` documented |
| 10 | Driving | Count before Start answers `not_started` |
| 11 | Driving | Any action on a run never started answers `ended` (`disposal_start` included) |
| 12 | WebSocket | A bad ticket gets the `disconnect` frame |
| 13 | Notifications | `run.open` on bell lines; the app uses it and dims `open: false` lines |
| 14 | Vehicle History | Counts only runs the driver started |
| 15 | Sample data | Seed bug, fixed 23/11: Siti's SSS AM 1 (run 1841, 20/11) has `left_early: { missing: 1 }`, a skipped point and feedback; runs 603 force ended (Accident) and 605 skipped |
| 16 | Driving | Main contractor app built 23/11: `contractor { name, requires_app, choice, chosen_at }` on every run card, `POST /runs/:id/app_choice`, `complete` with `on_contractor_app`. Wired; the phone-only `extChoice` is gone. Checked: the card field, `not_started`, `not_required`; the success path (Eric's NYP Industry Visit, from 15:00 SGT) not driven yet |
| 17 | Profile | Update with Singpass: not planned. The button stays hidden; verified fields stay locked |
| 18 | Notifications | Push built 23/11 (`PUT` / `DELETE /driver/device`, a push per new bell line). Wired 25/11 on Firebase convoy-1131e; delivery waits on #20 |
| 19 | Environments | Staging only, no production API yet: the prod flavor and CI keep staging until a host is announced |
