# Driver app — Screen map

Every screen and button of `Convoy Driver.dc.html` and the call behind it. Paths start with `/api/v1`. Driving actions
carry `{ client_id, at }` ([driving.md § 1](driving.md#1-how-every-action-works)); their answer is the trip again.

## Sign in

| Screen / button | Call | Doc |
| --- | --- | --- |
| Mobile Number → Send OTP (Resend) | `POST /driver/session/code` | [auth § 1.1](auth.md#11-send-otp-post-driversessioncode) |
| Code boxes (code `123456` for now); Create an Account | `POST /driver/session` | [auth § 1.2](auth.md#12-sign-in-with-the-code-post-driversession) |
| Use email address instead | `POST /driver/session/email` | [auth § 2](auth.md#2-sign-in-with-email-and-password-post-driversessionemail) |
| App start (who am I, which company) | `GET /driver/session`, then `GET /driver/config` | [auth § 3](auth.md#3-the-session-get-driversession), [gps § 1](gps.md#1-app-settings-get-driverconfig) |
| Invitation: Accept / Decline | `POST /driver/companies/:key/accept` / `decline` | [auth § 5](auth.md#5-companies-invitations-employment-history) |

## Drive (Home)

| Screen / button | Call | Doc |
| --- | --- | --- |
| Today / Tomorrow trip cards, New badge, status chip | `GET /driver/runs` (`?date=` for Tomorrow) | [runs § 1](runs.md#1-drive-the-days-runs-get-driverruns) |
| Header plate | `GET /driver/vehicle` → `current.plate` | [vehicle § 1](vehicle.md#1-my-vehicle-today-get-drivervehicle) |
| Bell with red dot | `GET /driver/notifications` → `meta.unread` | [notifications § 1](notifications.md#1-the-bell-get-drivernotifications) |
| Switch Vehicle card | `GET /driver/runs` → `meta.vehicle_switches` | [vehicle § 2](vehicle.md#2-the-switch-vehicle-card-on-drive) |
| Floating on-going trip (every tab) | `GET /driver/runs/on_going` | [runs § 3](runs.md#3-the-on-going-trip-get-driverrunson_going) |
| GPS strip (location off), Internet / GPS dots | app only (phone permissions) | — |

## Plan

| Screen / button | Call | Doc |
| --- | --- | --- |
| Month dots | `GET /driver/runs/schedule?month=` | [runs § 2](runs.md#2-plan-days-with-runs-get-driverrunsschedule) |
| Week strip / a day's trips (past days read-only with the record) | `GET /driver/runs?from=&to=` / `?date=` | [runs § 1](runs.md#1-drive-the-days-runs-get-driverruns) |

## Trip Details

| Screen / button | Call | Doc |
| --- | --- | --- |
| Open a trip (clears New) | `GET /driver/runs/:id`, `POST /driver/runs/:id/seen` | [runs § 4–5](runs.md#4-trip-details-get-driverrunsid) |
| Client, route, tiles, Trip Value, airport, disposal, Day n of N, notes, attachments, standby | `GET /driver/runs/:id` | [runs § 4](runs.md#4-trip-details-get-driverrunsid) |
| Map pins, road route, waypoints, stop stepper, recorded times / counts | `points` | [runs § 4](runs.md#4-trip-details-get-driverrunsid) |
| Point of Contact (requester, guest, main contractor; operations) | `contacts`; `GET /driver/company` → `operations` | [runs § 4](runs.md#4-trip-details-get-driverrunsid), [profile § 5](profile.md#5-transport-company-get-drivercompany) |
| Before You Go (children not riding, skipped points) | `before_you_go` | [runs § 4](runs.md#4-trip-details-get-driverrunsid) |
| Swipe to start (On the Way) | `POST /driver/runs/:id/start` | [driving § 2](driving.md#2-start-the-trip-post-driverrunsidstart) |
| Edit Route (not riding today, skip a point) | `PATCH /driver/runs/:id/route` | [driving § 8](driving.md#8-edit-route-patch-driverrunsidroute) |
| Main contractor app ("Continue on … app") | `contractor.requires_app` (the handover flow is not built on the server) | [runs § 4](runs.md#4-trip-details-get-driverrunsid) |

## On Route

| Screen / button | Call | Doc |
| --- | --- | --- |
| GPS while the trip runs (every few seconds, in batches) | `POST /driver/positions` | [gps § 2](gps.md#2-send-positions-post-driverpositions) |
| Geofence fires (start the 10 s countdown) | `POST /driver/runs/:id/geofence` | [gps § 3](gps.md#3-geofence-alert-post-driverrunsidgeofence) |
| Arrive (button or countdown) | `POST /driver/runs/:id/arrive` | [driving § 3](driving.md#3-arrive-at-a-point-post-driverrunsidarrive) |
| Leave (button or countdown); Leave without attendance warning → leave anyway | `POST /driver/runs/:id/leave` (`force: true`) | [driving § 4](driving.md#4-leave-a-point-post-driverrunsidleave) |
| Skip point (reasons); empty point skipped on the way | `POST /driver/runs/:id/skip_stop` (`auto: true`) | [driving § 5](driving.md#5-skip-a-point-post-driverrunsidskip_stop) |
| Take Attendance, QR scan, All Passengers (correct a mark), child photo / Call Parent | `POST /driver/runs/:id/attendance`; `passengers` | [driving § 6](driving.md#6-take-attendance-post-driverrunsidattendance) |
| Count passengers | `POST /driver/runs/:id/count` | [driving § 7](driving.md#7-count-passengers-post-driverrunsidcount) |
| Complete Trip (feedback) | `POST /driver/runs/:id/complete` | [driving § 9](driving.md#9-complete-the-trip-post-driverrunsidcomplete) |
| Force End Trip (reasons, call operations) | `POST /driver/runs/:id/force_end` | [driving § 10](driving.md#10-force-end-trip-post-driverrunsidforce_end) |
| Skip Trip (reasons) | `POST /driver/runs/:id/skip` | [driving § 11](driving.md#11-skip-the-whole-trip-post-driverrunsidskip) |
| Phone icon (call the office) | `GET /driver/company` → `operations.phone` | [profile § 5](profile.md#5-transport-company-get-drivercompany) |

## Disposal

| Screen / button | Call | Doc |
| --- | --- | --- |
| Start Disposal (odometer, dash photo, agreed / now) | `POST /driver/runs/:id/disposal_start` | [disposal § 2](disposal.md#2-start-the-disposal-post-driverrunsiddisposal_start) |
| Block timer, overtime, standing by | `disposal.record.clock` | [disposal § 6](disposal.md#6-the-block-clock) |
| Start Run / End Run | `POST /driver/runs/:id/disposal_run_start` / `disposal_run_end` | [disposal § 3](disposal.md#3-runs) |
| Extend Time (step 1 driver, step 2 client signs) | `POST /driver/runs/:id/disposal_extend` | [disposal § 4](disposal.md#4-extend-time-post-driverrunsiddisposal_extend) |
| End Disposal (odometer, photo, released by, signature) | `POST /driver/runs/:id/disposal_end` | [disposal § 5](disposal.md#5-end-the-disposal-post-driverrunsiddisposal_end) |

## Switch Vehicle

| Screen / button | Call | Doc |
| --- | --- | --- |
| Switch Vehicle screen (the bus, when) | `GET /driver/vehicle` → `switches` | [vehicle § 1](vehicle.md#1-my-vehicle-today-get-drivervehicle) |
| Six photos, mark up a photo, declaration → Confirm | `POST /driver/vehicle/handovers` | [vehicle § 3](vehicle.md#3-handover-inspection-post-drivervehiclehandovers) |

## Notifications

| Screen / button | Call | Doc |
| --- | --- | --- |
| List, unread dot | `GET /driver/notifications` | [notifications § 1](notifications.md#1-the-bell-get-drivernotifications) |
| Tap a line / Mark all read | `POST /driver/notifications/:id/read` / `read_all` | [notifications § 2](notifications.md#2-mark-as-read) |
| Notice detail (text, picture, link) | `GET /driver/notices/:id` | [notifications § 3](notifications.md#3-open-a-notice-get-drivernoticesid) |
| Acknowledge | `POST /driver/notices/:id/acknowledge` | [notifications § 4](notifications.md#4-acknowledge-a-notice-post-drivernoticesidacknowledge) |

## Account

| Screen / button | Call | Doc |
| --- | --- | --- |
| Profile card, Career Metrics (This Company / All Time) | `GET /driver/profile` | [profile § 1](profile.md#1-the-profile-get-driverprofile) |
| Personal Details, Complete My Profile (name, DOB, nationality, address, photo, NRIC once) | `PATCH /driver/profile` | [profile § 2](profile.md#2-personal-details-patch-driverprofile) |
| Email and password | `PATCH /driver/profile/email` | [profile § 3](profile.md#3-email-and-password-patch-driverprofileemail) |
| Update with Singpass | not available yet (fields verified with Singpass are shown locked) | [profile § 1](profile.md#1-the-profile-get-driverprofile) |
| Driving Credentials: add / edit / delete a licence | `POST` / `PATCH` / `DELETE /driver/licences` | [profile § 4](profile.md#4-driving-credentials) |
| Transport Company, Contact Operations, Company Links | `GET /driver/company` | [profile § 5](profile.md#5-transport-company-get-drivercompany) |
| Switch Company | `PATCH /driver/session` | [auth § 4.1](auth.md#41-switch-company-patch-driversession) |
| Disconnect from … | `POST /driver/companies/:key/disconnect` | [auth § 5.4](auth.md#54-disconnect-from-a-company-post-drivercompanieskeydisconnect) |
| Employment History | `GET /driver/companies` | [auth § 5.1](auth.md#51-list-companies-get-drivercompanies) |
| My Vehicle Today, Vehicle History | `GET /driver/vehicle`, `GET /driver/vehicle/history` | [vehicle § 1, 4](vehicle.md#1-my-vehicle-today-get-drivervehicle) |
| App Language, Appearance, Larger Text, Date / Time Format | app only (defaults: `GET /driver/config`) | [gps § 1](gps.md#1-app-settings-get-driverconfig) |
| Help Centre, Terms, Privacy, Permissions, About | app only (static pages) | — |
| Sign Out | `DELETE /driver/session` | [auth § 4.2](auth.md#42-sign-out-delete-driversession) |
