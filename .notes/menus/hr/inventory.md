# HR menu (rail `pay`, label "HR", icon `badge`) — feature inventory from the HTML prototype

Paths are relative to `/Users/kevinluu/workspace/convoy-v3/Convoy Project/`.
Abbreviations: **HTML** = `Convoy OS.dc.html`, **pay.js** = `logic/mixins/pay.js`, **DP** = `driver-pay.js` (`window.DriverPay`), **EXP** = `param-explainers-hr.js`, **admin.js** = `logic/mixins/admin.js`.

Menu definition: `admin.js:1048-1058` (`payIt`), rail item `admin.js:1090` (`{ id: 'pay', icon: 'badge', label: 'HR' }`). Order: Drivers (`paydrv`, icon badge), Earnings (`payearn`, receipt_long), Pay Schemes (`payschemes`, account_balance_wallet), Rate Plans (`payrates`, sell), Bonuses (`paybon`, emoji_events), Points (`paypts`, stars), Rewards (`payrew`, redeem), Salary Simulator (`paysim`, calculate), Audit Log (`paylog`, history). Page values wired at `admin.js:1177-1188`.

---

## 0. Summary

### Pages → main entities

| Page | Main entities (prototype key) | Notes |
|---|---|---|
| Drivers `paydrv` | **driver pay assignments**: scheme assignment `{id, sid, from, to}` and vehicle-type assignment `{id, vt, from, to}` per driver (`cfg().pay.drv[driverKey] = {sch:[], veh:[]}`) | Drivers themselves come from Fleet (own vehicles' `driverName`) |
| Earnings `payearn` | **monthly earnings confirmation** `cfg().pay.earn["driverKey|YYYY-MM"] = {total, n, by, at, keys[]}`; reads occurrences + **trip issue** (`sched.iss[key] = {why, by, at}`) | Pay computed live by `DriverPay.simulate` from completed runs |
| Pay Schemes `payschemes` | **pay scheme** (≈60 fields) + nested tiers: daily volume tiers, weekly target tiers, monthly target tiers, route bands; `isDefault`; `lock` | `cfg().pay.schemes[]` |
| Rate Plans `payrates` | **rate plan** `{id, name, description, vehicleTypes[], periods[], lock}` → **period** `{id, name, days[], timeRanges[], isOverride, rates{vt:{trip, hourly}}}` → **time range** `{id, startTime, endTime}` | `cfg().pay.plans[]` |
| Bonuses `paybon` | **campaign bonus** (planType, frequency, start/end period, payout schedule + trenches, eligibility schemes/drivers, sign-up + T&C + signed-up drivers, deconfliction rules, tiers, excluded attendance periods, lock) | `cfg().pay.bon[]` |
| Points `paypts` | **points ledger entry** `{id, dk, pts(±), desc, date, exp, status, by}` | `cfg().pay.pts[]`; balance derived |
| Rewards `payrew` | **reward** `{id, title, description, photo, pointsRequired, status}` | `cfg().pay.rew[]`; no redemption flow |
| Salary Simulator `paysim` | **simulator template** (5 shared slots) `cfg().pay.simTpl[]`; working inputs in localStorage `convoy.paysim.v1` | What-if tool; no real data written except templates |
| Audit Log `paylog` | **pay audit entry** `{id, at, user, action, type, name, details}` | `cfg().pay.log[]`, capped at 500 |

All HR data lives in one JSON blob `cfg().pay` (company settings), saved via `paySave` (`pay.js:9-23`) → `saveCfg` (`HTML:18195-18200`, `SA.api.saveSettings`). Shape of `cfg().pay`:
```
{ plans[], schemes[], drv{driverKey:{sch[],veh[]}}, earn{"driverKey|ym":{...}}, bon[], pts[], rew[], simTpl[5], log[] }
```
`payCfg()` (`HTML:18185-18193`) returns `plans`/`schemes` from cfg, or an in-memory seed (`DP.seedPlans`, `DP.seedSchemes`) when never saved — the seed is regenerated (random ids) every page load until the first save.

### Access / permissions
- HR menu and every HR page require `hasC && canFin()` (`admin.js:1048`, `1177`). `canFin()` = role `super` or perms include `finview` or `finance` (`logic/mixins/finance.js:11-16`).
- `payAdm()` (`pay.js:1042`) = role `admin` OR perms include `users`. Needed to **Unlock** rate plan / scheme / bonus, and to **Reopen** a confirmed Earnings month. Anyone with HR access can **Lock**.
- `roStop()` (`logic/mixins/vs-engine.js:1276-1278`): Convoy Admin is view-only ("View only. Convoy Admin cannot change company data"); applied by `saveCfg` and explicitly in Earnings confirm/reopen.
- Rails mapping to decide: `canFin` ≈ member permission `finance`/`finview`; `payAdm` ≈ admin/owner or permission `users`.

### Top open questions / ambiguities (design decisions needed)
1. **Driver identity**: prototype keys drivers by lower-cased name from vehicles (`payDrivers`, `pay.js:1070-1080`; `payEarnVals` `pay.js:1723-1727`). Rails has a `drivers` table → use `driver_id` FK everywhere (assignments, earnings, points, bonus eligibility/sign-up).
2. **Scheme / vehicle type per job date vs per month**: tooltip says "Pay follows the scheme on each job date, so a change mid-month splits the month" (`pay.js:1111`), but Earnings picks the assignment active on the **last day of the month** (`pay.js:1751-1755`, `act(r.sch, z)`), and Vehicle Financials uses the **first day** (`fleet.js:342`). Need a rule (split month into segments per scheme? pro-rate fixed pay?).
3. **Fixed pay with partial months** (driver joins/leaves mid-month, scheme changes mid-month): no proration anywhere in `simulate`. Explainer says route retainer is pro-rated "by calendar days" (`pay.js:862`, HTML 8718) but code pays full `rtN * avg band` (`DP:118`).
4. **Rejection count source**: penalty needs "rejected jobs in month" — only a manual number in the simulator (`pay.js:417`); Earnings never passes `rejected` (`pay.js:1759`), so penalty never applies to real pay. Need a job offer/reject record (driver app).
5. **On-time % / attendance %** for reliability bonuses: only manual inputs in simulator (`pay.js:621`). Need data sources (Reports OTP? attendance/leave?).
6. **Bonuses, points-from-bonuses, payout schedule** are only evaluated in the simulator; Earnings ignores bonuses entirely (`pay.js:1749-1772`). Real bonus accrual, "paid N months later"/split trenches, and auto-crediting bonus points are not built. Quarterly/half-yearly/yearly bonuses are never computed ("not worked out for one month", `pay.js:653`).
7. **Trip value variants not handled in Earnings**: `payOccTv` (`pay.js:1633-1644`) handles `tv`, `tv2` (return), shuttle `tvPer='day'` split; it ignores `tvMode='hours'` (by the hour, rounded up/down to quarter hour — `trip-form.js:1310`), per-run overrides `runTv`, and replacement **pay split** ("Who Earns the Trip Value": Original / New / Both, Full / Split with `pct`, `scheduler.js:226,280-312`). Rails already has `trip_occurrences.trip_value`, `trips.trip_value_mode/rounding/per/return`, `replacements.pay_split/original_share` — decide how HR consumes them.
8. **"Completed" definition**: a past run counts as completed unless cancelled or issue raised (`scheduler.js:544-551`; TODO.md:73 "today a past run counts as completed unless an issue is raised"). Rails has `trip_occurrences.status`, `ended_at`, `issue_*` columns. Decide whether pay needs `ended` status from driver app.
9. **Disposal detection**: Earnings treats `kind === 'Disposal'` as hourly from start to end (`pay.js:1744,1757`). Hourly charter / shuttle in hours mode not considered.
10. **Overnight shift**: `shiftOn` uses `mins >= start && mins < end` (`DP:74`), so a shift like 22:00–06:00 (shown in explainer `EXP:53`, "Shift 22:00 to 06:00") never matches. Support cross-midnight shifts?
11. **Weekly target with partial weeks**: weekly incentive only evaluated on a Sunday whose week started on a Monday inside the month (`DP:86,112`); first partial week and trailing partial week are dropped. Cross-month weeks rule needed.
12. **Points ledger semantics**: balance = Σ negatives + Σ non-expired positives (`pay.js:1478`), no FIFO consumption, so a deduction against points that later expire is double-counted. Text claims "expire 24 months after they were given, oldest first" (`pay.js:1481`). Need lot-based (FIFO) ledger or explicit expiry entries. `status 'expired'` is never written.
13. **Rewards redemption**: no redemption record; admin deducts points manually with reason (`pay.js:973` tip). Driver app redemption not built. Decide whether to add `reward_redemptions`.
14. **Bonus sign-up** is done "in the driver app" (not built); admin can tick drivers by hand (`pay.js:1427-1431`). `excludedAttendancePeriods` is stored but never used in any calculation.
15. **Pay periods**: everything is calendar-month. `payPeriods` supports weekly/monthly/quarterly/half-yearly/yearly only for bonus periods (`pay.js:1202-1248`). No pay-run / payslip / payroll export / CPF deduction / allowances / deductions in HR. CPF exists only in `logic/cpf.js` (employer CPF) used by Vehicle Financials (`fleet.js:351`), not in HR pages. **No maker-checker** for driver pay (Finance's `finSet().approval` maker-checker applies to operator pay runs only, `admin.js:1621`). Confirm Month is single-person.
16. **Earnings confirmation snapshot**: stores only `{total, n, by, at, keys}` (`pay.js:1927-1933`); breakdown is not frozen. Rails should snapshot breakdown (JSON allowed for snapshots per CLAUDE.md) or lines table.
17. **Audit log**: the prototype keeps its own log in `cfg().pay.log` (cap 500). Rails already uses `audited` — decide whether HR Audit Log page reads from `audits` filtered to HR models, or a dedicated table. Simulator template saves/deletes are not logged; Earnings confirm logs type `driver_pay` which has no label/filter option (`pay.js:1913`, `1960-1967`).
18. **Locking**: rate plans, schemes, bonuses can be locked (`lock {by, at}`); rewards and points cannot. Editing a scheme/plan that already paid confirmed months is allowed when unlocked — versioning / effective-dating of schemes and plans is not modelled (changing rates retroactively changes unconfirmed months).
19. **Vehicle type for a driver** without assignment: derived from the first enabled vehicle type with same seats, else first with seats ≥ (`pay.js:1078`). Rails has `vehicles.vehicle_type_id` presumably → use it directly.
20. **Earnings rate line bug**: `lineOf` looks for `l.j`/`l.id` (`pay.js:1854`) but `simulate` lines never carry ids (`DP:104`), so per-trip pay explanation is always empty. In Rails, store per-job pay lines with occurrence identity.
21. **Default scheme fallback**: a driver with *no* scheme assignments is paid on the default scheme; a driver whose assignments exist but none covers the date has **no scheme** (`pay.js:1107`, `1752`). Keep this rule?
22. **Driver age shown** uses KYC dob; when KYC is missing the prototype fabricates a sample KYC (`fleet.js:1887-1899`, `drvKyc`) — sample data.

---

## 1. Rate Plans (`payrates`)

Markup `HTML:8040-8232`; logic `payPlVals` `pay.js:38-184`; engine `DP:15-22, 34-37`.

### 1.1 What the user sees / does
- Header "Rate Plans" + **How It Works** (HIW stepper, content `pay.js:925-934`). (HTML 8042-8043)
- Header buttons:
  - When editing (dirty): **Cancel**, **Save and Lock** (icon lock), **Save** (icon check). (HTML 8045-8048)
  - When clean: **Unlock** (if `canUnlock`: locked && admin && !dirty), **Lock** (if `canLock`: !locked && !dirty), **Add Rate Plan**. (HTML 8050-8053; `pay.js:1044-1067`)
- Lock banner `lockTxt`: "Locked by {by} on {date}. Unlock it to change or delete it" / "... Ask an Admin to unlock it" (`pay.js:1056`).
- Intro: "Per-trip and per-hour rates for each vehicle type, by day and time. A pay scheme uses one rate plan: trip pay is the per-trip rate times the trip value, and disposal pay is the hourly rate times the hours" (HTML 8060).
- **List** (left): each plan card: name (or "Untitled Rate Plan"), sub "{n} period(s) | Used by {u} scheme(s)" or "Not used yet", plus " | Not saved" while editing (`pay.js:46-58`). Click switches; blocked with flash "Save or cancel your changes first" if a plan edit is open (`payGuard`, `pay.js:36`).
- **Plan Details** card (HTML 8071-8092): ⓘ tip "Rate Plan" (`pay.js:170`); **Delete Plan** button; inputs:
  - Plan Name (text, placeholder "e.g. Standard")
  - Description (text, optional)
- **Vehicle Types** card (HTML 8099-8114): toggle pills of vehicle types (`schVT()`, enabled ones plus disabled ones already in the plan, `pay.js:96,174-181`); hint "Each period gets a rate for every type picked here. Types come from Vehicle Types". Tip `pay.js:171`.
- **Periods** (HTML 8117-8186), one card per period (colour from palette by index):
  - Period Name (text, placeholder "e.g. Peak")
  - Switch **Takes Priority** — "Used instead of other periods where they overlap, like weekend and PH rates" (= `isOverride`)
  - Remove period icon (only if >1 period)
  - **Days**: toggle pills Mon Tue Wed Thu Fri Sat Sun **PH** (`DL`, `pay.js:45`)
  - **Times**: list of ranges `start` "to" `end` (`input type=time`); note "Ends the next day" when end < start (`pay.js:122`); remove (if >1); **Add Time** (default 09:00–17:00)
  - Rates table: "Vehicle Type | Per Trip | Per Hour, Disposal"; per selected type two number inputs suffix S$ placeholder 0.
  - **Add Period** (default name '', days Mon–Fri, 09:00–17:00, rates {}) (`pay.js:135-143`)
- **Coverage** card (HTML 8190-8225): legend (period colours + "No rate"); grid 8 rows (Mon..Sun, PH) × 48 half-hour cells, colour = period that pays at the cell's midpoint (`DP.cover(P, dayLabel, c*30+15)`), orange `#FFEFDF` = no rate; tooltip "{Day} {HH:MM}: {period|No rate}" (`pay.js:144-157`). Axis 00:00/06:00/12:00/18:00/24:00.
  - Gap warning: "No rate for {first 6 gaps} and {n} more. Jobs at these times are paid S$0" (`pay.js:183`); else "Every day and time has a rate".
  - Empty-rate warning: "Rates still empty for {period, type; ...} and {n} more" (`pay.js:184`).

### 1.2 Validation / confirms (verbatim)
- Save (`pay.js:78-86`): "Enter a plan name"; "Pick at least one vehicle type"; "Add at least one period"; "Name every period"; "Pick the days for {period name}".
- Delete (`pay.js:88-95`): if locked: "{name} is locked. Unlock it first" / "... Ask an Admin to unlock it"; if used: "Used by {scheme names}. Pick another rate plan there first"; confirm `Delete {name}?`.
- Editing a locked plan: "{name} is locked. Unlock it to make changes" / "... Ask an Admin to unlock it" (`pay.js:30`).
- Flash after save: "Saved {name}" / "Saved and locked {name}"; "Deleted {name}"; "Locked {name}" / "Unlocked {name}"; "Only an Admin can unlock".
- Empty rates are allowed on save (just a warning); empty → treated as 0 in engine.

### 1.3 Data
```
plan  = { id:'rp-xxxxxxx', name, description, vehicleTypes:[vtValue], periods:[period], lock?:{by, at(YYYY-MM-DD)} }
period = { id, name, days:['mon'..'sun','ph'], timeRanges:[{id, startTime:'HH:MM', endTime:'HH:MM'}], isOverride?:bool,
           rates:{ [vtValue]: { trip: number|'' , hourly: number|'' } } }
```
New plan default (`pay.js:61-73`): vehicleTypes = all enabled types; one period "All Day", all 8 day labels, 00:00–23:59, rates {}.
Seed (`DP:25-33`): plan `rp-std` "Standard" — "Weekday, peak, night and weekend rates", periods:
- Off Peak: Mon–Fri 07:00–19:00, +0
- Peak: Mon–Fri 05:00–07:00 and 19:00–21:00, +2
- Night: Mon–Fri 21:00–05:00, +3
- Weekend and PH: Sat, Sun, PH 00:00–23:59, **override**, +4
- Base by seats `base(s)`: ≤6 → trip 12 / hourly 8; ≤13 → 14/10; ≤23 → 16/12; ≤29 → 18/14; else 22/16 (S$). Rate = base + add.
Vehicle types list `schVT()` (`logic/mixins/fleet.js:2936-2947`): built-ins car/4, mpv/6, van(Minibus)/13, mb19, mb23, mc29 (Mini Coach)/29, c40, c45, c49, dd(Double Decker)/89 + custom; `off` if disabled in `cfg().vtypes.off`.

### 1.4 Rate lookup rule (period resolution) — `DP.period` (`DP:15-22`)
```js
function period(plan, d, mins, ph) {
  let day = d; if (mins >= 1440) { day = addD(d, 1); mins -= 1440; }
  const today = lbl(day, ph), yest = lbl(addD(day, -1), ph), hits = [];   // lbl = 'ph' if date is a public holiday, else dow name
  plan.periods.forEach(p => p.timeRanges.forEach(r => { const a = tm(r.startTime); let b = tm(r.endTime); if (b === 1439) b = 1440;
    if (a < b) { if (p.days.includes(today) && mins >= a && mins < b) hits.push(p); }
    else { if (p.days.includes(today) && mins >= a) hits.push(p); if (p.days.includes(yest) && mins < b) hits.push(p); } }));
  return hits.find(p => p.isOverride) || hits[0] || null;
}
```
- A public-holiday date's label is **only** `ph` (a PH Monday does not match "mon" periods).
- Overnight range (end ≤ start) belongs to the start day; the after-midnight part matches when *yesterday*'s label is in days.
- 23:59 end == 24:00.
- Multiple hits: first override in period order, else first hit in period order. No period → rate 0, label "No period".
- Rate = `period.rates[vt].trip` (per trip) or `.hourly` (per hour); missing → 0. Vehicle type not in plan → 0 (warned on Drivers page).
- Coverage grid uses `DP.cover(plan, label, mins)` (`DP:34-37`), same rule by label (PREV of 'ph' is 'ph').

### 1.5 Reads from other areas
Vehicle types (`cfg().vtypes`, platform custom types). Schemes (count "Used by", delete guard).

### 1.6 Sample / demo
Seed plan is generated in-memory until first save (`HTML:18185-18193`).

---

## 2. Pay Schemes (`payschemes`)

Markup `HTML:8234-9125`; logic `payScVals` `pay.js:186-390`, tips `pay.js:858-888`; defaults `DP:38-55`.

### 2.1 Screen
- Header "Pay Schemes", How It Works; dirty: Cancel / Save and Lock / Save; clean: Unlock / Lock / **Add Pay Scheme** (HTML 8236-8247). Lock banner (HTML 8251).
- Intro: "How drivers are paid each month. Trip pay is the per-trip rate times the trip value, and disposal pay is the hourly rate times the hours. Rates come from the rate plan picked here" (HTML 8254).
- List cards: name ("Untitled Pay Scheme"), **Default** badge, sub = type label (+ " | Not saved") (`pay.js:198-209`).
- **Scheme Details**: Delete Scheme; Scheme Name (placeholder "e.g. Basic + Trips"); Description (optional); Switch **Default Scheme** — "New drivers start on this scheme" (HTML 8284-8307).
- **Scheme Type** cards (radio) (`pay.js:193-197`):
  - `basic_plus_trips` "Basic + Trips" — "Basic salary plus pay for every trip, with an optional guarantee"
  - `monthly_with_minimum` "Monthly Pay with Minimum" — "Fixed monthly pay for a minimum number of trips. Extra trips are paid per trip"
  - `shift_based` "Shift Based" — "Fixed salary for set shift hours. Work outside the shift is paid extra"
- **Rate Plan** select (options = plans) + **Open Rate Plan** (navigates to `payrates`; blocked "Save or cancel your changes first" while dirty) + warning "Pick a rate plan, or trips are paid S$0" (HTML 8340-8358).
- **Basic Salary** section (only Basic + Trips) (HTML 8361-8474):
  - Basic Salary (number, "S$ / mo")
  - Switch **Basic Salary Includes Trips** — "The first trips each day are covered by the basic salary instead of paid per trip"
  - when on: **Trips Included a Day** (number, "Trips"); **On** schedule pills: Mon to Fri / Mon to Sat / Mon to Fri + Sun / 6 Days a Week / Every Day (`SCH`, `pay.js:262`); Switch **Public Holidays Included** — "Public holidays on the days above count as covered days" (`basicCoverPH`)
  - Switch **Disposal Hours Count as Trips** — "Each disposal hour uses up one included trip"
- **Monthly Pay** section (only Monthly with Minimum) (HTML 8480-8581):
  - Monthly Pay (S$ / mo); **Minimum Trips** pills Per Day / Per Month
  - Per Day: Trips a Day (number); On: schedule pills; Switch Public Holidays Included — "The daily minimum also applies on public holidays on the days above" (`monthlyCoverPH`)
  - Per Month: Trips a Month (number)
  - Text "Trips past the minimum are paid at rate plan rates"
  - Switch Disposal Hours Count as Trips — "Each disposal hour counts as one trip towards the minimum"
- **Shift** section (only Shift Based) (HTML 8587-8643): Shift Salary (S$ / mo); Shift Starts / Shift Ends (time); Working Days pills Mon..Sun; **Work Outside the Shift Is Paid By** pills Rate Plan (`trip_rates`) / Hourly Rate (`hourly_rate`); Hourly Rate (S$) when Hourly. Text "Trips and disposal hours inside the shift are covered by the shift salary. Public holidays are always outside the shift".
- **School Routes** section (all types) (HTML 8650-8757):
  - Switch **Monthly Route Retainer** (`schoolRoutesPay`) — "Each assigned route pays a fixed amount every month, in term time and school holidays, instead of per trip"
  - when on: **Monthly Pay by Route Length** bands: each "Band n": Up To (Min) + Monthly Pay (S$ / mo); last open band "Longer Routes" — "Above the last band"; remove band; **Add Band** (inserts before open band: to = last+30, amt = last+50). Text "Paid every month for each route the driver is regular on, in term time and school holidays. Part months are paid by calendar days".
  - Switch **Count Routes in School Holidays** (`schoolRoutesCount`) — "Assigned routes still count as trips on weekdays when school is out"
  - Switch **Counts Towards Guarantee** (`schoolRoutesInG`, shown only if retainer on and Basic+Trips with guarantee) — "Route pay helps reach the guarantee"
- **Guarantee** section (only Basic + Trips) (HTML 8763-8832):
  - Switch **Guaranteed Monthly Pay** — "If the month comes to less, the driver is topped up to this amount"
  - Guaranteed Amount (S$ / mo)
  - **Paid on Top of Guarantee** pills Public Holidays / Saturdays / Sundays; text `onTopTxt`: "Trips on {public holidays, saturdays and sundays} are paid in full on top of the guarantee, with their incentives. They do not count towards it" or "Every day counts towards the guarantee" (`pay.js:383`)
  - Switch **Boost After Guarantee** — "Pay more per trip once regular pay passes the guarantee"; pills Percentage / Flat per Trip / Fixed Rate; Boost (suffix % or S$); text: "Adds this percentage to each trip once pay passes the guarantee" / "Adds this amount to each trip once pay passes the guarantee" / "Pays each trip at this rate once pay passes the guarantee, if higher than the rate plan" (`pay.js:385-386`)
- **Rejection Penalty** (all types) (HTML 8843-8918): Switch — "Applies when a driver turns down more jobs in a month than allowed"; Rejections Allowed a Month (Jobs); Fallback Basic Salary (S$ / mo, not for Basic+Trips); Switch **Keep Incentives** — "Incentives are still paid when the penalty applies"; text `penTxt`: Basic+Trips "When triggered, the guarantee no longer applies" else "When triggered, pay falls back to Basic + Trips: the fallback basic salary plus every trip at the rate plan rates" + ". Incentives are still paid" / " and no incentives are paid" (`pay.js:387`).
- **Incentives** (all types) (HTML 8926-9114):
  - **Daily Volume Incentive** — "Extra pay for each trip past a number of trips in a day"; tiers table From Trip / To Trip (placeholder "No limit") / Boost (select Flat per Trip, Percentage, Fixed Rate) / Amount (suffix S$ or %); Add Tier (from = last.to+1 or last.from+1 or 7; to ''; flat 2) ; text "Trips are counted from the first trip of the day. Leave To Trip empty for no limit"; Switch Counts Towards Guarantee (only when guarantee on) "Off: paid on top of the guarantee".
  - **Weekly Target Incentive** — "Paid when a driver reaches a number of trips in a week"; tiers Trips in a Week / Pay As (Lump Sum, Per Trip) / Amount S$; Add Tier (target = last+5 or 20, lump 50); text "Weeks run Monday to Sunday. Only the highest target reached is paid. Per Trip pays the amount for every trip that week"; Counts Towards Guarantee.
  - **Monthly Target Incentive** — "Paid when a driver reaches a number of trips in the month"; tiers Trips in a Month / Pay As / Amount; Add Tier (last+20 or 80); text "Only the highest target reached is paid, at the end of the month"; Counts Towards Guarantee.
- Field tooltips with full meanings: `pay.js:320-329` and `pay.js:858-888` (verbatim explanations of every switch).

### 2.2 Validation / confirms
- Save (`pay.js:218-229`): "Enter a scheme name"; "Pick a rate plan"; route bands: "Enter the monthly pay for every route band". Numbers coerced (`NUMK` list `pay.js:216`); band `to` = max(1, to) or '' for open.
- Default handling on save: if saved scheme `isDefault`, all others set false; if none default, first becomes default (`pay.js:227`).
- Delete (`pay.js:230-238`): locked msg; "Keep at least one pay scheme"; "Make another scheme the default first"; confirm `Delete {name}?`.
- Lock/unlock as rate plans.

### 2.3 Data (scheme) — defaults from `DP.blankScheme` (`DP:38-50`)
| Field | Type / default | Meaning |
|---|---|---|
| id | 'ps-xxxxxxx' | |
| name, description | '' | |
| isDefault | false | scheme for new drivers / drivers with no assignment |
| schemeType | 'basic_plus_trips' \| 'monthly_with_minimum' \| 'shift_based' | |
| basicSalary | 0 | fixed monthly (Basic+Trips) |
| basicCoversDailyTrips | false | basic covers first N trips a day |
| basicCoveredDailyTrips | 1 | N |
| basicCoveredSchedule | 'mon-fri' (enum mon-fri, mon-sat, mon-fri-sun, 6-days, all-days) | covered days |
| basicCoverPH | (undefined→false) | PH on covered days counts as covered |
| disposalCountsAsTrips | false | each disposal hour consumes an included trip / counts to minimum |
| hasGuarantee | false | |
| guaranteedAmount | 2200 | |
| onTop | {ph:false, sat:false, sun:false} | days paid on top of guarantee |
| hasPostGuaranteeBoost | false | |
| postGuaranteeBoostType | 'percentage' \| 'flat' \| 'fixed_rate' | |
| postGuaranteeBoostValue | 50 | |
| hasRejectionPenalty | false | |
| rejectionPenaltyAllowedJobs | 0 | |
| rejectionPenaltyFallbackBasic | 0 | non-Basic types fall back to this basic |
| rejectionPenaltyKeepsIncentives | true | |
| monthlyPayAmount | 2200 | |
| monthlyMinimumType | 'daily' \| 'monthly' | |
| monthlyDailyTripsCommitment | 6 | |
| monthlyTripsCommitment | 150 | |
| monthlyExpectedSchedule | 'mon-fri' | |
| monthlyCoverPH | (false) | |
| shiftSalary | 0 | |
| shiftStartTime / shiftEndTime | '08:00' / '18:00' | |
| shiftWorkingDays | ['mon'..'fri'] | |
| shiftOvertimePayType | 'trip_rates' \| 'hourly_rate' | |
| shiftOvertimeHourlyRate | 0 | |
| baseRatePlanId | first plan id | FK rate plan |
| schoolRoutesPay | false | monthly route retainer |
| routeBands | [{to:40,amt:200},{to:70,amt:300},{to:'',amt:350}] | minutes upper bound ('' = open) → S$/month |
| schoolRoutesCount | false | count routes as trips in school holidays |
| schoolRoutesInG | true | route pay counts towards guarantee |
| hasDailyVolumeIncentive / dailyVolumeIncludesInGuarantee | false / false | |
| dailyVolumeTiers | [{id, fromTripStart:7, toTripEnd:10, boostType:'flat', boostValue:2}, {id, fromTripStart:11, toTripEnd:null, boostType:'flat', boostValue:3}] | boostType flat\|percentage\|fixed_rate |
| hasWeeklyTargetIncentive / weeklyTargetIncludesInGuarantee | false/false | |
| weeklyTargetTiers | [{id, targetTrips:20, incentiveType:'lump_sum', incentiveValue:50}] | incentiveType lump_sum\|per_trip |
| hasMonthlyTargetIncentive / monthlyTargetIncludesInGuarantee | false/false | |
| monthlyTargetTiers | [{id, targetTrips:100, incentiveType:'lump_sum', incentiveValue:200}] | |
| lock | {by, at} | |

Seed scheme (`DP:51-55`): `ps-std` "Basic + Trips", "Basic pay with 1 trip a day included, topped up to S$2,200", default, basic 500, covers 1 trip/day Mon–Fri, guarantee 2200, on top PH, boost percentage 20, rejection penalty allowed 1, daily volume + weekly + monthly incentives on (default tiers).

Note: the explainer for route bands mentions a per-route "own amount" overriding the band (`EXP:75-83`, "AM4 ... Own amount set") — no such field exists in the scheme; open question.

### 2.4 Calculation — see §8 (engine `DP.simulate`).

---

## 3. Drivers (`paydrv`)

Markup `HTML:9465-9599`; logic `payDrivers` `pay.js:1070-1080`, `payMinD` `1082`, `payFix` `1084-1091`, `payDrvVals` `1095-1200`.

### 3.1 Screen
- Header "Drivers" + How It Works. Intro: "Drivers of your own vehicles, with the pay scheme and vehicle type used to work out their pay. Add drivers or change their details in Vehicles & Attendants" (HTML 9482).
- Empty: "No drivers yet. Drivers come from your own vehicles in Vehicles & Attendants. Operator drivers are paid by their operator, so they are not listed" (HTML 9483).
- Left list: Search (placeholder "Name or plate"); items: name, "Age {n}" (from KYC dob, `Convoy.cpf.age`), sub "{plate|No vehicle} | {scheme today|No pay scheme}"; "No drivers match".
- Right card: photo or initials; name; "{phone|No mobile number} | {plate | vehicle type short | No vehicle}"; **Pay Scheme Today** {name | "No pay scheme today" (orange)}.
- **Pay Scheme Assignments** (HTML 9509-9547): **Assign Scheme** button (adds default scheme from today). Empty text: "No scheme assigned yet, so {name} is paid on the default scheme, {default}". Each row: tag Upcoming / Current / Ended; remove (confirm "Remove this assignment?"); Pay Scheme select; Start Date (date, min = today − 1 month); End Date (optional). Hint: "Start dates can go back up to 1 month, to {date}. A new scheme ends the one before it".
- **Vehicle Types** (HTML 9553-9589): **Assign Vehicle Type** (adds driver's current bus type from today). Empty: "Uses the type of {plate}, {type}. Assign a type to set dates" or "No vehicle type yet". Row: tag, remove ("Remove this assignment?"), Vehicle Type select (enabled types), Start/End date, warning per row. Implicit warning (no assignment): `impWarn`.
- Warning text: "Rate plan {plan} of {scheme} has no rates for {type}, so these jobs are paid S$0" (`pay.js:1137`).
- Tooltips: list "Only drivers of your own vehicles. Invite drivers in Fleet, Drivers"; sch "Pay follows the scheme on each job date, so a change mid-month splits the month between schemes"; veh "The type on each job date picks the rates. Orange warns when the rate plan has no rate for it" (`pay.js:1109-1113`).

### 3.2 Validation
- Start date < min: "Start dates can go back up to 1 month, to {date}" (`pay.js:1151`). Empty start ignored.
- End before start: "The end date is before the start date" (`pay.js:1156`).
- Every change auto-saves (no Save button) with flash: "Start date changed", "End date set"/"End date cleared", "Assignment removed", "Pay scheme changed", "Vehicle type changed", "Pay scheme assigned", "Vehicle type assigned"; audit `['update','driver_assignment', driverName, details]` with details e.g. "Assigned {scheme} from {date}", "Changed a start date to {date}", "Removed the assignment from {date}" (`pay.js:1132-1198`).

### 3.3 Data
`cfg().pay.drv[driverKey] = { sch: [{id, sid, from:'YYYY-MM-DD', to:''|'YYYY-MM-DD'}], veh: [{id, vt, from, to}] }`.
`payFix` (`pay.js:1084-1091`): sorts by `from`, and for each row whose `to` is empty or ≥ next.from sets `to = next.from − 1` (not before own from). So assignments never overlap; the last one may be open-ended.
Active on date d: `act(A, d)` = latest-from row with `from ≤ d ≤ to(or open)` (`pay.js:1107`). Scheme at d: active row's sid; if driver has rows but none active → '' (no scheme); if no rows at all → default scheme.

### 3.4 Reads
- Drivers list = **own vehicles** with a `driverName` (vehicle's operator not a subcontractor), deduped by lower-case name; fields name, phone (`driverContact`), photo (`driverPhoto`), plate, derived vt (by seats) (`pay.js:1070-1080`). Rails: `drivers` + `vehicles` (own) + `vehicle_types`.
- Age: `drvAll()` + `drvKyc(r).dob` (`pay.js:1114-1118`) → Rails `driver_kyc_profiles.date_of_birth`.

---

## 4. Earnings (`payearn`)

Markup `HTML:10117-10290`; logic `payEarnVals` `pay.js:1694-1944`, `payOccTv` `1633-1644`, `payOccStops` `1646-1656`, `payOccMap` `1658-1663`, `payOpenOcc` `1665-1677`, `payStatement` `1679-1692`; issue: `scheduler.js:1411-1431`, dialog HTML 214-226.

### 4.1 Screen
- Header "Earnings" (tip: "Pay is worked out from the Scheduler: only trips that have run with no issue raised count. Confirm each month once every issue is cleared"). Intro HTML 10133: "What each driver has earned this month from the trips on the Scheduler. A trip counts once it has run and no issue is raised on it. Pay follows the driver's pay scheme and rate plan. Confirm the month once it has ended and every issue is cleared".
- Top card: **Month** select (current + 11 previous months, label "October 2026"), **Search** ("Driver or plate"); totals: **Completed Trips** Σ, **Held** Σ, **Pay This Month** Σ totals, **Confirmed** "{n} of {m} confirmed" (`pay.js:1797`).
- Empty: "No own drivers yet. Add drivers in Fleet, Drivers and set them on a vehicle".
- Driver list: name, amount, sub "{plate} | {n} trip(s) | {held} held", status badge: **Confirmed** (success) / **Held** (danger, has issue rows) / **To Confirm** (warning, month ended) / **Open** (neutral) (`pay.js:1789-1796`).
- **Trips This Month** card: count; empty "No trips on the Scheduler for this driver in this month"; each row: title, trip value (or "{h} h" for disposal = (e−s)/60 rounded to 0.25), "{date} | HH:MM to HH:MM", "{kind} | {plate}", status badge (Completed ✓ success, Issue Raised flag danger, Running bus info, Upcoming schedule neutral, Cancelled block neutral), pay line (intended; see bug Q20), issue text "{why} | {by}, {date}", action **Raise an Issue** / **Clear Issue** (only when month not confirmed and status Completed/Issue Raised). Trip ID hover card: tid | kind, status, title, date/time, "plate | driver", "{pax} seats", OneMap static image of stops, up to 6 stops (n, name, time) "and {n} more stops", "Click the Trip ID to open the trip" → opens Scheduler day view on that occurrence.
- Selected driver card: "{name} | {plate}", total, sub "Confirmed by {by} on {date}" / "Live from {n} completed trip(s)" / "No pay scheme", scheme "{scheme} | {plan}"; stacked bar chart (same as simulator, without bonuses) with guarantee line; KPIs Completed / Held / Cancelled / Upcoming; breakdown rows `sim.rows`; reason text `why`; buttons **Export Statement** (print), **Confirm Month** (disabled unless allowed), **Reopen Month**.
- Raise an Issue dialog (HTML 214-226): title "Raise an Issue", "Driver pay for this trip is held until the issue is cleared", Textarea "What is the issue" placeholder "e.g. Trip ran 40 minutes late, client complaint"; Cancel / **Raise Issue** (disabled until non-blank). Flash "Issue raised. Driver pay for this trip is held" / "Issue cleared" (`scheduler.js:1411-1419`). Clearing has no confirm.

### 4.2 Rules
- **Rows** (`pay.js:1717-1747`): every occurrence in month (`memoTrips(a, z)`), skip ghosts (replaced) and unassigned; vehicle must be **own** (`vType(v) === 'own'`); driver = `schDrv(v, date, key)` (replacement driver / per-trip driver override / temporary driver / regular driver, `scheduler.js:503-530`); grouped by lower-case driver name. Drivers listed even with 0 rows.
- **Status** (`pay.js:1728`): cancelled → Cancelled; `schSt` 'done' (ended, or date past, or today after end) → Issue Raised if `sched.iss[key]` else Completed; 'live' → Running; else Upcoming (`scheduler.js:544-551`).
- **Pay** (`pay.js:1749-1772`): scheme = assignment active on **last day of month** else default (if no assignments); plan = scheme.baseRatePlanId; vt = vehicle-type assignment active on last day else driver's bus type. Jobs = Completed rows only: disposal (kind 'Disposal') → `{type:'disposal', startTime, endTime}`; else `{type:'trip', startTime, tv: payOccTv(x)}`. Then `DP.simulate({scheme, plan, vt, ph: SGPH, ym, jobs})` — **no routes, no rejected count, no bonuses**. Total = confirmed snapshot total if confirmed else sim.total.
- **Trip value** `payOccTv` (`pay.js:1633-1644`): `t.tv` (default 1); return-direction runs (`rk` starts with `d2`) use `t.tv2` (default tv); Corporate Shuttle with `tvPer === 'day'`: value ÷ number of runs in that direction, rounded to 0.001.
- **PH**: `this.SGPH` = `calCtx().ph` (date → holiday name) from the company Public Holidays calendar (`HTML:18128`).
- **Confirm Month** allowed when month ended (ym < current month) AND not confirmed AND no held rows AND scheme exists (`pay.js:1914`). Reasons shown (`why`): "No pay scheme assigned. Pick one in Drivers"; "The month can be confirmed from {1st of next month}"; "{n} trip has/trips have an issue raised. Clear them first". Confirm text: `Confirm {Month YYYY} for {driver} at {S$x}? The amount is recorded and the month is locked`. Saves `earn["key|ym"] = {total, n: completedCount, by, at: today, keys: [completed occurrence keys]}`; audit `['update','driver_pay', name, 'Confirmed {ym} at {S$} from {n} trips']`; flash "{Month} confirmed for {driver}".
- **Reopen Month**: admin only ("Only an Admin can reopen a confirmed month"); confirm `Reopen {Month YYYY} for {driver}?`; deletes the record; audit "Reopened {ym}".
- After confirmation, issue actions are hidden, but status of rows can still change (e.g. issue cleared elsewhere in Scheduler); confirmed total is frozen.
- **Export Statement** (`pay.js:1679-1692`): printable HTML — header "Earnings Statement", driver name | plate, "scheme | plan", company name, month, status "Confirmed by X on D" / "Provisional, not yet confirmed"; "Pay Breakdown" table (sim rows) + "Total for {month}"; "Trips (n)" table Date/time, Trip ID, Trip (title, kind, line, issue), Value, Status; footer "Only trips that have run with no issue raised are paid. Cancelled, skipped and upcoming trips earn nothing. Printed {date} from Convoy." Popup blocked flash "Allow pop-ups to export the statement". Comment says Driver app will show the same statement later.

### 4.3 Reads (fields)
Occurrence: `key, d (date), s, e (minutes), vid, title, kind, sub, tid (Trip ID), pax, cancel, ghost, ended, rk (run key), t (trip: tv, tv2, tvPer, kind, sched, pickup, dropoff, stops), src 'route', r.stops, pl.session, stp`. Vehicle: `plate, driverName, operator`. Scheduler cfg: `iss`, `rep` (replacements), `drv` (per-trip driver), `tmpDrv`. School: name/short/lat/lng (route stops). Geocode cache for stop pins.
Rails equivalents: `trip_occurrences` (date, start_time, end_time, kind, trip_label, vehicle_id, driver_id, driver_name, status, cancelled_at, ended_at, issue_reason/raised_at/raised_by_id, trip_value, replacement_id, school_route_id, pax), `replacements.pay_split/original_share`, `public_holidays`.

---

## 5. Bonuses (`paybon`)

Markup `HTML:9601-9910`; logic `payPeriods` `pay.js:1202-1248`, `payBonBlank` `1250-1273`, `payBonVals` `1275-1467`; simulator evaluation `pay.js:602-669`.

### 5.1 Screen
- Header "Bonuses" + HIW; dirty Cancel / Save and Lock / Save; clean Unlock / Lock / **Add Bonus**. Lock banner. Intro: "Bonuses on top of pay schemes, for trip targets, on-time performance or attendance over a period. Lock a bonus once it is announced to drivers" (HTML 9621). Empty "No bonuses yet. Add one to start".
- List: name ("Untitled Bonus"), sub "{Type} | {Frequency} | {Upcoming|Running|Ended} | Locked | Not saved".
- **Bonus Details**: Delete Bonus; type cards: **Trip Target** "Reach a number of trips" (`trip_target`), **On-Time Performance** "Keep on-time within a range" (`reliability_otp`), **Attendance** "Turn up for every working day" (`reliability_attendance`); Bonus Name (placeholder "e.g. Year-End Trip Bonus"); Description (optional).
- **Period**: Frequency pills Daily / Weekly / Monthly / Quarterly / Half Yearly / Yearly (reliability types: only Monthly+). Hint: "On-time and attendance bonuses run monthly or longer" / "Weekly periods start on Mondays". Daily: First Day / Last Day (optional) dates; else First Period / Last Period selects from `payPeriods` (Last includes "No end date"). Text `perTxt`: "Runs from {start} to {end of last period}. Status: {st}" / "Runs from {start} with no end date. Status: {st}".
- **Payout Timing** pills: daily/weekly → **Next Payroll** (`next_payroll_cycle`), else **End of Period** (`end_of_period`); **Months Later** (`x_months_later`) with Delay (Months); **Split Payments** (`split_trenches`) list "Payment n": Share (%) and "Months After Period Ends" (first) / "Months After Payment {n-1}"; Add Payment (pct = 100 − sum); "Adds up to 100%" / "Adds up to {x}%. Must add up to 100%" (orange). Text `payTxt` (`pay.js:1401`).
- **Who Can Join**: Eligible Pay Schemes chips "All Schemes" + each scheme (empty selection → ALL); Specific Drivers chips (optional) — "Only the picked drivers can join" / "No drivers picked, so every driver on an eligible scheme can join"; Switch **Drivers Must Sign Up** — "Drivers accept the terms in the driver app before the bonus counts"; Sign-Up Opens / Closes dates; Terms and Conditions (textarea); Signed Up chips (tick by hand) "{n} signed up. Drivers sign up in the driver app. Tick a driver to sign them up by hand".
- **When the Scheme Also Pays** (daily/weekly/monthly only): Bonus Adds (`additive`) / Bonus Supersedes (`supercede`) / Scheme Prevails (`prevail`), stored per frequency; text `ovlTxt` (`pay.js:1437`).
- **Tiers**: Add Tier; each "Tier n": Trip types → Target (Trips), Pay As (Lump Sum `lump_sum` / Per Trip `rate_increase`), Amount (S$ or "S$ per trip"); reliability → From % / To %, Amount (lump sum only); Points (optional, pts). Hint "Trips needed in each period for each tier. The highest tier reached is paid" / "The percentage range for each tier. The highest tier reached is paid".
- **Excluded Days** (Attendance only): Add Period; each Name (placeholder "e.g. Year-end shutdown"), From, To; empty "No excluded days. Add school holidays or leave periods that should not count".
- Tooltips with meanings `pay.js:1305-1313`.

### 5.2 Validation (verbatim, `pay.js:1326-1339`)
"Enter a bonus name"; "Add at least one tier"; "The split payments add up to {sm}%. They must add up to 100%"; "Set the sign-up dates"; "Sign-up ends before it starts"; "The last period is before the first". Delete: locked msg; confirm `Delete {name}?`. Numbers coerced.
Type switch to reliability while daily/weekly → frequency monthly, start = first monthly period ≥ today, end cleared, payout next_payroll→end_of_period (`pay.js:1370-1378`). Frequency change resets start to first period of that kind and end to '' and toggles payout between next_payroll_cycle/end_of_period (`pay.js:1380-1391`). Start change clears end if end < start.

### 5.3 Data (defaults `payBonBlank`, `pay.js:1250-1273`)
```
{ id:'cb-xxx', planType:'trip_target'|'reliability_otp'|'reliability_attendance', name, description,
  frequency:'daily'|'weekly'|'monthly'|'quarterly'|'half_yearly'|'yearly' (default monthly),
  startDate: 1st of next month (period start value), endDate: '' (start of LAST period, not end date),
  payoutScheduleType:'end_of_period'|'next_payroll_cycle'|'x_months_later'|'split_trenches', payoutDelayMonths:1,
  payoutTrenches:[{percentage:50, delayMonthsRelative:1},{percentage:50, delayMonthsRelative:3}],
  requiresSignUp:false, signUpStartDate:'', signUpEndDate:'', termsAndConditions:'', signedUpDriverIds:[driverKey],
  excludedAttendancePeriods:[{id, name, startDate, endDate}], eligibleSchemeIds:['ALL'] | [schemeId], eligibleDriverIds:[driverKey],
  tiers:[{id, targetTrips:120, targetMetricMin:95, targetMetricMax:100, incentiveType:'lump_sum'|'rate_increase', incentiveValue:100, pointsValue:''}],
  deconflictionRules:{daily:'additive', weekly:'additive', monthly:'additive'}, lock?:{by,at} }
```
Period end `endOf(b)` (`pay.js:1293-1303`): daily → endDate; weekly → endDate + 6; monthly/quarterly/half/yearly → last day of the month n−1 months after endDate (n = 1/3/6/12). Status: startDate > today → Upcoming; endOf < today → Ended; else Running.
Period options `payPeriods` (`pay.js:1202-1248`): weekly 40 Mondays from 4 weeks before this week ("Week of Mon {date}"); monthly prev month + 24 ("Oct 2026"); quarterly 12 ("Q4 2026, Oct to Dec"); half-yearly 8 ("H2 2026, Jul to Dec"); yearly 6.

### 5.4 Calculation (simulator only, `pay.js:602-669`)
- Eligible bonuses for the month: `eligibleSchemeIds` includes ALL or the scheme, and bonus range overlaps the month (`pay.js:620`). Driver eligibility / sign-up not checked (text "Assumes the driver signed up").
- `tierFor` (`pay.js:622`): trip_target → highest `targetTrips ≤ x`; reliability → tier with `targetMetricMin ≤ x ≤ targetMetricMax`, highest min.
- `payT` (`pay.js:623`): trip_target & rate_increase → `incentiveValue × x` (x = trips in period); else `incentiveValue`. Points += `pointsValue` per hit.
- trip_target daily: each day in range, x = trips that day (simulated trips incl. trip values) → hit per day ("{hits} of {per} days reached a tier"). weekly: Mon–Sun weeks, evaluated on Sundays in range ("full weeks"). monthly: trips in range for trip_target, else OTP % or attendance % entered (default 100). quarterly+: not computed.
- Deconfliction (`pay.js:654-655`): if bonus amt > 0 and scheme incentive of same frequency (daily → dInc, weekly → wInc, monthly → mInc) > 0: `prevail` → amt = pts = 0; `supercede` → adj = −schemeIncentive (bonus replaces it); `additive` → both.
- Payout (`pay.js:656`): `end_of_period`/`next_payroll_cycle` → paid this month (added to total as `amt + adj`); `x_months_later` → "Paid {n} months after the period"; `split_trenches` → "Paid later in {n} parts" — listed but not added ("in bonuses paid in later months").

---

## 6. Points (`paypts`)

Markup `HTML:9913-10026`; logic `payPtsVals` `pay.js:1469-1539`.

### 6.1 Screen
- Header "Points" + HIW. Intro "Driver points from bonuses and manual awards. Points last 24 months and are redeemed for rewards". Empty "No drivers yet. Drivers come from your own vehicles in Vehicles & Attendants".
- List of drivers (same source as Drivers): name, plate, "{balance} pts".
- **Balance** card: name, balance pts; Earned / Used / Expired; `soonTxt` "{n} points expire in the next 60 days" (orange) / "No points expire in the next 60 days".
- **Adjust Points**: pills Award / Deduct; Points (number, pts); Reason (placeholder "e.g. Good conduct, Nov 2026"); button **Award Points** / **Deduct Points**; hint "Awarded points expire after 24 months" / "Deducted points come off the balance now, up to {balance}".
- **History** (newest first): "+n"/"−n" (struck-through if expired), reason, meta "{date} | {by} | Expires/Expired {exp}", status Active / Used / Expired. Empty "No points yet".

### 6.2 Validation (`pay.js:1494-1511`)
"Enter the number of points" (must be > 0, rounded); "Enter a reason"; deduct > balance: "{name} has only {b} points". Flash "Awarded {n} points" / "Deducted {n} points". Audit `['award'|'deduct','points', driverName, 'Awarded {n} points: {reason}']`. No edit/delete of entries.

### 6.3 Data & rules
`{ id:'pt-xxx', dk: driverKey, pts: +n|−n, desc: reason, date: today, exp: today + 2 years (award only, '' for deduct), status: 'active'|'used', by }`.
- expired(r) = pts > 0 and (status 'expired' or exp < today).
- balance = Σ(negative pts) + Σ(positive non-expired pts) (`pay.js:1478`).
- earned = Σ positive; used = −Σ negative; expired = Σ expired positive; expiring soon = positive non-expired with exp ≤ today+60.
- Points from bonus tiers are **not** credited automatically (only shown in simulator).

---

## 7. Rewards (`payrew`)

Markup `HTML:10028-10115`; logic `payRewVals` `pay.js:1541-1631`.

### 7.1 Screen
- Header "Rewards" + HIW; dirty: Cancel / Save; clean: **Add Reward** (no lock). Intro "Rewards drivers redeem with their points. Only active rewards show in the driver app". Empty "No rewards yet. Add one to start".
- List: photo thumbnail, title ("Untitled Reward"), "{points} pts | Active/Inactive | Not saved".
- Editor: Delete Reward; photo drop zone "Drop a photo here", **Upload Photo** (accept png/jpeg/webp), **Remove Photo**, "JPEG, PNG or WebP, under 2 MB"; Title (placeholder "e.g. S$50 NTUC Voucher"); Description (textarea); Points Needed (pts); Status pills Active / Inactive; text "Drivers can see and redeem this reward in the driver app" / "Hidden from drivers".

### 7.2 Validation
"Enter a reward title"; "Enter the points needed" (> 0, rounded); photo: "Use a JPEG, PNG or WebP image"; "The image must be under 2 MB". Photo is resized to max 480 px and stored as JPEG data URL (q 0.86) inline (`pay.js:1593-1613`) → Rails: CarrierWave uploader. Delete confirm `Delete {title}?`. Audit create/update "Created the reward, {pts} points, active|inactive"; delete.

### 7.3 Data
`{ id:'rw-xxx', title, description, photo (data URL), pointsRequired: 500 default, status: 'active'|'inactive' (default inactive) }`. No stock/quantity, no redemption entity.

---

## 8. Salary Simulator (`paysim`) and the pay engine

Markup `HTML:9127-9462`; logic `paySimVals` `pay.js:392-856`; engine `DP.simulate` `DP:67-124`, `sampleJobs` `DP:56-65`, `inSched` `DP:23`.

### 8.1 Screen
- Header "Salary Simulator" + HIW; **Templates** (bookmarks), **Clear Month**, **Fill Sample Month** (auto_awesome). Intro "Try a pay scheme on a made-up month. Nothing here changes drivers, trips or pay. Pick a day to add trips and disposal jobs". Empty "Add a pay scheme first".
- Inputs: Pay Scheme select; Vehicle Type select (types of the scheme's plan); Month prev/next; Rejected Jobs (number); when any eligible reliability bonus: On-Time Performance (%) and Attendance (%) (placeholder 100). Plan warning: "This scheme has no rate plan, so jobs are paid S$0. Pick one in Pay Schemes" / "The rate plan has no vehicle types. Add them in Rate Plans".
- **School Routes**: Add Route (names AM1/PM1/AM2..., 45 min, start 06:30 AM / 14:30 PM); each: Route (placeholder "e.g. AM1"), Starts (time), Length (Min), amount "{S$}/ mo" from bands or "Paid per trip"; empty "No school routes. Add the routes this driver is regular on". **School Holidays** From / To (optional dates). Note `rtNote` (`pay.js:576`) + ". Leave School Holidays empty if school is open all month".
- Calendar: weekday header Mon..Sun; cells: day number, "On top" badge, PH name, "{n} trips | {h} h", day pay; PH cells orange, weekends grey. Empty month: "No jobs this month. Fill a sample month, or pick a day and add jobs".
- Selected day: title "{Wed} {4} {Nov} | {PH name}"; Add Trip (start = last job end + 60 min, default 08:00, max 23:00, tv 1) / Add Disposal (4 h); job rows: Trip (start time, Trip Value number step 0.25 min 0) or Disposal (start – end); remove. "No jobs on this day". Breakdown table Time | Pay | Amount (lines from engine), Day Total, "Month so far: {S$}. This day is paid on top of the guarantee".
- Right panel: scheme name, total, "{Month} | {vehicle type}"; stacked bar chart with guarantee line and hover card; groups (Fixed Pay; Trips and Jobs; Incentives; Bonuses — or with guarantee: Counts Towards Guarantee; Guarantee Top-Up (Guaranteed Pay, Pay That Counts with % bar, Top-Up Paid); Paid on Top of Guarantee) with expandable lines (trips by rate, hours by rate, weeks vs target, routes); **Total Pay**; **Bonuses** list (name, sub, amount, +pts) + "{n} points earned. {S$} in bonuses paid in later months"; note "Guarantee {S$}. Trips on ... are paid on top" / "Rejection penalty triggered, so the guarantee does not apply this month" (`pay.js:686-856`).
- **Test Templates** dialog (HTML 9128-9165): "Saved months for testing pay schemes. {n} of 5 used"; 5 slots "Template n": name, desc ("No description"), meta "{Mon YYYY} | {n} days with jobs, {n} routes | Saved by {by} on {date}"; Delete (confirm `Delete template {name}?`), **Save Over**, **Load** (flash "Loaded {name}"), empty → **Save Current Month**. Edit form: title "Save as Template n" / "Save Over Template n"; sub "Saves {Mon YYYY} as it is now: jobs, school routes, school holidays, pay scheme and vehicle type[. This replaces what is saved in this slot]"; Template Name (placeholder "e.g. Busy month with 2 school routes", required: "Give the template a name"); Description (optional textarea, placeholder "What this tests, e.g. a PH week, 1 rejection and a short PM route"); Cancel / Save Template. Footer "Templates are shared with everyone who can use the Salary Simulator. Loading one opens its month and replaces the jobs in that month only".

### 8.2 Data
- Working state (per browser) localStorage `convoy.paysim.v1`: `{sid, vt, ym, rej, otp, att, routes:[{id,name,min,start}], rtN, rtMin (legacy), holF, holT, jobs:{date:[{id,type:'trip'|'disposal',startTime,endTime?,tv?}]}, day}` (`pay.js:393-398`).
- Shared templates `cfg().pay.simTpl` (array of 5, null = empty): `{name, desc, ym, sid, vt, rej, otp, att, routes, holF, holT, jobs (that month only), by, at}` (`pay.js:469-493`). Saves/deletes not audited.
- Sample month `DP.sampleJobs(ym, ph)` (`DP:56-65`): weekdays trips 06:00, 07:00 (tv 1.5 on Wednesdays), 13:00, 15:00, 16:00; first weekday + disposal 17:00–23:00; first Sat and first Sun disposal 08:00–15:00; PH weekdays 2 trips 07:00 and 13:00. **Sample/demo data.**

### 8.3 Engine `DP.simulate(o)` — exact rules (`DP:67-124`)
Inputs: scheme S, plan P, vt, ph map, ym, jobs {date: [job]}, rejected, routes {list:[{min,start}], hol:[from,to]}.

Setup (`DP:68-77`):
- `T = S.schemeType`; `pen = hasRejectionPenalty && rejected > rejectionPenaltyAllowedJobs`; `inc = !pen || rejectionPenaltyKeepsIncentives !== false` (incentives allowed).
- `base` = Basic+Trips: basicSalary; else if pen: rejectionPenaltyFallbackBasic; Monthly: monthlyPayAmount; Shift: shiftSalary.
- `G = guaranteedAmount`; `hasG = T==='basic_plus_trips' && hasGuarantee && !pen`.
- `isExc(d)` (paid on top) = hasG && ((onTop.ph && PH) || (onTop.sat && Sat) || (onTop.sun && Sun)).
- `fb = pen && T !== 'basic_plus_trips'` (fallback: no coverage, no shift).
- `shiftOn(d, mins)` = Shift && !fb && !PH && weekday in shiftWorkingDays && shiftStart ≤ mins < shiftEnd.
- Route bands sorted by `to` (''→∞); route amount = first band with `min ≤ to`; `rtAmt` = average band amount over routes; `rtN` = number of routes.
- Without retainer (`!schoolRoutesPay`): each weekday, non-PH, non-school-holiday date gets a synthetic trip per route at its start time (tv 1, `route:true`) (`DP:76`).

Coverage available `avail(d, dayCount)` (`DP:79-82`):
- fb → 0.
- Basic+Trips: if basicCoversDailyTrips and `inSched(d, basicCoveredSchedule, ph, J, basicCoverPH)` → max(0, basicCoveredDailyTrips − dayCount) else 0.
- Monthly: `monthly` → max(0, monthlyTripsCommitment − gCount (month cumulative)); `daily` → on schedule days max(0, monthlyDailyTripsCommitment − dayCount) else 0.
- Shift → 0 (coverage via shiftOn).

`inSched(d, sc, ph, J, incPH)` (`DP:23`): PH and !incPH → false; Mon–Fri always true; `all-days` true; `mon-sat` Sat; `mon-fri-sun` Sun; `6-days`: Sat true, Sun true only if the previous day (Sat) was PH or had no jobs.

Post-guarantee boost `pgBoost(amt, units, curBasis)` (`DP:83-84`): 0 unless inc && hasPostGuaranteeBoost && hasG && curBasis ≥ G && units > 0; percentage → amt × v/100; flat → v × units; fixed_rate → max(0, v × units − amt).

Per day (`DP:85-117`), jobs sorted by start:
- Mondays reset weekly count; week start = Monday or first date.
- **School routes with retainer or counted in holidays** (`DP:88-89`): on weekdays non-PH, `nC` = rtN if retainer && (schoolRoutesCount || school day); or (no retainer) && holiday && schoolRoutesCount. These count as trips (dayCount, trips, wTrips, gCount), consume coverage `c0 = min(nC, avail(d,0))`, pay S$0 per trip (paid by retainer or not paid in holidays).
- Disposal jobs are split into hour steps from start (`DP:91`): end ≤ start → +1440 (overnight); steps of 60 min, last step partial.
- **Trip** (`DP:95-104`): `tv` (default 1, ≥0); period by start time; `rate = period.rates[vt].trip`; covered `c = shiftOn ? tv : min(tv, avail(d, dayCount))`; `pay = tv − c`; `core = rate × pay`.
  - Daily volume (inc && enabled && pay > 0): trip number `n = floor(dayCount) + 1` (counts covered trips, routes, disposal-hours-as-trips); tier where `from ≤ n ≤ to` (to empty = open): flat → value × pay; percentage → rate × value/100 × pay; fixed_rate → max(0, (value − rate) × pay).
  - `pg = pgBoost(core + vol, pay, basis + dayBasis)`; `amt = core + vol + pg`.
  - On exempt (on-top) day: amt goes to `onTop`; else `dayBasis += core + (dailyVolumeIncludesInGuarantee ? vol : 0)`.
  - Counters: dayCount, trips, wTrips, gCount += tv.
- **Disposal hour step** (`DP:105-110`): rate = Shift && !fb && shiftOvertimePayType 'hourly_rate' → shiftOvertimeHourlyRate, else period hourly rate at step start (`step` hours); covered: inside shift → whole step; else if disposalCountsAsTrips && not shift → `min(step, avail)` and dayCount/gCount += c; pay = step − c; core = rate × pay; pg boost; no daily volume on disposal; exempt-day / basis as trips. Consecutive steps with same period/rate/coverage are merged into one display line.
- **Weekly target** (`DP:112-113`): on Sunday, only if the week started on a Monday in this month; highest tier with `wTrips ≥ targetTrips`; lump_sum → value; per_trip → wTrips × value; adds to `dayBasis` if weeklyTargetIncludesInGuarantee.
- **Monthly target** (`DP:114-115`): on last day; highest tier `trips ≥ target`; same lump/per-trip; basis if monthlyTargetIncludesInGuarantee.
- `basis` (starts at base) += dayBasis; day record `{lines, sub, cum, trips, ex, ph}`.

Month end (`DP:118`):
```js
const rtPay = S.schoolRoutesPay ? rtN * rtAmt : 0; if (S.schoolRoutesInG !== false) basis += rtPay;
const topUp = hasG && basis < G ? G - basis : 0,
      total = base + rtPay + tripPay + dispPay + dInc + wInc + mInc + pgInc + topUp;
```
Breakdown rows (`DP:119-122`): Basic Salary / Fallback Basic Salary / Monthly Pay / Shift Salary; Trips Counted; Included in Base Pay; School Route Pay "{S$}, n x {S$}"; Trip Pay; Disposal Hours; Disposal Pay; Daily Volume Incentives; Weekly Target Incentives; Monthly Target Incentives; After-Guarantee Boost; Counted Towards Guarantee "{basis} of {G}"; Paid on Top of Guarantee; Guarantee Top-Up; Rejection Penalty "Triggered. No guarantee | Paid as Basic + Trips, incentives kept | no incentives".
Output also: tripBy/dispBy (units by rate, counted vs on-top), weeks[], months[], days{}, periodStats, rounding to cents `r2`.

Shift salary note: total always includes full `base` regardless of days worked (no proration).

Bonuses on top of simulator total: see §5.4; displayed total = `Rs.total + bNow` (`pay.js:846`).

### 8.4 Reads
Schemes, plans, vehicle types, public holidays (`SGPH`), bonuses (`cfg().pay.bon`), user name.

---

## 9. Audit Log (`paylog`)

Markup `HTML:10292-10335`; logic `payLogVals` `pay.js:1946-2004`; writer `paySave` `pay.js:9-23`.

- Header "Audit Log" (tip "Locks, unlocks and every points change are recorded too, with the time to the minute") + HIW. Intro "Every change to rate plans, pay schemes, bonuses, driver assignments, points and rewards, with who made it and when. Entries cannot be edited".
- Filters: Search ("Name, user or detail" over user/name/details); Action select: All Actions, Created, Updated, Deleted, Locked, Unlocked, Awarded, Deducted; Item select: All Items, Rate Plan, Pay Scheme, Bonus, Points, Reward, Driver.
- Table columns When (date + HH:MM local) | Who | Action (coloured chip) | Item (type label + name) | Details. Count "{n} change(s)[, newest 300 shown]". Empty "No changes match these filters" / "No changes yet. Changes to pay, bonuses, points and rewards show here".
- Entry `{id:'lg-xxx', at: ISO timestamp, user, action: create|update|delete|lock|unlock|award|deduct, type: rate_plan|pay_scheme|campaign_bonus|points|reward|driver_assignment|driver_pay, name, details}`; kept last 500 (`slice(-499)` then push).
- Writers: rate plan create/update/delete/lock/unlock; scheme same; bonus same; driver_assignment updates; points award/deduct; reward create/update/delete; earnings confirm/reopen (`driver_pay`). Not logged: simulator templates, trip issues (stored in Scheduler cfg).

---

## 10. Cross-area reads summary

| Source | Fields | Used by |
|---|---|---|
| Vehicles (own, `sa.vehicles`) | id, plate, seats, driverName, driverContact, driverPhoto, operatorId/operator | Drivers list, Points list, Bonus driver chips, Earnings |
| Operators (`cfg().subcons`) | id, name, kind | exclude operator drivers (`pay.js:1074`) |
| Vehicle types (`schVT`) | value, nm, short, seats, off | plan rates, driver vt assignment |
| Driver KYC (`drvAll`, `drvKyc`) | dob (age), res (CPF only in Vehicle Financials) | Drivers age |
| Public holidays (`calCtx().ph`) | date → name | rate period 'ph', coverage, on-top, shift, sample month |
| Scheduler occurrences (`memoTrips`) | see §4.3 | Earnings |
| Scheduler cfg | `iss`, `rep`, `drv`, `tmpDrv`, `cancel` | Earnings status/driver |
| Trip | tv, tv2, tvPer, kind, sched (runs), stops | trip value |
| School (`D.school`) | name/short, lat/lng | route stops on hover |
| Company (`saSess.company.name`) | name | statement header |

Consumers of HR data elsewhere: Vehicle Financials `vfDrvCost` (`logic/mixins/fleet.js:322-351`) — driver salary per vehicle month = `simulate(scheme, plan, vt '', ph, ym, jobs {})` total (i.e. fixed pay + top-up only, no trips) × share of days the driver was on the vehicle; plus employer CPF via `Convoy.cpf.employer(wage, dob, ym, residency)` (`logic/cpf.js:18`: Citizens/PR only; wage ≤ 50 → 0; rate by age band, capped at OW ceiling 7,400 (2025) / 8,000 (2026); bands 55-, 55–60, 60–65, 65–70, 70+ = 17/16/12.5/9/7.5% for 2026). Scheme picked at first of month there.

## 11. Sample / demo / not-real markers
- Seeded rate plan + scheme until first save (`HTML:18185-18193`; `DP:25-55`).
- `DP.sampleJobs` "Fill Sample Month" (`DP:56-65`).
- Driver KYC fabricated when missing (`fleet.js:1887-1899`) → ages shown on Drivers page may be fake.
- Driver app parts not built: bonus sign-up, T&C acceptance, rewards display/redeem, earnings statement ("the Driver app will show the same statement later", `pay.js:1678`), job rejection tracking, marking trips completed (TODO.md:73).
- Simulator is explicitly non-real ("Nothing here changes drivers, trips or pay", HTML 9192).
- How It Works stepper content (`pay.js:890-994`) and ⓘ explainer animations (`param-explainers-hr.js`) are UI-only; explainer examples (Eric Pang, S$ amounts, "own amount" per route) are illustrative.
