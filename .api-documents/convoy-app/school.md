# Convoy App — School Bus (parents)

Home › **School Bus** and every screen it opens: the School Bus page, Bus Information, **Request School Bus** (3 steps),
**Application Status**, Renew / Change Service / Stop Bus Service, **Change of Address** (3 steps).
Conventions: [README.md](README.md); the Family and children: [household.md](household.md). Paths start with `/api/v1/app`.
Every call needs the Bearer token, a finished Create Your Account and a Family (`404 { code: "no_household" }` without one:
show "Set Up Your Family").

> Phase 4b (Bus Not Required, School Calendar, Contact + Report an Issue, Stop Photos) is added to this document when built.
> Fees, paying a bill (registration fee, first invoice) and the CCA Bus are in [fees.md](fees.md): the bill ids below open its Invoice.

## Contents

1. [How it works](#1-how-it-works)
2. [School Bus page: `GET /app/school`](#2-school-bus-page-get-appschool)
3. [Bus Information: `GET /app/school/riders/:dependant_id/bus`](#3-bus-information)
4. [Request School Bus](#4-request-school-bus)
5. [Application Status, Withdraw, Agree](#5-application-status-withdraw-agree)
6. [Renew / Change Service / Stop Bus Service](#6-renew--change-service--stop-bus-service)
7. [Change of Address](#7-change-of-address)
8. [The request object](#8-the-request-object)
9. [Values reference](#9-values-reference)

---

## 1. How it works

- The Family and its children belong to the people (platform). A **request** goes to the transport company that runs
  the child's school; the company answers in Convoy OS. When the company **accepts**, the Family becomes the school's
  family there (every adult a guardian) and the child joins the rider list. Nothing is matched by phone number.
- **Any adult** of the Family can look at everything here and send requests. **Money is the Billing Contact's**: bills
  (registration fee, first invoice), their amounts and the Pay buttons only come back for them (`you.billing_contact`).
  Fare estimates and quotes are shown to every adult (they are part of the request).
- One school can be served by several companies (`providers`); each request names the school **of one company**
  (`school_id` from the providers list), and `company { name, mark }` is shown on the cards ("SD").
- Dates are the company's (Singapore). Amounts are strings with 2 decimals.

## 2. School Bus page: `GET /app/school`

```json
{ "data": {
  "family": { "name": "Tan Family", "address": "Blk 412 Bedok North Ave 2, #08-123", "postal": "460412" },
  "you": { "admin": true, "billing_contact": true },
  "riders": [ {
    "dependant_id": 1, "name": "Ethan Tan", "first_name": "Ethan", "level": "P4", "rid": "M-0002",
    "school": { "id": 1, "name": "St. Stephen's School" }, "company": { "id": 1, "name": "SimpleDrive", "mark": "SD" },
    "next_bus_date": "2026-11-16", "today": true, "can_track": true,
    "legs": [
      { "session": "am", "label": "Pick-up", "main": "Pick-up · 06:55", "time": "06:55", "status": "Ended", "tone": "neutral",
        "route": "SSS AM 1", "stop": "Blk 32 Siglap", "school_time": "07:30" },
      { "session": "pm", "label": "Drop-off", "main": "Not on a route yet", "time": null, "status": "Not on a route", "tone": "neutral" } ] } ],
  "children": [ {
    "dependant_id": 2, "name": "Lucas Tan", "first_name": "Lucas", "meta": "Primary 1 · St. Stephen's School",
    "school": { "id": 1, "name": "St. Stephen's School" },
    "badge": { "label": "Fee Unpaid", "tone": "warning" },
    "line": "Requested 16 Nov 2026 for AY2027, est. S$420.00 a month. SimpleDrive replies within 1 to 2 weeks",
    "request_id": 24, "company": { "id": 1, "name": "SimpleDrive", "mark": "SD" },
    "action": { "kind": "pay_registration", "label": "Pay Registration Fee", "bill_id": 22, "request_id": 24 } } ],
  "address_change": {
    "from": "2027-01-04", "address": "Blk 216 Bedok North St 1, #05-22, S460216", "names": [ "Ethan Tan" ], "status": "Accepted",
    "line": "SimpleDrive confirmed the change. The fare goes from S$420.00 to S$460.00 a month (The new stop is on a longer route). Agree to apply it.",
    "ask": true, "request_ids": [ 25 ],
    "fares": [ { "request_id": 25, "name": "Ethan Tan", "from": "420.0", "to": "460.0", "note": "The new stop is on a longer route" } ] },
  "actions": { "renew": { "year": "2027" }, "bus_not_required": true, "school_calendar": true, "guardians": true,
               "change_of_address": true, "change_service": true, "stop": true, "contact": true, "fees": { "due": 1 } }
} }
```

- **`riders`** — one card per child on a rider list (today or from a later start), once no first invoice is owed.
  `next_bus_date` is today or the next day with a bus (up to 15 days ahead); when `today` is false show
  "Next bus day · <date>" over the legs. Leg `status`: `Scheduled`, `On the way`, `Ended`, `Not Required` (+ `note`, the
  reason from Bus Not Required), or `Not on a route` (`main` "Not on a route yet"). **Track Bus** only when `can_track` → Live Tracking `GET /app/school/live` ([home.md § 6](home.md#6-live-tracking-get-appschoollive)).
  Card tap → [Bus Information](#3-bus-information).
- **`children`** — every other child: `badge` (No Bus Yet, Requested, Under Review, Fee Unpaid, Accepted, Waitlisted,
  Declined, Offer Lapsed), the `line` under it and one button `action` (or none):

  | `action.kind` | Button | Goes to |
  | --- | --- | --- |
  | `request` | Request School Bus | [§ 4](#4-request-school-bus) with `action.school_id` |
  | `view_request` | View Request | [§ 5](#5-application-status-withdraw-agree) with `request_id` |
  | `pay_registration` | Pay Registration Fee (Billing Contact) | the Invoice of `bill_id` ([fees.md § 3](fees.md#3-invoice-get-appfeesinvoicesid)) |
  | `first_invoice` | View First Invoice (Billing Contact) | the Invoice of `bill_id` ([fees.md § 3](fees.md#3-invoice-get-appfeesinvoicesid)) |

  With no request yet the card carries `window { state: open | soon | closed, year, opens_on, closes_on }` and the line
  says "… is accepting bus requests for 2027 until 3 Sep 2027. Service by SimpleDrive", "… opens bus requests for 2027 on
  …", "Bus requests for 2027 closed on …. Ask SimpleDrive about a late request" or "… is not on Convoy yet".
- **`address_change`** — the latest Change of Address (null when none): the orange banner "Address change from <from>" +
  `line`. When `ask`, show **Agree to New Fare** / **Don't Agree**: call [Agree](#53-agree-to-new-fare--dont-agree-post-appschoolrequestsidagree) for
  each id in `request_ids`.
- **`actions`** — the quick actions shown when at least one child rides: `renew` (null = hide "Renew for <year>"),
  `fees` is null for anyone but the Billing Contact (`due` = unpaid bills so far, the badge).
- No children: `riders` and `children` are empty → "No children in your Family yet" + Add a Child.

## 3. Bus Information

`GET /app/school/riders/:dependant_id/bus?session=am|pm` (default: the first session the child rides). `404` when the child
does not ride.

```json
{ "data": {
  "child": { "dependant_id": 1, "name": "Ethan Tan", "first_name": "Ethan", "level": "P4", "school": "St. Stephen's School" },
  "company": { "id": 1, "name": "SimpleDrive", "mark": "SD" },
  "sessions": [ "am", "pm" ], "session": "am", "date": "2027-01-04", "status": { "label": "Scheduled", "tone": "neutral" },
  "bus": { "plate": "PC7475L", "seats": 40, "model": "Yutong ZK6107", "size": "L" },
  "rows": [ { "key": "Route", "value": "SSS AM 1" }, { "key": "Pick-up Point", "value": "Blk 412 Bedok North Ave 2" },
            { "key": "Pick-up Time", "value": "06:55" }, { "key": "Arrive at School", "value": "07:30" }, { "key": "Days", "value": "Mon to Fri" } ],
  "crew": [ { "role": "Driver", "name": "Ahmad Ali", "phone": "+65 9123 4567", "relief": false },
            { "role": "Bus Attendant", "name": "Siti", "phone": "+65 9000 2222", "relief": false } ],
  "guardians": { "count": 2, "text": "2 people can receive Ethan" },
  "can_track": true
} }
```

- The Pick-up / Drop-off control switches `session` (only those in `sessions`). Afternoon rows: Route, Leaves School,
  Drop-off Point, Drop-off Time, Days. `bus` is null when the route has no bus yet; `rows` / `crew` are empty when the child
  is not on a route that day.
- The bus is the run's that day, else a replacement, else the route's regular bus. Calling the **Driver** asks first (HTML);
  the Authorised Guardians row opens [household § 7](household.md#7-authorised-guardians).

## 4. Request School Bus

### 4.1 The form: `GET /app/school/apply?school_id=`

`school_id` = the child's `school.id` from the Household, or `action.school_id` from the page. Every company serving a
school of that name with a scheduled registration comes back in `providers` (usually one; pills when more).

```json
{ "data": {
  "school": { "name": "St. Stephen's School" },
  "home": { "address": "Blk 412 Bedok North Ave 2, #08-123", "postal": "460412" },
  "providers": [ {
    "school_id": 1, "company": { "id": 1, "name": "SimpleDrive", "mark": "SD" }, "year": "2027",
    "window": { "state": "open", "opens_on": "2026-10-18", "closes_on": "2027-09-03", "starts_on": "2027-01-04", "ends_on": "2027-12-31" },
    "mid_year": null,
    "start": { "options": [ "first", "pref", "fixed" ], "default": "first", "first_day": "2027-01-04", "dates": null, "default_on": "2027-01-04",
               "fix_why": [ { "value": "move", "label": "Moving House" }, { "value": "ready", "label": "Not Ready Before Then" }, { "value": "other", "label": "Other Reason" } ] },
    "levels": [ "P1", "P2", "P3", "P4", "P5", "P6" ], "sessions": [ "AM", "PM", "CCA" ],
    "services": [ { "value": "both", "label": "Two Ways" }, { "value": "am", "label": "One Way Morning" }, { "value": "pm", "label": "One Way Afternoon" } ],
    "cca": { "on": true, "per": "trip", "per_ride": "8.0", "starts_on": "2027-01-04" },
    "show_fare": true, "registration_fee": "50.0",
    "agreement": { "text": "I have read and agree to the Payment & Refund Policy, …", "extra_terms": null },
    "children": [ { "dependant_id": 1, "name": "Ethan Tan", "level": "Primary 4", "student_id": "S4-0412", "can_apply": false, "reason": "Already rides the bus", "request_id": null },
                  { "dependant_id": 2, "name": "Lucas Tan", "level": "Primary 1", "student_id": null, "can_apply": true, "reason": null, "request_id": null } ] } ]
} }
```

- **Step 1**: School, Service Provider (`company`), Academic Year "AY<year> · requests until <closes_on>", the children
  switches (only `can_apply`; default on) + Add New Child ([household § 4.1](household.md#41-add-a-child-post-apphouseholddependants)).
  `window.state` other than `open` → the request is refused; show the line from the page instead.
- **Step 2, per child**: Level in <year> (`levels`, required), Student ID, **When Should the Bus Start?** — before term
  (`mid_year` null): `first` From the First School Day (`first_day`) / `pref` Preferred Date / `fixed` Fixed Date (a date
  from `first_day` to `ends_on`); mid-year (`mid_year { ack_days, plan_weeks }`): `asap` As Soon As Possible / `pref` /
  `fixed` with a date from `dates` (the next 8 Mondays, default `default_on`). Fixed → **Why This Date?** (`fix_why`;
  `other` needs text). **Service Requirement** (`services`). **Pick-up Point · Morning** / **Drop-off Point · Afternoon**:
  Home Address (`home`) or Different Point (6-digit postal + "Block, street, unit"). **CCA / ASA bus** switch only when
  `cca.on`: `per: "period"` adds a monthly amount ([§ 4.2](#42-review-and-estimated-fare-post-appschoolapplyreview)),
  `per: "trip"` is booked per ride at `per_ride` (CCA Bus, [fees.md § 5](fees.md#5-cca-bus-week-get-appcca)); CCA Bus From: Start of CCA (`starts_on`) or a date.
- `show_fare: false` = the company does not show fares to parents: hide the estimate amounts.

### 4.2 Review and Estimated Fare: `POST /app/school/apply/review`

Same body as Submit without `agree` ([§ 4.3](#43-submit-post-appschoolapply)); checks everything Submit checks (the same
`422` messages, so call it on step 2's Next for the last child) and saves nothing.

```json
{ "data": {
  "school": { "id": 1, "name": "St. Stephen's School" }, "company": { "id": 1, "name": "SimpleDrive", "mark": "SD" }, "year": "2027", "show_fare": true,
  "children": [ { "dependant_id": 2, "name": "Lucas Tan", "level": "P2", "student_id": null, "service": "both",
                  "start": { "start_when": "first", "start_on": "2027-01-04", "text": "From the first school day, 4 Jan 2027" },
                  "pickup": { "home": true, "address": "Blk 412 Bedok North Ave 2, #08-123", "postal": "460412" },
                  "dropoff": { "home": true, "address": "Blk 412 Bedok North Ave 2, #08-123", "postal": "460412" },
                  "cca": false, "cca_from": null,
                  "estimate": { "shown": true, "amount": "840.0", "fare": "840.0", "cca": null, "cca_per_ride": null, "unit": "semester",
                                "km": "1.1", "text": "About 1.1 km from school · two ways S$840.00 a semester" } } ],
  "riders": 1, "total": "840.0", "registration_fee": { "each": "50.0", "total": "50.0" },
  "note": "SimpleDrive reviews in 1 to 2 weeks and sends the final quote. Once accepted, the first invoice is issued here"
} }
```

- The fare is the company's **real Bus Fares**: the tier for the straight-line distance from school to the pick-up point
  (the drop-off point for afternoon only), for the billing period the start falls in (`unit`: `month`, or the year's
  `term` / `semester`), two ways or one way; `cca` = the CCA bus a period when charged per period. `amount: null` (and
  `total: null`) = no Bus Fares apply ("The fare comes with the transport company's quote").
- `registration_fee` null → "No registration fee or deposit at this school"; else "Registration fee S$<total> is paid
  now". The bill adds GST when the company charges it (Finance Settings).

### 4.3 Submit: `POST /app/school/apply`

```json
{ "application": {
  "school_id": 1, "agree": true,
  "children": [ {
    "dependant_id": 2, "level": "P2", "student_id": "S1-0099",
    "start_when": "fixed", "start_on": "2027-02-01", "fix_why": "other", "fix_note": "Moving in late January",
    "service": "both",
    "pickup": { "point": "home" },
    "dropoff": { "point": "other", "postal": "460216", "address": "Blk 216 Bedok North St 1" },
    "cca": true, "cca_from": "cca" } ] } }
```

→ `201 { data: [request] }` ([§ 8](#8-the-request-object)), one per child. `pickup` is ignored for afternoon only,
`dropoff` for morning only. `cca_from`: `"cca"` (start of CCA) or a date. When the school charges a registration fee, **one
bill** for all the children is issued at once; each request shows `Fee Unpaid` until it is paid. Then go to Application
Status (no fee) or the bill's Invoice (Billing Contact, [fees.md](fees.md)).

`422` messages (shown as is): "Agree to the Transport Procedures and Safety Rules to continue", "Choose at least one child",
"Choose a child from your Family", "<first> goes to <school>, not <school>", "<first> already has a bus request for 2027",
"<first> already rides the bus at <school>", "Choose the level", "Enter the pick-up postal code and address", "Enter the
drop-off postal code and address", "Pick a start date from tomorrow", "Pick a date from the first school day, 4 Jan 2027",
"Pick a date in the 2027 school year, up to 31 Dec 2027. Requests for a later year open with its registration", "Say why the
bus has to start on this date", "<school> has no morning / afternoon / CCA bus to ask for", "<school> opens bus requests on
<date>", "Bus requests for <school> closed on <date>", "<school> is not taking bus requests yet".

## 5. Application Status, Withdraw, Agree

### 5.1 `GET /app/school/requests/:id`

The [request object](#8-the-request-object). `404` for a request of another Family. Screen: "<child> · AY<year>", the
`badge`; when `status` is `Accepted`: "SimpleDrive accepted the request for <first>", "Final quote S$x a month (you were
shown S$y)." or ", as estimated." from `fare.quote` / `fare.estimate`, `fare.note`, "pay it by <offer.by>" and **View First
Invoice** (`first_invoice`, Billing Contact); `message { title, text }` for Waitlisted / Declined / Lapsed / a mid-year
acknowledgement; the rows (School, Service Provider, Service `service_text`, Start Date `start.text`, Pick-up Point,
Drop-off Point, CCA Bus from, Final / Estimated Fare + km, Registration Fee `registration_fee.paid`); `timeline` (4 steps,
`state` done / current / todo). `Active` → "Service confirmed. Starts <start.on>. SimpleDrive sends the pick-up point, bus
and crew before then. Invoices are under Fees."

### 5.2 Withdraw Request: `POST /app/school/requests/:id/withdraw`

Only when `can.withdraw` (a bus service application not yet Active or Declined). → the request, `status: "Withdrawn"`.
An accepted request withdrawn before its first invoice is paid tells the company to take the child off the rider list.

### 5.3 Agree to New Fare / Don't Agree: `POST /app/school/requests/:id/agree`

`{ "yes": true }` or `{ "yes": false }`; only when `can.agree` (`badge` "Agree to New Fare": a Change of Address or Change
of Service the company confirmed at a higher fare). Yes → `Active` (and, for a move sent with "Update the Family's
residential address", the Family's address changes now); no → `Not Agreed` ("You did not agree to the new fare.
SimpleDrive will contact you"). `422` "This request is not waiting for the parent".

## 6. Renew / Change Service / Stop Bus Service

### 6.1 The screen: `GET /app/school/changes?kind=renew|svc|stop`

```json
{ "data": { "kind": "svc",
  "children": [ { "dependant_id": 1, "name": "Ethan Tan", "first_name": "Ethan", "level": "P4", "school": { "id": 1, "name": "St. Stephen's School" },
                  "company": { "id": 1, "name": "SimpleDrive", "mark": "SD" }, "service": "both", "cca": false,
                  "fares": { "both": "840.0", "am": "504.0", "pm": "504.0", "cca": null } } ],
  "mine": [ request ],
  "from_dates": [ "2027-01-11", "2027-01-18", "…8 Mondays" ] } }
```

- `children` — the children who ride. Renew lists only children whose school takes renewals for a later year and adds
  `year`, `closes_on`, `next_level` (default of Level in <year>; null in the final level), `final_level` (show "Final level
  at <school>. Renew only if <first> stays at the school in <year>." and default the switch off), `levels`, `fares` (that
  year's Bus Fares, or null with `fare_note` "The 2028 fare comes with SimpleDrive's confirmation"). Change Service adds
  `fares` per service for "Now S$x a month · after the change about S$y". Stop adds `notice { n, unit, earliest_on }` for
  "Notice period 1 months, so the earliest last day is …. You can ask for an earlier day, but fees are charged up to …"
  and `current_fare`.
- `mine` — the Family's requests of that kind so far, newest first ([§ 8](#8-the-request-object)): show `child.name`,
  `change.what`, `badge`, `line`; **Agree to New Fare / Don't Agree** when `can.agree`; **Pay S$x** when
  `can.pay_first_invoice` (accepted renewal, Billing Contact: [fees.md § 4](fees.md#4-pay-post-appfeesinvoicesidpay)).
- `from_dates` (svc): Change From (default the third); `why` (stop): the Reason list.

### 6.2 Send

| Button | Call | Body |
| --- | --- | --- |
| Send Renewal | `POST /app/school/renewals` | `{ renewal: { children: [ { dependant_id, level, service, cca } ] } }` |
| Send Change | `POST /app/school/service_changes` | `{ service_change: { from, children: [ { dependant_id, service, cca } ] } }` |
| Send Request to Stop | `POST /app/school/stops` | `{ stop: { last_on, why, why_note, children: [ { dependant_id } ] } }` |

→ `201 { data: [request] }`. `422`: "Choose at least one child", "Choose a child who rides the school bus", "Choose the
level for 2028", "<school> is not taking renewals now", "<first> already has a renewal for 2028", "Pick the date from the
list", "Pick a different service for at least one child", "Pick a last day from tomorrow", "Say why the bus is no longer
needed", "<first> already has a request to stop".

## 7. Change of Address

### 7.1 Step 1: `GET /app/school/address_change[?dependant_ids[]=1]`

```json
{ "data": {
  "home": { "block": "412", "street": "Bedok North Ave 2", "floor": "08", "unit": "123", "postal": "460412", "address": "Blk 412 Bedok North Ave 2, #08-123" },
  "children": [ { "dependant_id": 1, "name": "Ethan Tan", "school": "St. Stephen's School", "company": { "id": 1, "name": "SimpleDrive", "mark": "SD" },
                  "sessions": [ "am", "pm" ], "riding": true, "current_fare": "420.0" } ],
  "rule": { "notice_days": 14, "start": "any", "max_days": 90, "from": "2026-11-30", "to": "2027-02-14" },
  "dates": [ "2026-11-30", "2026-12-01", "…" ], "default_on": "2026-11-30" } }
```

- `children` = every child who rides and every child with an application in progress; switches default on.
- **Bus From the New Address On**: only dates in `dates` (the calendar greys the rest). The rule is the strictest of the
  children's schools (notice days, `start` any day / `mon` a Monday / `first` the first school day of a month, how far
  ahead). Call again with `dependant_ids[]` when the switches change, to get the dates for those children.
- Postal search: `GET /app/household/postal?postal=` ([household § 2.1](household.md#21-postal-code-get-apphouseholdpostalpostal460412)).
  Switch **Update the Family's residential address** (default on) → `update_home`.

### 7.2 Step 2 → 3: `POST /app/school/address_change/review`

Body as Submit. Step 2 lists, per child, the `sessions` that move (send `am` / `pm` false to keep one). →

```json
{ "data": { "move_on": "2027-01-18", "new_address": "Blk 216 Bedok North St 1, #05-22, S460216",
  "children": [ { "dependant_id": 1, "name": "Ethan Tan", "school": "St. Stephen's School", "company": { "…": "…" },
                  "old_address": "Blk 412 Bedok North Ave 2, #08-123, S460412", "moves": [ "Morning pick-up moves", "Afternoon drop-off moves" ],
                  "current_fare": "840.0", "new_fare": "840.0" } ],
  "note": "SimpleDrive confirms the new pick-up point and fare before 18 Jan 2027. The current service runs unchanged until then." } }
```

### 7.3 Confirm Change: `POST /app/school/address_change`

```json
{ "address_change": { "postal": "460216", "block": "216", "street": "Bedok North St 1", "floor": "05", "unit": "22",
                      "move_on": "2027-01-18", "update_home": true, "children": [ { "dependant_id": 1, "am": true, "pm": true } ] } }
```

→ `201 { data: [request] }` (kind `adr`). The Family's address does **not** change now: with `update_home` it changes when
the company confirms the move (or the parents agree to a higher fare); a declined move never changes it. `422`: "Enter a
6-digit postal code", "Enter the block or house number and the street", "Choose at least one child", "Choose at least one
service", "Pick the date from the calendar".

## 8. The request object

```json
{ "id": 24, "code": "REQ-0024", "kind": "new", "renew": false, "status": "Requested",
  "badge": { "label": "Fee Unpaid", "tone": "warning" }, "submitted_at": "2026-11-16T19:41:55.000+08:00",
  "school": { "id": 1, "name": "St. Stephen's School" }, "company": { "id": 1, "name": "SimpleDrive", "mark": "SD" }, "year": "2027",
  "child": { "dependant_id": 2, "name": "Lucas Tan", "first_name": "Lucas" }, "level": "P2", "student_id": null,
  "service": "both", "service_text": "Two Ways · To School and Home", "cca": false, "cca_from": null,
  "start": { "when": "first", "on": "2027-01-04", "text": "From the first school day, 4 Jan 2027" },
  "pickup": { "address": "Blk 412 Bedok North Ave 2, #08-123", "postal": "460412" },
  "dropoff": { "address": "Blk 412 Bedok North Ave 2, #08-123", "postal": "460412" },
  "fare": { "estimate": "420.0", "km": "1.1", "quote": null, "unit": "month", "note": null, "current": null },
  "offer": null, "message": null, "line": "Sent to SimpleDrive on 16 Nov 2026",
  "timeline": [ { "name": "Requested", "meta": "Submitted 16 Nov 2026 · registration fee unpaid", "state": "done" },
                { "name": "Under Review", "meta": "Waiting for SimpleDrive to open it · usually 1 to 2 weeks", "state": "current" },
                { "name": "Accepted", "meta": "Final quote and first invoice issued · pay to confirm", "state": "todo" },
                { "name": "Active", "meta": "Service starts 4 Jan 2027 · pick-up point and bus shared before then", "state": "todo" } ],
  "change": null,
  "can": { "withdraw": true, "agree": false, "pay_first_invoice": false, "pay_registration": true },
  "registration_fee": { "paid": false, "amount": "50.0",
                        "bill": { "id": 22, "number": "INV-2026-000022", "period": "Registration · AY2027", "total": "54.5",
                                  "due_on": "2026-11-16", "due_at": "2026-11-16T19:41:55.000+08:00", "paid": false } },
  "first_invoice": null }
```

- `status` is the company's word (Lapsed / Stopped worked out from the dates); `badge` is what the app shows (Fee Unpaid,
  Offer Lapsed, Agree to New Fare…). `line` = the one-line status of the Renew / Change / Stop lists and the address banner.
- `offer { by, hours_left }` while an accepted application waits for its first invoice (48 hours by default).
- `change` (kinds `adr`, `svc`, `stop`): `effective_on`, `what` ("Morning Only from 18 Jan 2027", "Last day 20 Jan 2027",
  "Move from …"), `old_address`, `new_address`, `new_postal`, `new_stop`, `update_home`, `from_service`, `to_service`,
  `last_on`, `earliest_on`, `early`, `stop_reason`, `notice { n, unit }`, `pay_to`.
- **Billing Contact only**: `registration_fee.amount`, `registration_fee.bill`, `first_invoice`, `can.pay_*`. Others get
  `registration_fee { paid, amount: null, bill: null }`, `first_invoice: null` and false.

## 9. Values reference

| Field | Values |
| --- | --- |
| `kind` | `new` (application; `renew: true` = Renew), `adr` Change of Address, `svc` Change Service, `stop` Stop Bus Service |
| `status` | Requested, Under Review, Accepted, Active, Waitlisted, Declined, Lapsed, Withdrawn, Not Agreed, Stopping, Stopped |
| `badge.label` | No Bus Yet, Requested, Under Review, Fee Unpaid, Accepted, Active, Waitlisted, Declined, Offer Lapsed, Withdrawn, Agree to New Fare |
| `badge.tone` | `info`, `success`, `warning`, `danger`, `neutral` |
| `service` | `both` Two Ways, `am` One Way Morning, `pm` One Way Afternoon |
| `start_when` | `first`, `asap`, `pref`, `fixed`; `fix_why`: `move`, `ready`, `other` |
| `why` (stop) | `leave` Leaving the School, `move` Moving House, `noneed` No Longer Needed, `other` Other Reason |
| `window.state` | `open`, `soon`, `closed` |
| Leg `status` | Scheduled, On the way, Ended, Not Required, Not on a route |
