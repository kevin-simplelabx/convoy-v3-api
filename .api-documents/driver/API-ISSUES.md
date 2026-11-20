# API issues found while wiring the Driver app

Format from integration.md § 9. The Driver app docs are in convoy-v3-api/.api-documents/driver/. Each endpoint is
called on staging (https://convoy-api-staging.convoy.sg) before it is wired; the scrubbed answers are kept as test
fixtures in test/fixtures/. Fixed issues are removed (numbers are kept so earlier references still match).

Last re-checked 2026-11-20 against convoy-v3-api 57b794b. Open: 2.

Answered in fe-updates.md 19/11 (bd3f3d6, 57b794b) and checked on staging 20/11, so removed: #1 (account.photo
documented), #2 (invited_at = joined_at), #3 ("You already work with SimpleDrive"), #4 (ended without times = not
driven; the app shows "Ended" alone), #5 (sample runs from today), #6 (point note null on School Bus, parent_phone2
documented), #8 (account.name null until filled in; the app shows name_on_record), #10 (count before Start: 422
not_started), #11 (actions on a run never started: 422 ended, disposal_start included), #12 (bogus ticket gets the
disconnect frame), #13 (run.open on bell lines; the app uses it and dims open: false lines). Earlier: #7, #9.

---

## 15. Runs: Siti's sample records missing (20/11)
```
Endpoint: GET /driver/runs?from=2026-11-01&to=2026-11-20   (Siti Nurhaliza)
Got:      75 runs, all plain MBC Campus Shuttles "ended" without driver_end, plus today's SSS AM 1 (ended) and run 601
          (replaced). No School Bus run left early, no skipped point or feedback, no force-ended (Accident) or skipped
          shuttle on 18/11 or 19/11.
Doc says: README.md § Sample accounts and fe-updates.md 19/11 — Siti has yesterday's ended runs: a School Bus run left
          early with a child not boarded, a skipped point and feedback; a shuttle force ended (Accident); a shuttle
          skipped before the start ("made for the day the seed runs"). Without them the Plan / Trip Details records
          (fe-updates items 1–5) can't be checked on staging.
```
(An earlier #15, "runs ended before their end time", was withdrawn: it was read in UTC+7 instead of Singapore time.)

## 14. Vehicle History: scheduled runs counted as driven (20/11)
```
Endpoint: GET /driver/vehicle/history?month=2026-11   (Tony, on 20/11 at 08:23)
Got:      "days" lists every weekday up to 30/11 (5 runs each, PC7475L), and 20/11 counts 5 runs (PC7475L 4,
          PD5126A 1) while only 3 had been driven; the 17:30 and 18:15 runs are still scheduled.
Doc says: vehicle.md § 4 — "the buses driven each day (from the trips driven)". The app hides days after today
          (shown as "Buses you drove this month"); today's counts still include runs not driven yet.
          Suggest: count only runs that were started (or ended with a started_at).
```
20/11 re-checked (57b794b): same (not answered in fe-updates.md yet).
