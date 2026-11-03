# School Bus › Families, Registration, Bus Requests & CCA Rides — API Guide

This guide covers the parent side of School Bus in Convoy OS: Families & Riders, Bus Service Registration (Year Setup),
Bus Service Requests (New Service, Change of Address, Change of Service, Stop Service), the bell / strip / 08:00 email,
and CCA Rides. Conventions are in [README.md](README.md). Paths start with `/api/v1`.

**Permissions**

| What | Who |
| --- | --- |
| Read families, requests, alerts | `plans`, `schools` or `finance` (only the schools the user may open) |
| Change families; review requests (open, acknowledge, accept, decide, confirm, end rider) | `plans` or `schools` |
| Read registration and CCA Rides | Every company user who may open the school |
| Change registration and CCA Rides settings, Bus Not Running | `plans` or `schools` |

A Convoy Admin can read but change nothing.

**What the Convoy App does (not here yet).** Parents send requests, withdraw them, pay first invoices, agree to a higher
fare, and book and pay for CCA rides in the Convoy App. Those endpoints come with the app. Until then, seeds hold sample
data, and Convoy OS can add an application on a parent's behalf.

## Contents

1. [Families & Riders](#1-families--riders)
2. [Bus Service Registration](#2-bus-service-registration)
3. [Bus Service Requests: list and detail](#3-bus-service-requests-list-and-detail)
4. [New Service: review, accept, first invoice](#4-new-service-review-accept-first-invoice)
5. [Change of Address, Change of Service, Stop Service](#5-change-of-address-change-of-service-stop-service)
6. [Alerts and the 08:00 email](#6-alerts-and-the-0800-email)
7. [CCA Rides](#7-cca-rides)
8. [Front-end only and not built yet](#8-front-end-only-and-not-built-yet)

---

## 1. Families & Riders

| Call | What it does |
| --- | --- |
| `GET /schools/:school_id/families?q=&page=` | The list, with search and the count of riders not in a family (`meta.unlinked_riders`) |
| `POST /schools/:school_id/families` | Add a family: `{ family: { code, name, name_mode }, guardian: { first_name, last_name, relationship, phone, email } }` |
| `GET /families/:id` | One family, with its guardians and its riders (sessions, dates, the routes they ride) |
| `PATCH /families/:id` | Change the family: `{ family: { code, name, name_mode } }` |
| `DELETE /families/:id` | Delete the family |
| `POST /families/:id/guardians` | Add a guardian: `{ guardian: {…} }` |
| `PATCH /families/:id/guardians/:guardian_id` | Change a guardian |
| `DELETE /families/:id/guardians/:guardian_id` | Remove a guardian |
| `POST /families/:id/riders` | Link riders: `{ school_id, rids: [] }` (a rider leaves any other family at the school) |
| `DELETE /families/:id/riders/:rid?school_id=` | Unlink a rider |
| `GET /families/:id/candidates?school_id=&q=` | Link Existing Rider: parent matches first, then the same last name (`match: parent \| last_name`) |
| `POST /schools/:school_id/families/import` | CSV import (`file`, or `text`), with warnings |
| `GET /schools/:school_id/families/export` | CSV export |

How families work:

- **Codes.** Codes run `FAM-0001`, `FAM-0002` and so on.
- **Automatic names.** With `name_mode: auto`, the name comes from a guardian's last name: Father first, then Mother, then
  the first guardian. For example, `TAN Family`.
- **Add Rider.** `POST /schools/:id/riders` accepts `family_id` to put the new rider in that family.

## 2. Bus Service Registration

There is one registration per school academic year.

| Call | What it does |
| --- | --- |
| `GET /academic_years/:id/registration` | The settings. Before a save, these are the defaults (`saved: false`) |
| `PUT /academic_years/:id/registration` | Save Draft, or Save Changes once scheduled |
| `POST /academic_years/:id/registration/schedule` | Save and schedule. Takes the same body |
| `POST /academic_years/:id/registration/unschedule` | Back to draft: messages stop and the form closes to parents |
| `POST /academic_years/:id/registration/release` | Release Now for a message sent by hand: `{ key: "wel" }` |

**Body fields (all optional).**

- **Dates.** `renew_from`, `renew_to` (renewals only), `general_from`, `general_to` (everyone), `service_starts_on`.
- **Timings.** `confirm_hours` (to pay after acceptance), `ack_days`, `plan_weeks` (mid-year reply times).
- **Who can apply.** `levels[]` (School Levels names; empty means all), `sessions[]` (`AM`, `PM`, `CCA`).
- **Graduating message.** `grad_on`, `grad_message`, `grad_link`.
- **Auto-accept rules.**
  - Renewals: `auto_renew`, with the checks `renew_check_address`, `renew_check_session`, `renew_check_debt`.
  - New families nearby: `auto_near`, `near_km`, `near_needs_cover`.
  - Siblings: `auto_siblings`, `siblings_need_cover`.
  - When to run: `run_mode` (`arrive` or `daily`), `run_at` (`"HH:MM"`).
  - Seats and waitlist: `seats_buffer`, `waitlist_auto`.
- **Fees.** `show_fare`, `extra_terms`.
- **Form questions.** `asks[]`, from `cls sidn dob med photo emerg cca`.
- **Messages.** `messages[]`: `{ key, enabled, email, whatsapp, app, offset_days, offset_hours, subject, body, whatsapp_body, scheduled }`.

**Defaults.** These count from the year's first school day S:

- Renewals: S−122 to S−79.
- Everyone: S−78 to S+242.
- Confirm hours: 48. Mid-year reply times: 3 and 3. Sessions: AM, PM, CCA.

**Errors (422).**

- The Convoy OS checks: `Enter every date in Schedule`, `The early window must end after it starts`,
  `The general window must open after the early window closes`, `Pick at least one session`, and so on.
- Schedule also needs Terms & Semesters, Bus Sessions and Bus Fares locked, and a Payment & Refund Policy in use.
  Otherwise it returns `code: "not_ready"`, `details.missing`, and the message `Finish Bus Fares, … before scheduling`.

**Response.** It includes:

- `status` (`draft` or `scheduled`) and `state`: `draft`, `upcoming`, `renewals_open`, `general_upcoming`, `open` or `closed`.
- `ready[]` and `final_levels`.
- `policy`: the version, the registration fee, the deposit and the agreement text.
- `messages[]`, with these fields per message:
  - `name`, `audience`.
  - `anchor`: one of `eF`, `eT`, `gF` or `start`.
  - `event`.
  - `adjustable`, `manual`.
  - `sends_on`: the date it goes at 09:00. It is null for messages that follow an event, or that wait for Release Now.

**Messages.** There are 12, in this order: `inv`, `grad`, `rem`, `last`, `open`, `recv`, `offer`, `crem`, `wl`, `lapse`,
`rej`, `wel`. Their texts start from `config/presets/registration_messages.yml`. Timing rules:

- Only `adjustable` timings can change.
- Days keep the preset's side: before or after its anchor.
- `wel` waits for Release Now unless `scheduled: true`.
- Messages are recorded only. Nothing is sent yet.

## 3. Bus Service Requests: list and detail

| Call | What it does |
| --- | --- |
| `GET /schools/:school_id/bus_requests` | The Requests page (filters below) |
| `GET /bus_requests/:id` | One request with its history |
| `POST /bus_requests/:id/open` | Opening it the first time: Requested → Under Review. A mid-year request waits for Acknowledge |

**Filters.**

- `kind`: `new` (default), `adr`, `svc` or `stop`.
- `academic_year_id`: New Service only. The default is the year after this one.
- `status`: a status, or `Accepted+` for Accepted and Active.
- `tag`, `level`, `session` (`AM` or `PM`).
- `deadline`: `over`, `soon` or `ok`.
- `check`: `covered`, `change`, `new` or `none`.
- `q`: child, parent, code, postal, email or address. Three or more digits also match the phone.
- `page`, `limit` (default 150, max 500).

**Order.**

- New Service: overdue mid-year first, then due soon, then other mid-year requests, then the rest. Renewals come first
  within each group, then the oldest.
- The other tabs: newest first.

**Statuses** use the app's words:

- `Requested`, `Under Review`, `Accepted`, `Active`, `Waitlisted`, `Declined`, `Withdrawn`, `Not Agreed`, `Stopping` and
  `Stopped` are stored.
- `Lapsed` is read, never stored: an accepted request not paid by `offer_by`.
- A `Stopping` request past its last day reads `Stopped`.
- `status_label` shows `Waiting for Parent` while a higher fare waits for the parent to agree.
- `tone` is one of `info`, `success`, `warning`, `danger` or `neutral`.

**Tags.**

- Stored on the request: `Renewing` and `Final Level`.
- Worked out on the server:
  - `New`: no current rider, or not a renewal.
  - `Mid-Year`: sent after the year's service started.
  - `Fixed Start`.
  - `From the App` or `Sample`.

**Row fields.**

- What the parent asked for: `code`, `kind`, `source` (`app`, `console` or `sample`), `child_name`, `level`, `am`, `pm`,
  `cca`, the parent fields, `submitted_at`, `start_text` (for example "From 16/11/2026, not earlier (moving house)").
- Where it stands: `status`, `status_label`, `tone`, `tags`, `reason`, `last_event`.
- `deadline` (mid-year only): `{ stage: ack | answer, by, left (working days), tone: ok | soon | over }`.
- `check`: Route Fit (section 4).
- The offer: `offer_by`, `hours_left`, `quote_amount`.
- Links: `rider` (`{ id, rid }`) and `family` (`{ id, code, name }`).
- Changes: `change` (section 5) and `end_action`.

**Meta.**

- The tiles (`label`, `count`, `filter`). Mid-Year and Overdue appear only when there are any.
- `tabs` (`open` counts), `windows` (early and general window state), `years` (cards: This Year, Next Year, Later or Past;
  `to_review`, `requests`, `registration`) and `levels`.
- `mid`: `ack_days`, `plan_weeks`, `service_starts_on`.
- `auto_accept` and `cover` (section 4).

**The detail** adds the following:

- The address and the form answers.
- `ack`: `{ at, by, answer_by, note, moves[] }`.
- `route_fit` per session, `quote`, `quote_default`, `places[]`, `first_bill` and `planned`.
- `events[]`, newest first.
- `can`: `{ acknowledge, move_answer, waitlist, decline, accept, reoffer, record_payment, confirm_change, confirm_stop, not_agreed, end_rider }`.

## 4. New Service: review, accept, first invoice

| Call | What it does |
| --- | --- |
| `POST /schools/:school_id/bus_requests` | Add Application on a parent's behalf |
| `POST /bus_requests/:id/acknowledge` | Mid-year: `{ answer_by, note }`. Under Review; the parent sees the date and the note |
| `POST /bus_requests/:id/move_answer` | `{ answer_by, reason }`. The reason is required; every move is kept |
| `POST /schools/:school_id/bus_requests/decide` | Waitlist or Decline one or many: `{ ids: [], to: Waitlisted \| Declined, reason, note }` |
| `POST /schools/:school_id/bus_requests/message` | `{ ids: [], text }`. Logged on each request (parent accounts are not live) |
| `POST /bus_requests/:id/accept` | Accept and Send Quote: `{ amount, start_on, note }` |
| `POST /schools/:school_id/bus_requests/accept` | Accept many at their Bus Fares quotes: `{ ids: [] }`. Also used by the auto-accept and "can now be covered" banners |
| `POST /bus_requests/:id/reoffer` | A lapsed offer again: the same quote and invoice number, new hours to pay |
| `POST /bus_requests/:id/record_payment` | Record First Invoice Paid: `{ method }`. The request becomes Active |

**Add Application.**

- Body: `{ academic_year_id, child_name, parent_name, parent_phone, parent_email, level, address, postal, am, pm, start_on, fee_paid }`.
- Errors: `Enter the child's name`, `Enter the parent's name`, `Enter a 6-digit postal code`, `Pick AM, PM or both`.
- The postal code is placed on the map with OneMap. `located: false` when OneMap does not know it.

**Reasons.**

- Waitlist: `Route full`, `New area`, `Awaiting bus`.
- Decline: `Outside service area`, `Not eligible`, `Duplicate application`, `Other`.
- An empty reason is allowed.

**Route Fit (`check`, `route_fit`).** Each session the request asks for is checked against the routes running on its
start date. That is the session's plan in use that day, or else the latest plan.

| Result | Meaning |
| --- | --- |
| `fits` (Fits) | A child already rides from the same block on a route with a free seat |
| `new` (New Stop) | A route with a free seat can add a stop at the child's block, inside the arrival window (AM) and the max journey. `delta` is minutes added; `impact[]` is what changes for the other children; `alts[]` are other routes |
| `full` (Bus Full) | Routes can reach the child, but none has a free seat |
| `area` (New Area) | No route can reach the child |
| `none` (Not Checked) | The session has no route plan yet |

How the check is worked out:

- **Free seats.** Seats, less the riders, less the seats held for accepted requests not yet in the plan, plus riders
  who have left by then.
- **Limits.** The arrival window and max journey come from the year's Bus Sessions. Without them, the plan's own settings apply.
- **Worst session wins.** The row shows the worst session. The order from best to worst is Fits, New Stop, Not Checked,
  Bus Full, New Area. The label gets "(part)" when a session is Not Checked.
- **Other labels.** A renewal whose child already rides shows `Covered` (current route). An accepted request shows `Seat held`.

**Quote (`quote_default`).** This is the Bus Fares tier for the distance from the school.

- **Which table.** The year's locked table, or else the latest locked table before it.
- **Which amount.** The amount of the bill the start date falls in. Both sessions are charged two ways; AM only or PM
  only is charged one way.
- **Unit.** `month`, `term` or `semester`.
- **No table.** Without a table, the quote is the estimate the parent saw.
- **Text.** `text` has the Route Fit summary and how the fare was found.

**Accept checks.**

- `Enter the monthly fare` and `Pick the start date`.
- A fixed start cannot be earlier than the family asked: "The family needs the bus from …".
- A note is required when the fare differs from Bus Fares or the start is later than asked:
  `Add a note for the parent: …`.

**On accept.**

- The request becomes Accepted, with `offer_by` = now + the registration's confirm hours (48 by default).
- The seat is held where Route Fit placed the child (`places[]`).
- **First invoice (`first_bill`).** A real School Bus bill:
  - Numbered from Finance Settings (`INV-2026-000123`).
  - GST as in Finance Settings.
  - Covers the start's billing period, and is due at `offer_by`.
- **A new child** joins the rider list from the start date as Unpaid, and joins a family. The family is the school's
  family with a guardian of the same phone (last 8 digits) or email. Otherwise a new family `<LAST NAME> Family` is
  created, with the parent as guardian.

**After the offer.**

- Not paid by `offer_by`: the request reads `Lapsed`. Use Re-offer, or End Rider (section 5).
- Paid: Active, and the child joins the route plans from the start date (section 5, plan versions).

**Banners.**

- `meta.auto_accept` (`{ count, ids }`) lists the requests the scheduled registration's rules would take. These are
  renewals unchanged, renewing riders at the same address and sessions, siblings, and families nearby, with a seat
  beyond `seats_buffer` when the rule asks for one.
- `meta.cover` lists waitlisted requests that can now be covered.
- Both are accepted with the bulk call.

## 5. Change of Address, Change of Service, Stop Service

| Call | What it does |
| --- | --- |
| `POST /bus_requests/:id/confirm_change` | Change of Address: `{ amount, stop, note }` (the new pick-up point is required). Change of Service: `{ amount, note }`. From Not Agreed, this is Change the Fare |
| `POST /bus_requests/:id/confirm_stop` | `{ last_on, note }`. Stopping. A last day before the notice ends stops the bus earlier, but fees run to `pay_to` (the earliest last day) |
| `POST /bus_requests/:id/not_agreed` | `{ choice: keep \| stop }`. Keep the old pick-up (Declined), or stop the service from the move date (Stopped) |
| `POST /bus_requests/:id/end_rider` | End Rider / Remove from Rider List, on the day in `end_action.end` |

**Fare changes.** When the fare goes up, the request is Accepted and waits for the parent to agree in the app. Otherwise
it is Active from its date.

**`change` on the row.**

- When: `effective_on`.
- Fares: `current_fare`, `agree`, `waiting_for_parent`.
- Address: `old_address`, `new_address`, `new_stop`.
- Service: `from_service`, `to_service` (for example "Two ways", "Morning only + CCA bus"), `adds`.
- Stop: `last_on`, `stop_reason`, `notice`, `earliest_on`, `early`, `pay_to`.
- Confirmation: `confirmed_at`, `confirm_note`, `ended_on`.

**Plan versions (`planned`).** A confirmed request goes into the route plans of its session from its date, once:

| Request | What changes |
| --- | --- |
| New child paid | joins |
| Address Active | moves |
| Address Stopped | leaves |
| Service | joins or drops each session that changed |
| Stop | leaves from the day after the last day |

How it works:

- **Split.** The plan in use that day is split. The old version ends the day before; a copy with the change runs from the date.
- **Later plans.** Every later adopted plan of the session gets the change too.
- **Name.** The new version is named `<plan> · from dd/mm/yyyy · N changes`.
- **Placing the child.** Joins and moves use Route Fit. The child goes to the same block's stop, or to a new stop with
  the times around it moved.
- **No fit.** When the child does not fit, nothing changes. The line says why.
- **Result.** `planned: { at, ok, lines[] }`. The Scheduler runs are re-synced.

**`end_action`.** It is `{ end, why, button, label, text }`, and set when the child should come off the rider list:

| `why` | When |
| --- | --- |
| `lapsed` | The offer lapsed |
| `withdrawn` | Withdrawn before paying |
| `stop` | The last day has passed |
| `adr` | The service stopped from the move date |
| `declined` | A renewal was declined and the new year has started |

Nothing leaves the list by itself.

**Daily job (12:30am).**

- Confirmed changes of service and address reach the rider record on their date.
- Renewed riders move to their new level when the new year starts.

## 6. Alerts and the 08:00 email

| Call | What it does |
| --- | --- |
| `GET /bus_requests/alerts` | The bell and the strip (Ops Control, School Live Ops): requests that need someone, across the user's schools, most urgent first |
| `GET /bus_requests/digest` | The 08:00 email as it would go today: `{ to: [names], subject, groups: [{ school, rows: [{ who, text, tone }] }] }` |

**Alert items.** Each item has:

- `request_id`, `code`, `child_name`, `level`, `school`.
- `tab`: the Requests tab to open.
- `kind`: `new`, `adr`, `svc`, `stop` or `end`.
- `what`: for example "New bus request", "Answer due", "Renewal", "Change of address", "Leaving" or "Offer lapsed".
- `text`: for example "Acknowledge was due Fri 23/10", or "Moves Mon 16/11. Not opened yet".
- `tone`: `over`, `soon` or `ok`.
- `rank`, `by` and `deadline`.

**Meta.**

- The counts: `count`, `overdue`, `to_acknowledge`, `answers_due`, `changes`, `to_end`.
- `parts[]`, and `text` (the strip subtitle).

**The email** goes to the owner, Admins, and users with the Schools permission who open those schools. It goes at 08:00
only on days with requests waiting. It is recorded in notification emails and not sent until email sending exists.

## 7. CCA Rides

| Call | What it does |
| --- | --- |
| `GET /schools/:school_id/cca_rides?week_of=YYYY-MM-DD` | Settings and one week. Any day picks its Monday; the default is the next week with rides |
| `PUT /schools/:school_id/cca_rides` | `{ enabled, price, days: [1..5], seats }` |
| `POST /schools/:school_id/cca_rides/not_running` | `{ date, reason: school \| weather \| bus \| other \| no_school, note }`. Every ride booked that day becomes credit for its family, once per day |

**Settings.**

- Errors when on: `Enter the price per ride`, `Pick the days the CCA bus runs`, `Enter the seats per day`.
- `fares_price` is set when this year's Bus Fares has the CCA / ASA bus per trip at a fixed price. That price is then
  used, and the front end locks the field.

**Each day of the week** has:

- `date`, `label`, `phase` (`past`, `today`, `late` or `open`) and `status`, for example "Open until Sat 7 Nov, 23:59",
  "Closed · late adds while seats last", "Bus Not Running" or "No School".
- Seats: `riders`, `taken`, `seats`, `full`.
- Calendar: `off` (`{ reason, by, at, credit }`), `no_school` (not a school day, with the holiday name) and `calendar`
  (a special day: check the bus time).
- Actions: `can_not_running`, and `can_no_school_credit` (give credit for rides booked before the calendar changed).
- `rows[]`: child, class, family, `paid_on`, `method`, `bill_id`, `late`, `not_riding`.

**Week figures (`kpis`).** `rides`, `collected`, `late`, `not_riding`, `credit_given`.

**Booking rules (Convoy App).**

- Parents book next week by Saturday 23:59 and pay to confirm. After that, a ride can be added only while seats are left.
- Paid rides cannot be removed. Not Riding frees the seat; the ride is still charged.
- Credit is used first at the family's next payment.
- Each payment is a School Bus bill (`kind: cca`), with lines per child and a credit line.

## 8. Front-end only and not built yet

- **Front end only.** These are screen state: map pins, the dialogs, and the words around deadlines. The server gives
  `deadline` and `text`.
- **Convoy App endpoints, not built yet.**
  - Sending, withdrawing and renewing requests.
  - Paying first invoices.
  - Agreeing to a higher fare.
  - CCA booking, Not Riding, and Same Days Every Week.
  - Auto-accept as requests arrive.
- **Sending.** Parent messages and the 08:00 email are recorded, not sent.
- **Family fees.** These come with School Finance.
