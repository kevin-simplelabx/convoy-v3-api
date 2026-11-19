# API issues found while wiring the Driver app

Format from integration.md § 9. The Driver app docs are in convoy-v3-api/.api-documents/driver/. Each endpoint is
called on staging (https://convoy-api-staging.convoy.sg) before it is wired; the scrubbed answers are kept as test
fixtures in test/fixtures/. Fixed issues are removed (numbers are kept so earlier references still match).

Last re-checked 2026-11-19 against convoy-v3-api 4b79fc4. Open: 11.

Fixed in e815362 (fe-updates.md 19/11): #7 (driver_end, driver_feedback, contact roles and note documented) and
#9 (point record fields documented, left_early { missing, until }).

---

## 13. Notifications: older lines of a run taken away (19/11)
```
Endpoint: GET /driver/notifications, then GET /driver/runs/2614   (Ah Beng)
Got:      lines 42 run_assigned, 44 run_cancelled, 45 run_changed and 46 run_removed all carry "run": { "id": 2614 };
          GET /driver/runs/2614 answers 404 not_found (the run is no longer his).
Doc says: notifications.md § 1 — run_assigned / run_changed / run_cancelled open Trip Details, run_unassigned /
          run_removed open nothing. Not said what the earlier lines of a run later unassigned or removed do. The app
          skips them when the run's newest line is run_unassigned / run_removed and treats a 404 on Trip Details as
          "no longer assigned to you". Suggest: drop "run" (or add "available": false) on lines of runs that are no
          longer the driver's.
```

## 12. WebSocket: bad ticket (19/11)
```
Endpoint: wss://convoy-api-staging.convoy.sg/cable?ticket=bogus   (subprotocol actioncable-v1-json)
Got:      the socket closes (code 1000) with no frame at all
Doc says: websocket.md § 1 — "the server sends {"type":"disconnect","reason":"unauthorized","reconnect":false} and
          closes". The app treats a close before `welcome` the same way (new ticket; 401 on the ticket call → Sign In).
          Signing in on another phone does send {"type":"disconnect","reason":"remote","reconnect":false} as documented.
```

## 11. Driving: Start on an ended run (19/11)
```
Endpoint: POST /driver/runs/37/start { client_id }   (Kumar; run 37 already "status": "ended", never started)
Got:      200, started_at set, status still "ended"; GET /driver/runs/on_going then answered run 37 (floating bar on an
          Ended trip). Cleared afterwards with POST /driver/runs/37/complete.
Doc says: driving.md § 1 — after the end actions answer 422 code "ended". Linked to #4: runs that were never driven are
          "ended" without times, and Start does not refuse them.
```
19/11 re-checked (e815362): same. POST /driver/runs/6/disposal_start on Eric's ended disposal (never started) answers
`not_started` "Swipe to start the trip first", not `ended`.

## 10. Driving: Count before Start (19/11)
```
Endpoint: POST /driver/runs/598/count { client_id, position: 0 }   (Tony Tan, run not started, 6 hours before it)
Got:      200, points[0].record = { boarded: 0, alighted: 0, arrived_at: null, ... } while status stays "scheduled"
Doc says: driving.md § 12 — not_started for arrive, leave, skip a point, complete, force end; count is not listed, but a
          count before Start (and before arriving) records a point the bus has not reached. Expected 422 not_started.
```

## 8. Session (19/11)
```
Endpoint: GET /driver/session   (Ah Beng, Lee Kok Wah, Kumar)
Got:      "account": { ..., "name": null }, memberships[0].name_on_record "Ah Beng"
Doc says: auth.md § 3 — account.name is shown as always set. The app falls back to the current membership's
          name_on_record, then to phone_display. Please say in the doc that name is null until the driver fills it in.
```

## 6. Trip Details (19/11)
```
Endpoint: GET /driver/runs/:id   (every run probed)
Got:      fields not in the doc: "driver_end" ({ kind, at, reason, on_board } on run 6, else null), "driver_feedback"
          ({ note, at }), contacts[].note, contacts[].role "attendant" / "school_office", passengers[].parent_phone2.
          School Bus points (run 1833) have no "note" key (other kinds have it).
Doc says: runs.md § 4 / § 6 — contact.role is requestor | guest | main_contractor; points have "note". The app reads the
          extra fields as optional and treats a missing point note as null. Please document them (driver_end looks like
          the Force End record of driving.md).
```

## 5. Runs: sample data (19/11)
```
Endpoint: GET /driver/runs?from=2026-11-01&to=2026-11-30, GET /driver/runs/schedule
Got:      Eric Pang: last run 2026-11-11, nothing from today; the bus swap was 2026-11-12 12:00 (vehicle.current.since).
          Ah Beng: last School Bus run 2026-11-11, nothing from today. Kumar: no run with status "replaced" in November.
          Lee Kok Wah: runs up to 2026-11-20 only. Tony Tan: shuttles every weekday (fine).
Doc says: README.md § Sample accounts — Eric: "a bus swap tomorrow at 12:00", Ah Beng: School Bus, Kumar: "a trip taken
          by a replacement (Replaced)"; runs.md — runs exist up to 120 days ahead. The staging seed needs refreshing
          so Drive and the driving actions can be tried on those accounts.
```
19/11 re-checked (4b79fc4): fe-updates.md says Siti Nurhaliza (+65 9003 4455) has today's St. Stephen's AM 1 with Ethan Tan's photo;
her November runs are shuttles only. Ethan Tan's photo is on Ah Beng's run 1833 (10/11) instead.
19/11 re-checked (e815362): still no disposal run from today for Eric (GET /driver/runs?from=2026-11-19&to=2026-12-19),
so disposal_start / run / extend / end can't be tried end to end on staging (only their error answers, as multipart).

## 4. Runs (19/11)
```
Endpoint: GET /driver/runs, GET /driver/runs/:id   (Kumar run 37, Tony runs 592-596, Ah Beng run 1833, Eric run 6)
Got:      "status": "ended", "started_at": null, "ended_at": null   (runs earlier today and on past days nobody drove)
Doc says: runs.md § 6 — ended = the trip was driven. A run that was never started shows Ended with no times; the app
          shows Ended as sent. Is a not-driven run meant to be ended automatically, or should it stay scheduled/missed?
```

## 3. Companies (19/11)
```
Endpoint: POST /driver/companies/driver-1/accept   (Eric Pang, membership already active)
Got:      422 { "error": { "code": "invalid", "message": "Eric Pang is active, so this can't be done" } }
Doc says: auth.md § 5 — "<name> is <status>, so this can't be done". The name is the driver's, so the sentence reads as
          if the driver were active; the company's name ("SimpleDrive is active, …") would make sense to the driver.
```

## 2. Session (19/11)
```
Endpoint: GET /driver/session, POST /driver/session   (Eric Pang)
Got:      memberships[0] (SimpleDrive, active): "invited_at": "2026-11-02T11:03:30+08:00", "joined_at": "2026-05-11T12:41:03+08:00"
Doc says: auth.md § 3 example has invited_at = joined_at. Invited six months after joining: seed data, or invited_at
          overwritten by a later invite? The app does not show invited_at for active rows, so nothing is blocked.
```

## 1. Session (19/11)
```
Endpoint: POST /driver/session, GET /driver/session
Got:      account.photo { url, thumb_url, name, size, content_type }
Doc says: auth.md § 3 — account is { id, phone, phone_display, name, email, password_set }; photo is not listed.
          The app uses it (avatar before GET /driver/profile answers); please add it to the doc.
```
