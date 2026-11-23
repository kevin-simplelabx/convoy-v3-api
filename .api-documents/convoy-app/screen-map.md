# Convoy App — Screen map

Every screen, sheet and button of `Convoy App.dc.html` and the call behind it. Paths start with `/api/v1/app`. The HTML
page id is in brackets after each heading (`v.<page>` in the prototype).

- **FE only**: the app does it alone (navigation, a phone feature, a static text, a map control); no call.
- **Not built**: no API. Either decided not to build (Coming Soon in the HTML, or the user's decision: see the list at
  the end), or **Phase 4b** (Bus Not Required, School Calendar, Contact + Report an Issue, Stop Photos), which is planned
  and not built yet: hide those buttons, or show them as Coming Soon, until their API is announced.

## Sign in (`signin`, `otp`)

| Screen / button | Call | Doc |
| --- | --- | --- |
| Mobile / Email toggle, the format checks (8 digits from 8 or 9, an email) | FE only (the server checks again: `422`) | [auth § 1](auth.md#1-send-the-code-post-appsessioncode) |
| Sign In: mobile or email → Continue (Resend) | `POST /app/session/code` | [auth § 1](auth.md#1-send-the-code-post-appsessioncode) |
| One-Time Code (code `123456` for now) | `POST /app/session` | [auth § 2](auth.md#2-sign-in-with-the-code-post-appsession) |
| App start (who am I, signed out?) | `GET /app/session` | [auth § 3.1](auth.md#3-the-session-and-sign-out) |
| After sign-in: `account.profile_complete` false → Create Your Account, true → Home | the sign-in answer | [auth § 2](auth.md#2-sign-in-with-the-code-post-appsession) |
| Any `403 profile_required` | back to Create Your Account | [auth § 5](auth.md#5-profile_required) |
| `429` on a code step | disable Resend for `details.retry_after` | [auth § 6](auth.md#6-codes-and-rate-limits) |
| Sign Out | `DELETE /app/session` | [auth § 3.2](auth.md#3-the-session-and-sign-out) |
| Push token (after sign-in, new token), Turn off on this phone | `PATCH /app/device`, `DELETE /app/device` | [auth § 4](auth.md#4-several-phones-and-the-push-token) |
| Scan (top right) → Child Login (`scan`) | **Not built** (Child Login) | — |

## Create Your Account (`setup`)

| Screen / button | Call | Doc |
| --- | --- | --- |
| First Name, Last Name, Show My Name As, Terms → Create Account | `PATCH /app/profile { profile: { ... accept_terms: true } }` | [account § 1](account.md#1-create-your-account-patch-appprofile) |
| Second mobile / email ("For invoices and receipts") | the Mobile and Emails calls below (verified by code) | [account § 4](account.md#4-mobile-and-emails) |

## Home (`home`)

| Screen / button | Call | Doc |
| --- | --- | --- |
| Greeting, invitation cards, notice banners, Up Next, tiles (+ badges), Get Started, Alerts tab badge | `GET /app/home` | [home § 1](home.md#1-home-get-apphome) |
| Family invite Accept / Not Me | `POST /app/household/invitations/:id/accept` / `decline` | [household § 5.5](household.md#55-accept--not-me) |
| Employer / school invite Accept / Not Me | `POST /app/organisations/:kind/:id/accept` / `decline` | [organisations § 4](organisations.md#4-accept--not-me) |
| Notice banner X | `POST /app/home/banners/:id/dismiss` | [home § 2](home.md#2-notice-banners-and-dismiss) |
| Notice banner button (Track the Bus, Open, See School Calendar) | `action.target` → Live / route / booking (School Calendar: Not built, 4b) | [home § 2](home.md#2-notice-banners-and-dismiss) |
| Notices expand / collapse, carousel dots | FE only | — |
| Up Next card tap | `open.kind` → Live, Bus Information, route, Usual Shuttle, booking, Track Buses, New Booking | [home § 1](home.md#1-home-get-apphome) |
| Up Next "Add a Child" (Family without children) | Household › Add a Child | [household § 4.1](household.md#41-add-a-child-post-apphouseholddependants) |
| Get Started: Book a Bus / School Bus for a Child / Staff Shuttle | FE only: Bookings, Set Up Your Family, Mobile and Emails with Add Work Email open | [home § 1](home.md#1-home-get-apphome) |
| Tile School Bus (Family) / (no Family) | School Bus page / Set Up Your Family | [school § 2](school.md#2-school-bus-page-get-appschool) |
| Tile Shuttles (linked) / (not linked) → sheet `link` "Shuttles Come From Your Employer" | Shuttles / sheet: FE only (Add Work Email, Suggest Convoy) | [shuttles § 1](shuttles.md#1-who-sees-what) |
| Tile Bookings | Bookings | [bookings § 2](bookings.md#2-list-get-appbookings) |
| Tile Discover, Discover banners (sponsored) | **Not built** (Coming Soon) | [home § 1](home.md#1-home-get-apphome) |
| Home › School Bus section (children, quick actions) | `GET /app/school` | [school § 2](school.md#2-school-bus-page-get-appschool) |
| Home › CCA Bus card | `GET /app/school` → `cca` | [fees § 8](fees.md#8-home-card-and-badges) |

## Activity (`activity`)

| Screen / button | Call | Doc |
| --- | --- | --- |
| Chips School Bus / Shuttles / Bookings, Now, Upcoming, Past | `GET /app/activity?service=` | [home § 3](home.md#3-activity-get-appactivity) |
| Tap a row | `open` → Live, Bus Information, route, booking, Track Buses | [home § 3](home.md#3-activity-get-appactivity) |
| Empty "No trips yet" → Book a Bus | FE only (Bookings › New) | — |

## Alerts (`alerts`)

| Screen / button | Call | Doc |
| --- | --- | --- |
| All / Delays / Notices, Today / Earlier, unread count | `GET /app/alerts?filter=&page=` | [home § 4](home.md#4-alerts-tab-inbox) |
| Tap an alert (marks read, opens `target`) | `POST /app/alerts/:id/read` | [home § 4](home.md#4-alerts-tab-inbox) |
| Mark All Read | `POST /app/alerts/read_all` | [home § 4](home.md#4-alerts-tab-inbox) |
| Chip Track Bus | Live Tracking | [home § 6](home.md#6-live-tracking-get-appschoollive) |
| Chip School Calendar | **Not built** (Phase 4b) | — |

## Account (`account`)

| Screen / button | Call | Doc |
| --- | --- | --- |
| Account header (name, photo, mobile and emails) | `GET /app/profile` (or the session's `account`) | [account § 2](account.md#2-the-account-get-appprofile) |
| Banner "Add a mobile or email to keep this account" (`needs_identity: true`) | opens Mobile and Emails | [account § 2](account.md#2-the-account-get-appprofile) |
| Edit name, Show My Name As, photo (choose / remove) | `PATCH /app/profile` | [account § 3](account.md#3-account-changes-patch-appprofile) |
| Household row ("<Family> · n adults · n children" / "No Family yet") | `GET /app/household` (`data: null` = no Family) | [household § 3](household.md#3-the-household-screen-get-apphousehold) |
| Fees row (Billing Contact: "n invoices due" / "All paid" / "No invoices yet") | `GET /app/fees` (`403 billing_only` for others: hide the row) | [fees § 2](fees.md#2-fees-get-appfees) |
| Organisations row | `GET /app/organisations` | [organisations § 2](organisations.md#2-the-screen-get-apporganisations) |
| Notifications switches (Push, SMS, Email) | `PATCH /app/profile { profile: { notify_* } }` | [account § 3](account.md#3-account-changes-patch-appprofile) |
| Shuttle Alerts rows, switch, Pause Alerts / Resume | see Shuttles below | [shuttles § 7](shuttles.md#7-alert-settings-and-pause-alerts) |
| Language ("English") | **Not built** (Coming Soon) | — |
| About Convoy, footer "Convoy App 1.0 · Singapore" | FE only (static) | — |
| Sign Out | `DELETE /app/session` | [auth § 3.2](auth.md#3-the-session-and-sign-out) |

## Mobile and Emails (`ids`)

| Screen / button | Call | Doc |
| --- | --- | --- |
| The list (Personal / Work chips, uses, next check) | `GET /app/identities` | [account § 4.1](account.md#41-the-list-get-appidentities) |
| Add Work Email / Add or Change Mobile / Add or Change Personal Email → Send code | `POST /app/identities/code` | [account § 4.2](account.md#42-add-code-then-verify) |
| Code typed → Verify (Resend, Cancel) | `POST /app/identities/verify` | [account § 4.2](account.md#42-add-code-then-verify) |
| Outcome found → Accept / Not Me | `POST /app/organisations/:kind/:id/accept` / `decline` | [organisations § 3](organisations.md#3-after-add-work-email) |
| Outcome none → Suggest Convoy / OK | Suggest Convoy below | [account § 5](account.md#5-suggest-convoy-post-appcompany_suggestions) |
| Verify Again (work email, due soon / paused) | the same two calls, same value, `tag: work` | [account § 4.6](account.md#46-work-email-verify-again) |
| X on a row | `DELETE /app/identities/:id` | [account § 4.4](account.md#44-remove-delete-appidentitiesid) |
| Mobile that another account had | same flow; outcome `moved` | [account § 4.5](account.md#45-a-mobile-on-another-account) |

## Suggest Convoy (`sugg`)

| Screen / button | Call | Doc |
| --- | --- | --- |
| Tell Convoy (Company Name, Who to Contact, Convoy May Say I Suggested It) → Send | `POST /app/company_suggestions` | [account § 5](account.md#5-suggest-convoy-post-appcompany_suggestions) |
| Share With Your Company (native share of the fixed message) | FE only (phone share) | [account § 5](account.md#5-suggest-convoy-post-appcompany_suggestions) |

## Privacy and Data (`privacy`)

| Screen / button | Call | Doc |
| --- | --- | --- |
| Who Sees What | FE only (static) | — |
| Download My Data | **Not built** | — |
| Delete Account → confirm | `DELETE /app/profile`, then Sign In | [account § 6](account.md#6-delete-account-delete-appprofile) |
| Sign in again within 30 days | cancels it (nothing to call) | [account § 6](account.md#6-delete-account-delete-appprofile) |

## Organisations (`orgs`)

| Screen / button | Call | Doc |
| --- | --- | --- |
| Links, invitations, unlinked work emails; Home invitation cards | `GET /app/organisations` | [organisations § 2](organisations.md#2-the-screen-get-apporganisations) |
| Add Work Email → code verified → "<org> added <email>" | `POST /app/identities/verify` (`invitations`) | [organisations § 3](organisations.md#3-after-add-work-email) |
| Accept / Not Me on an employer or school card | `POST /app/organisations/:kind/:id/accept`, `POST /app/organisations/:kind/:id/decline` | [organisations § 4](organisations.md#4-accept--not-me) |
| Links paused since … → Verify Again | `POST /app/identities/code` + `/verify` (same work email) | [organisations § 5](organisations.md#5-an-overdue-work-email-pauses-its-links) |
| Remove Link / Leave | FE only: shows "Ask <org>'s office to remove the link" | [organisations § 6](organisations.md#6-remove-link) |
| Unlinked work email → Suggest Convoy | `POST /app/company_suggestions` | [account § 5](account.md#5-suggest-convoy-post-appcompany_suggestions) |

## Household (`hh`, `famNew`, `guard`; sheets `addFam`, `qInv`, `adPh`; `mInv`)

| Screen / button | Call | Doc |
| --- | --- | --- |
| Household screen (adults, Asked to Join, children with status) | `GET /app/household` | [household § 3](household.md#3-the-household-screen-get-apphousehold) |
| Set Up Your Family: Start a New Family / Join My Family | FE only (choice) | [household § 1](household.md#1-how-a-family-works) |
| Banner "Add your personal mobile first" (work email only) | FE only: opens Mobile and Emails | [household § 1](household.md#1-how-a-family-works) |
| Join My Family (shows the person's mobile and emails); Share My Details | `GET /app/identities`; share = FE only | [household § 1](household.md#1-how-a-family-works) |
| Postal code search | `GET /app/household/postal?postal=` | [household § 2.1](household.md#21-postal-code-get-apphouseholdpostalpostal460412) |
| Relationship, medical tags, genders, School list (+ "Other"), Level lists | `GET /app/household/options` | [household § 2.2](household.md#22-form-lists-get-apphouseholdoptions) |
| Set Up Your Family step 1 → Next | `POST /app/household` | [household § 2.3](household.md#23-create-post-apphousehold) |
| Step 2 / Add a Child / Save Child | `POST /app/household/dependants` | [household § 4.1](household.md#41-add-a-child-post-apphouseholddependants) |
| Edit a child (not designed in the HTML; built) | `PATCH /app/household/dependants/:id` | [household § 4.2](household.md#42-edit-a-child-patch-apphouseholddependantsid) |
| Child row "Child Login", Let <child> Sign In (`kidLogin`), sheet "What Is Child Login?" | **Not built** (Child Login) | — |
| Add Family Members (sheet `addFam`: Quick Invite or Manual Invite) | FE only (choice) | [household § 5](household.md#5-add-family-members) |
| Quick Invite (message, Copy Link / Messages / WhatsApp / Telegram / More) | `POST /app/household/invite_link`; channels = FE only | [household § 5.1](household.md#51-quick-invite-post-apphouseholdinvite_link) |
| Person opens the invite link → asks to join | `GET /app/household/links/:token`, `POST /app/household/links/:token/join` | [household § 5.2](household.md#52-the-person-opens-the-link) |
| Asked to Join › Approve / Decline (Admin) | `POST /app/household/members/:id/approve`, `POST /app/household/members/:id/decline` | [household § 5.3](household.md#53-asked-to-join-admin) |
| Manual Invite › pick contacts (phone contacts, Add manually) | contacts = FE only; who is on Convoy: `POST /app/household/invites/check` | [household § 5.4](household.md#54-manual-invite) |
| Manual Invite › Relationship → Send (+ "Invite the Rest by Link") | `POST /app/household/invites` | [household § 5.4](household.md#54-manual-invite) |
| Family invite on Home / Accept / Not Me | `GET /app/household/invitations`, `POST /app/household/invitations/:id/accept`, `POST /app/household/invitations/:id/decline` | [household § 5.5](household.md#55-accept--not-me) |
| Add a Photo of an adult / Save Photo (sheet `adPh`) | `PATCH /app/household/members/:id` | [household § 6](household.md#6-adult-photo-patch-apphouseholdmembersid) |
| Authorised Guardians (pills per child, switches) | `GET /app/household/guardians` | [household § 7](household.md#7-authorised-guardians) |
| Guardian switch / Save and Allow | `PUT /app/household/dependants/:dependant_id/guardians/:member_id` | [household § 7](household.md#7-authorised-guardians) |
| Guardians › Add Someone to the Household | FE only (sheet `addFam`) | [household § 5](household.md#5-add-family-members) |
| Delete Family → confirm | `DELETE /app/household` | [household § 8](household.md#8-delete-family-delete-apphousehold) |

## School Bus (`school`, `bus`, `apply`, `appStatus`, `sreq`, `addr`)

| Screen / button | Call | Doc |
| --- | --- | --- |
| School Bus page (rider cards, children without a bus, address banner, CCA card, quick actions) | `GET /app/school` | [school § 2](school.md#2-school-bus-page-get-appschool) |
| Rider card tap › Bus Information (Pick-up / Drop-off) | `GET /app/school/riders/:dependant_id/bus?session=` | [school § 3](school.md#3-bus-information) |
| Bus Information › Call driver / attendant (driver: confirm sheet `drv`) | FE only (phone from `crew`) | [school § 3](school.md#3-bus-information) |
| Bus Information › "N people can receive <first>" | Authorised Guardians | [household § 7](household.md#7-authorised-guardians) |
| Track Bus (card, Bus Information) | Live Tracking below | [home § 6](home.md#6-live-tracking-get-appschoollive) |
| Request School Bus (step 1 and 2 lists) | `GET /app/school/apply?school_id=` | [school § 4.1](school.md#41-the-form-get-appschoolapplyschool_id) |
| Step 1 › Add New Child | `POST /app/household/dependants` | [household § 4.1](household.md#41-add-a-child-post-apphouseholddependants) |
| Step 2 Next (last child) › Review and Estimated Fare | `POST /app/school/apply/review` | [school § 4.2](school.md#42-review-and-estimated-fare-post-appschoolapplyreview) |
| Agree + Submit / Pay S$x and Submit | `POST /app/school/apply` | [school § 4.3](school.md#43-submit-post-appschoolapply) |
| View Request › Application Status | `GET /app/school/requests/:id` | [school § 5.1](school.md#51-get-appschoolrequestsid) |
| Withdraw Request | `POST /app/school/requests/:id/withdraw` | [school § 5.2](school.md#52-withdraw-request-post-appschoolrequestsidwithdraw) |
| Agree to New Fare / Don't Agree (banner, Change Service list) | `POST /app/school/requests/:id/agree` | [school § 5.3](school.md#53-agree-to-new-fare--dont-agree-post-appschoolrequestsidagree) |
| Renew for <yr> / Change Service / Stop Bus Service (form + my requests) | `GET /app/school/changes?kind=renew\|svc\|stop` | [school § 6.1](school.md#61-the-screen-get-appschoolchangeskindrenewsvcstop) |
| Send Renewal / Send Change / Send Request to Stop | `POST /app/school/renewals`, `/service_changes`, `/stops` | [school § 6.2](school.md#62-send) |
| Renewal accepted › Pay S$x | the Invoice of its `bill_id` | [fees § 3](fees.md#3-invoice-get-appfeesinvoicesid) |
| Change of Address step 1 (children, allowed dates) | `GET /app/school/address_change` | [school § 7.1](school.md#71-step-1-get-appschooladdress_changedependant_ids1) |
| Change of Address › Find (postal) | `GET /app/household/postal?postal=` | [household § 2.1](household.md#21-postal-code-get-apphouseholdpostalpostal460412) |
| Change of Address step 2 → 3 (fares before / after) | `POST /app/school/address_change/review` | [school § 7.2](school.md#72-step-2--3-post-appschooladdress_changereview) |
| Confirm Change | `POST /app/school/address_change` | [school § 7.3](school.md#73-confirm-change-post-appschooladdress_change) |
| Pay Registration Fee / View First Invoice / Pay S$x | open the Invoice of the `bill_id` on the card / request | [fees § 3](fees.md#3-invoice-get-appfeesinvoicesid) |
| Quick actions Fees / Guardians | Fees below / Authorised Guardians | [fees § 2](fees.md#2-fees-get-appfees) |
| Quick actions / buttons Bus Not Required, School Calendar, Contact | **Not built** (Phase 4b) | — |

## Live Tracking (`live`)

| Screen / button | Call | Doc |
| --- | --- | --- |
| Far card / map, child chips, changed bus banner, stops, crew, Your stop; live by WebSocket (`TrackChannel` `school_live`) | `GET /app/school/live?bus=` | [home § 6](home.md#6-live-tracking-get-appschoollive) |
| Sheet Small / Standard / Full, recentre, Street View, Call (confirm sheet `drv`) | FE only | [home § 6](home.md#6-live-tracking-get-appschoollive) |
| Help request banner "a photo of your stop", Add Photo (sheet `phBrief`) | **Not built** (Phase 4b, Stop Photos) | — |

## Fees and CCA Bus (`fees`, `inv`, `cca`)

Fees are the Billing Contact's (`403 billing_only` for others; `actions.fees` is `null` for them). Payment is simulated.

| Screen / button | Call | Doc |
| --- | --- | --- |
| Fees (Outstanding, Invoices, Payments tabs) | `GET /app/fees` | [fees § 2](fees.md#2-fees-get-appfees) |
| Outstanding › Pay with PayNow, tap an invoice, View First Invoice | `GET /app/fees/invoices/:id` (`pay_first_id` for the first) | [fees § 3](fees.md#3-invoice-get-appfeesinvoicesid) |
| Invoice › Pay S$x / I Have Paid / I've Transferred / Pay by Card | `POST /app/fees/invoices/:id/pay { method }` | [fees § 4](fees.md#4-pay-post-appfeesinvoicesidpay) |
| Invoice › PayNow QR, Save QR | FE only (draws the QR from the PayNow details) | [fees § 3](fees.md#3-invoice-get-appfeesinvoicesid) |
| Payments tab › Receipt | `receipt_number` from `GET /app/fees` (no email yet) | [fees § 2](fees.md#2-fees-get-appfees) |
| CCA Bus (school pills, Next Week / This Week, each child's days, credit, deadline) | `GET /app/cca?school_id=&tab=next\|this` | [fees § 5](fees.md#5-cca-bus-week-get-appcca) |
| Add Ride / Riding picks → the pay bar (rows, credit, admin fee, total) | `POST /app/cca/quote` | [fees § 6](fees.md#6-quote-and-pay-to-confirm) |
| Pay S$x / Book with Credit | `POST /app/cca/payments` (Billing Contact) | [fees § 6](fees.md#6-quote-and-pay-to-confirm) |
| Not Riding / Riding After All | `PATCH /app/cca/bookings/:id/not_riding` | [fees § 7](fees.md#7-not-riding-and-same-days-every-week) |
| Same Days Every Week switch | `PUT /app/cca/same_days` | [fees § 7](fees.md#7-not-riding-and-same-days-every-week) |

## Shuttles (`shuttle`, `shRoute`, `shSched`; sheets `usual`, `alr`, `pause`)

Staff reach an employer only through an accepted, not paused link ([organisations](organisations.md)); `:employer_id` is the `id` of an employer in the list. Nothing of an employer shows without a live link (`404`).

| Screen / button | Call | Doc |
| --- | --- | --- |
| Shuttles (header, employer switch, My Usual Shuttle card, tag chips, route cards, "Now / Next / Done for today") | `GET /app/shuttles?employer_id=&tag=` | [shuttles § 2](shuttles.md#2-route-list-get-appshuttles) |
| Pin on a route card / the route | `PUT /app/shuttles/:employer_id/routes/:id/pin { pinned }` | [shuttles § 4](shuttles.md#4-pin-and-bell) |
| Choose / Change My Usual Shuttle (sheet `usual`), route menu Set as My Usual | `GET /app/shuttles/:employer_id/usual` | [shuttles § 3](shuttles.md#3-my-usual-shuttle) |
| Save as My Usual / Clear | `PUT` / `DELETE /app/shuttles/:employer_id/usual` | [shuttles § 3](shuttles.md#3-my-usual-shuttle) |
| Route: date strip, timing pills, swap direction, status line, next change banner, change card, crew row, map, stops | `GET /app/shuttles/:employer_id/routes/:id?date=&direction=&run_id=` | [shuttles § 5](shuttles.md#5-route-page) |
| Change card "See the 08:40" | the same call with that `run_id` | [shuttles § 5](shuttles.md#5-route-page) |
| Map Centre on bus / Fit route, Legends, Street View, No Fixed Bus popover | FE only | [shuttles § 5](shuttles.md#5-route-page) |
| Stop bell | `PUT /app/shuttles/:employer_id/routes/:id/stops/:stop_id/bell { direction, on }` | [shuttles § 4](shuttles.md#4-pin-and-bell) |
| View Schedule (month, timetable) | `GET /app/shuttles/:employer_id/routes/:id/schedule?direction=&month=&date=` | [shuttles § 6](shuttles.md#6-view-schedule) |
| Alert Settings (sheet `alr`: bell in the route header, route menu, More) | `GET` / `PUT /app/shuttles/:employer_id/routes/:id/alerts` | [shuttles § 7](shuttles.md#7-alert-settings-and-pause-alerts) |
| Account › Notifications › Shuttle Alerts (rows, switch) | `GET /app/shuttles/alerts`, switch = `PUT …/alerts { enabled }` | [shuttles § 7](shuttles.md#7-alert-settings-and-pause-alerts) |
| Pause Alerts (sheet `pause`) / Resume | `PUT /app/shuttles/pause { until }` / `DELETE /app/shuttles/pause` | [shuttles § 7](shuttles.md#7-alert-settings-and-pause-alerts) |
| More › Report a Lost Item, Contact Transport Desk | **Not built** (Phase 4b, contact page) | — |
| More › Send Feedback | **Not built** (Coming Soon) | — |
| Alerts tab, Home Up Next / notice banners | see Home and Alerts above | [home.md](home.md) |

## Bookings (`bookings`, `bkDetail`, `bkNew`, `bkPt`, `bkTrack`; sheets `acc`, `reply`, `cx`, `dup`, `pay`, `link`)

`account` = a `key` from `GET /app/bookings/accounts` (Personal, or a school / company link). A booking id is found only among the person's own bookings (`404` otherwise).

| Screen / button | Call | Doc |
| --- | --- | --- |
| Bookings header (account switch sheet `acc`, "Bill to Your Company?") | `GET /app/bookings/accounts` | [bookings § 1](bookings.md#1-booking-accounts) |
| Personal hint "Add your work email" / Bill to My Company (sheet `link`) | FE only (Add Work Email, Suggest Convoy) | [bookings § 1](bookings.md#1-booking-accounts) |
| Tabs Current / Pending / Past / All, booking cards | `GET /app/bookings?account=&tab=&page=` | [bookings § 2](bookings.md#2-list-get-appbookings) |
| Tap a card: banner, day pills, trips, buses, rows, total, timeline | `GET /app/bookings/:id` | [bookings § 3](bookings.md#3-a-booking-get-appbookingsid) |
| New (step 1–2: kinds, vehicles, Who Pays, Bill To, PO, cards / PayNow, receipt, contact) | `GET /app/bookings/form?account=` | [bookings § 4.1](bookings.md#41-form-get-appbookingsformaccount) |
| Step 1 Add Trip, Duplicate Last, remove, Change Order, Reset way back, map pins, road time / km (OSRM) | FE only (`distance_km` is sent with the estimate) | [bookings § 4.3](bookings.md#43-send-post-appbookings) |
| Estimates while filling in, step 3 Review (approval preview, card fee, short notice) | `POST /app/bookings/estimate` | [bookings § 4.2](bookings.md#42-estimate-post-appbookingsestimate) |
| Send for Approval / Pay | `POST /app/bookings` | [bookings § 4.3](bookings.md#43-send-post-appbookings) |
| Add card | **Not built** (Coming Soon: no saved cards) | [bookings § 4.1](bookings.md#41-form-get-appbookingsformaccount) |
| Pick a Point lists (organisation, My Points, Recent) | `GET /app/bookings/points?account=` | [bookings § 5](bookings.md#5-pick-a-point) |
| Pick a Point search (OneMap), map with a fixed pin, address under the pin | FE only | [bookings § 5](bookings.md#5-pick-a-point) |
| Save This Point | `POST /app/bookings/points` | [bookings § 5](bookings.md#5-pick-a-point) |
| Accept Changes | `POST /app/bookings/:id/accept_changes` | [bookings § 6](bookings.md#6-accept-changes--cant-accept) |
| Can't Accept / Reply Again (sheet `reply`) | `POST /app/bookings/:id/reply` | [bookings § 6](bookings.md#6-accept-changes--cant-accept) |
| Cancel Booking / Request Cancellation (sheet `cx`: scopes, charge) | `GET /app/bookings/:id/cancel` | [bookings § 7](bookings.md#7-cancel) |
| Cancel … / Send Request | `POST /app/bookings/:id/cancel` | [bookings § 7](bookings.md#7-cancel) |
| Duplicate / Book Again (sheet `dup`) → New Booking prefilled | `GET /app/bookings/:id/copy?first_day=` | [bookings § 8](bookings.md#8-book-again) |
| Track Buses (map, buses, Fit buses / Fit route = FE) | `GET /app/bookings/:id/track` | [bookings § 9](bookings.md#9-track-buses) |
| Call TC Operations, Call driver | `company.ops_phone` of the booking; driver phone in Track Buses | [bookings § 3](bookings.md#3-a-booking-get-appbookingsid) |
| Pay Now (sheet `pay`: prepaid school invoice) | **Not built** (no prepay: every school / company is invoiced after the trip) | [bookings § 10](bookings.md#10-money-what-is-paid-and-when) |
| Send to Finance; invoice / receipt view | **Not built** (text only) | — |

## Not built

| Screen (HTML id) | Why |
| --- | --- |
| Child Login: Scan (`scan`), Let <child> Sign In (`kidLogin`), sheet "What Is Child Login?" | Not building: child screens not designed |
| Discover tile, Discover banners | Not building: Coming Soon |
| Language | Not building: Coming Soon |
| Send Feedback (Shuttles) | Not building: Coming Soon |
| Download My Data | Not building: export content not described |
| Pay Now on a prepaid school booking (sheet `pay`), Send to Finance, Add card | Not building: no prepay; no payment provider |
| Bus Not Required (`abs`) | **Phase 4b** (planned) |
| School Calendar (`cal`; alert chip, notice button) | **Phase 4b** (planned) |
| Contact + Report an Issue (`contact`; Shuttles Report a Lost Item / Contact Transport Desk) | **Phase 4b** (planned) |
| Stop Photos (`stopPhotos`, sheet `phBrief`, Live help request) | **Phase 4b** (planned) |

Also not in the app, by decision: boarding pass, seat booking, school prepay, real SMS / email (the inbox has every
alert; push is sent, [home § 4.1](home.md#41-push-notifications)), change Admin / Billing Contact, delete an adult / leave a Family.
