# API issues found while wiring the Driver app

Mismatches between the Driver app API on staging (https://convoy-api-staging.convoy.sg) and its docs
(convoy-v3-api/.api-documents/driver/). Each endpoint is called on staging before it is wired; the scrubbed answers are
kept as test fixtures in test/fixtures/. The backend answers in fe-updates.md.

Last re-checked 2026-11-23 against convoy-v3-api 5bc9041. **Open: 0. Waiting on the backend: 4 (#16–#19).** The next
issue is #20.

## Open

None.

New issues go here, newest on top, in the integration.md § 9 format:

    ## N. <Area> (dd/mm)
    ```
    Endpoint: METHOD /driver/...   (sample account)
    Got:      what staging answered
    Doc says: <doc>.md § x — what the doc says, and what the app does meanwhile
    ```

## Waiting on the backend

Not mismatches: the docs say these are not built on the server yet. The app works around them as below; wire them when
fe-updates.md announces them, then move them to Closed.

### 19. Prod host (23/11)
```
Endpoint: none, the production API host is not given yet
Doc says: README.md gives only staging (https://convoy-api-staging.convoy.sg)
App:      the prod flavor's .env and the CI workflow's prod default (.github/workflows/android-build.yml,
          PRODUCTION_BASE_API_URL) both point at staging. Set the repo variable PRODUCTION_BASE_API_URL once known.
```

### 18. Push notifications (23/11)
```
Endpoint: none (no device-token registration, no push)
Doc says: README.md, notifications.md — push notifications are not sent yet
App:      no Firebase / push setup. Updates come over the WebSocket (/cable) while the app is open, and from polling
          on start and resume. A closed app gets no alert for a new or changed run, or a notice.
Needs:    a device-token endpoint (register / remove on sign out) and the push payloads per notification kind.
```

### 17. Update with Singpass (23/11)
```
Endpoint: none (no Myinfo link)
Doc says: profile.md § 1, screen-map.md — Update with Singpass is not available yet
App:      the button is hidden (settings_sections.dart, singpassAction: null); fields already verified with Singpass
          show locked.
Needs:    the Myinfo authorise URL / callback flow and the endpoint that saves the verified fields.
```

### 16. Main contractor handover (23/11)
```
Endpoint: none; GET /driver/runs/:id gives contractor.requires_app only
Doc says: runs.md § 4, screen-map.md — the handover flow is not built on the server (and the trip form has no app name)
App:      "Continue on X's app" / keep driving here is kept on the phone only (TripsNotifier.extChoice): the office
          never sees it, and it is lost when the app restarts.
Needs:    an action to record the choice (e.g. POST /driver/runs/:id/handover {to: "contractor" | "stay"}) and it in
          the run's answer.
```

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
| 15 | Sample data | Siti's records re-seeded; a School Bus child not boarded (`left_early`) is still missing — test data only, closed without a fix |
