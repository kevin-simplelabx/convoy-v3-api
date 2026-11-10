# Convoy Admin — API Guide

The Convoy Admin menus (only for Convoy staff, role `convoy_admin`): **Transport Companies**, **Message Terms**,
**Discover**, **Company Leads**. Company users get `403`. Conventions are in [README.md](../README.md); paths start with `/api/v1`.
These are Convoy's own records, so no company needs to be picked first.

## Contents

1. [Transport Companies](#1-transport-companies)
2. [Message Terms](#2-message-terms)
3. [Discover](#3-discover)
4. [Company Leads](#4-company-leads)
5. [Changes to existing endpoints (02/11/2026)](#5-changes-to-existing-endpoints-02112026)

---

## 1. Transport Companies

| Action | Call |
| --- | --- |
| List | `GET /companies` (`q[name_i_cont]`) |
| New Company → Create Company | `POST /companies { company: { name, code? }, admin: { name, email, password } }` |
| External Vehicles limit, School Run / Route List Import switches | `PATCH /companies/:id { company: { external_vehicle_cap, school_run_enabled, route_list_import_enabled } }` |
| Open (work inside a company) | `PATCH /session { company_id }` |

Row (Convoy Admin view): the company fields plus `admin { name, email }`, `schools_count`, `users_count`, `created_at`,
`external_vehicle_cap`, `school_run_enabled`, `route_list_import_enabled`, `is_current` (the company opened for this
sign-in: badge Open). The new company's admin is its Super Admin with every permission ("<name> created. Its admin can sign in
with <email>"). `code` is made from the name when left out. `422`: "Password needs at least 8 characters", "Enter the admin's
name", `details.email` "is already used by another user".

`POST /companies` → **201** and `PATCH /companies/:id` → **200** return the same row as the list:

```json
{ "data": { "id": 4, "name": "Lion City Coaches Pte Ltd", "short_name": null, "display_name": "Lion City Coaches Pte Ltd", "code": "LCC",
            "country": "SG", "timezone": "Asia/Singapore", "theme_color": "#0B6E6E", "date_format": "dmy", "time_format": "24",
            "observed_holidays": "off", "business_units_enabled": false, "status": "active", "logo": null,
            "country_set_at": null, "ops_phone": null, "ops_hours": null, "ops_whatsapp": null, "ops_email": null, "depot_address": null,
            "country_locked": false, "country_set_by": null, "country_request": null, "can_edit": true,
            "school_run_enabled": false, "route_list_import_enabled": false, "external_vehicle_cap": null,
            "created_at": "2026-11-04T10:12:00+08:00", "admin": { "name": "Daniel Ong", "email": "daniel@lioncity.sg" },
            "schools_count": 0, "users_count": 1, "is_current": false } }
```

A Convoy Admin may change **every** field of any company with `PATCH /companies/:id`: the Company Settings fields
(`name`, `short_name`, `theme_color`, `logo` / `remove_logo`, `timezone`, `date_format`, `time_format`, `observed_holidays`,
`business_units_enabled`, `ops_*`, `depot_address`) and the platform fields (`code`, `country`, `status`,
`school_run_enabled`, `route_list_import_enabled`, `external_vehicle_cap`). `can_edit` is therefore `true` for a Convoy Admin.

## 2. Message Terms

| Action | Call |
| --- | --- |
| List (sorted by kind, then term) | `GET /message_terms` → `meta { kinds, count }` |
| Add | `POST /message_terms { message_term: { term, means, kind } }` |
| Edit | `PATCH /message_terms/:id` |
| Delete | `DELETE /message_terms/:id` |

`POST` → **201**, `PATCH` → **200**, both `{ data: <term> }`. Term:

```json
{ "id": 12, "term": "Alphard, Vellfire", "means": "Toyota Alphard / Vellfire (6–7 seat MPV)", "kind": "veh", "kind_label": "Vehicle",
  "created_by": "Convoy Support", "created_at": "2026-11-02T09:30:00+08:00" }
```

 `kind`: `veh` Vehicle, `svc` Service, `place` Place, `oth` Other.
Several spellings can share a term ("Alphard, Vellfire"). `422` `details.term`: "is already on the list".

## 3. Discover

Convoy's own space in the Convoy App (Home banners and the Discover tab). Views, taps and sales are counted by the app.

| Action | Call |
| --- | --- |
| Advertisers card | `GET /discover/advertisers` |
| Add / Edit Advertiser | `POST /discover/advertisers` (**201**), `PATCH /discover/advertisers/:id` `{ advertiser: { name, kind, premier, country, listing_fee, commission_pct, email } }` |
| Remove Advertiser | `DELETE /discover/advertisers/:id` → `204`; `422` "<name> has placements. End or delete them first" while any placement is not ended (drafts and scheduled count too) |
| Tabs Live / Scheduled / Draft / Ended, search, KPIs | `GET /discover/placements?tab=live&q=` |
| New Placement / Edit (multipart with a picture) | `POST /discover/placements`, `PATCH /discover/placements/:id` `{ placement: {...} }` |
| Open | `GET /discover/placements/:id` |
| Pause / Resume / End now / Duplicate | `POST /discover/placements/:id/pause` · `/resume` · `/end` · `/duplicate` |
| Delete draft | `DELETE /discover/placements/:id` |

Advertiser: `{ id, name, kind (tc Transport Partner, attr Attraction, prog Programme Provider, brand Brand), kind_label, premier,
country, listing_fee (S$ a month), commission_pct, email, live_count }` (`live_count` = placements live or paused).
`GET /discover/advertisers` also returns `meta { kinds: { "tc": "Transport Partner", "attr": "Attraction", "prog": "Programme Provider", "brand": "Brand" } }`. `listing_fee` / `commission_pct` empty: 0 on a new
advertiser, unchanged on edit. `422` "Listing fee must be 0 or more", "Commission must be between 0 and 100%" (also on placements). Premier Partner: shown as "From <partner>", not Sponsored.

Placement (body = response):

| Group | Fields |
| --- | --- |
| What it is | `kind`: `trip` Bookable Trip, `prog` Programme or Event, `ad` Advert or Offer, `news` From Convoy (no advertiser); `discover_advertiser_id` |
| Banner | `kicker`, `title`, `subtitle`, `background` (#hex), `image` (file; `remove_image`), `cta` (button label) |
| What people get | trip: `price` (adult), `child_price`, `seats`, `event_on`, `pickup_points`; prog: `price`, `event_on`, `bus_included`; ad: `link`, `promo_code`; `run_by_company_id` (runs the bus), `sold_to_public` |
| Where and who | `show_home`, `show_discover`, `push_once`, `slot` (`std` / `feat` Featured), `audiences[]` (`parents`, `staff`, `bookers`, `public`), `area` (`all`, `east`, `west`, `north`, `ne`, `central`), `school_level` (`any`, `pre`, `primary`, `secondary`) |
| When | `starts_on`, `ends_on`; `status` `draft` (save as draft) or `live` (publish), `paused` |
| Money | `listing_fee`, `commission_pct` (always a number, never `null`), `commission` (price × sold × %), `views`, `taps`, `sold` |

Empty fields (multipart sends `""`):
- `listing_fee`, `commission_pct` left out or empty: on a new placement, or when `discover_advertiser_id` changes, they come
  from the advertiser (0 for `news`); otherwise they stay as they are. Send a number (e.g. `0`) to set them.
- `price`, `child_price`, `seats`, `event_on`, `link`, `promo_code` and the banner texts empty → cleared (`null`).
- `cta` empty → "Book Now". `starts_on` / `ends_on` empty → `422` "Pick the start and end dates".

`state` (response) = `draft`, `scheduled` (published, not started), `live`, `paused` or `ended` (ended now or past `ends_on`).
Tabs: `live` holds `live` **and `paused`**; `scheduled`, `draft`, `ended` hold their own state. `meta.counts` = one count per tab.
The response also has `advertiser { id, name, premier }` (or `null` for `news`), `run_by_company { id, name }` (or `null`),
`image { url }` (or `null`), `kind_label`, `ended_at`, `created_at`. `POST` and `/duplicate` → **201**.

```json
{ "id": 9, "kind": "trip", "kind_label": "Bookable Trip", "discover_advertiser_id": 3,
  "advertiser": { "id": 3, "name": "Sentosa Leisure", "premier": false }, "run_by_company_id": 1, "run_by_company": { "id": 1, "name": "SimpleDrive" },
  "kicker": "School holidays", "title": "Sentosa Day Out", "subtitle": "Return coach from 6 pick-up points", "background": "#0B6E6E", "cta": "Book Now",
  "image": { "url": "/api/v1/downloads/eyJ..." }, "price": "38.0", "child_price": "28.0", "seats": 40, "event_on": "2026-12-05",
  "pickup_points": "Tampines, Jurong East, Woodlands", "bus_included": false, "sold_to_public": true, "link": null, "promo_code": null,
  "show_home": true, "show_discover": true, "push_once": false, "slot": "feat", "audiences": ["parents", "public"], "area": "all", "school_level": "any",
  "starts_on": "2026-11-10", "ends_on": "2026-12-04", "status": "live", "state": "live", "listing_fee": "0.0", "commission_pct": "10.0",
  "commission": "114.0", "views": 1240, "taps": 96, "sold": 30, "ended_at": null, "created_at": "2026-11-02T11:00:00+08:00" }
```
`meta { tab, counts, kpis { live, scheduled, views, taps, tap_rate, sold, revenue, listing_fees, commission }, kinds, audiences, areas, levels }`.
`422` (`message`): "Pick the advertiser", "Enter the title", "Pick the start and end dates", "Check the dates: the end is before the start", "Show it on Home, the
Discover tab or both", "Pick who sees it"; when publishing also "Enter the price", "Pick the transport company that runs the bus",
"Add a link or a promo code". Delete: "Only drafts can be deleted. End it instead". Duplicate → a draft "<title> (copy)".

## 4. Company Leads

| Action | Call |
| --- | --- |
| Tabs Open / Signed Up / Not Interested | `GET /leads?tab=open\|signed\|lost` |
| Status, Note | `PATCH /leads/:domain { status, note }` (e.g. `/leads/acme.com.sg`) |

Row (one per work email domain, most asks first): `{ domain, company (the name most typed), status, status_label, note, updated_by,
updated_at, last_asked_at, contacts_given, named, asks [{ asked_at, company, contact, who { name, via } | null, source }] }`.
`status`: `new` New, `contacted` Contacted, `demo` Demo Booked, `signed` Signed Up, `lost` Not Interested. Sub line
"N people asked", "Last asked <date>", "N contacts given · N agreed to be named"; "Updated by <name> on <date>" / "Not worked on yet".
Asks come from the Convoy App (Organisations > Suggest Convoy).

`meta`: `{ tab, counts: { open, signed, lost }, statuses: { new: "New", contacted: "Contacted", demo: "Demo Booked", signed: "Signed Up", lost: "Not Interested" } }`.
`PATCH /leads/:domain` → **200** `{ data: <row> }` (the domain's row after the change); `404` when nobody asked from that domain.

```json
{ "domain": "acme.com.sg", "company": "Acme Pte Ltd", "status": "contacted", "status_label": "Contacted", "note": "Call back after 15 Nov",
  "updated_by": "Convoy Support", "updated_at": "2026-11-04T10:20:00+08:00", "last_asked_at": "2026-11-01T08:12:00+08:00",
  "contacts_given": 1, "named": 1,
  "asks": [ { "asked_at": "2026-11-01T08:12:00+08:00", "company": "Acme Pte Ltd", "contact": "Facilities: Jason Lim, jason.lim@acme.com.sg",
              "who": { "name": "Mei Ling", "via": "Convoy app" }, "source": "Convoy app" } ] }
```

Discover reach estimate ("About N people in the app"): no API yet (the Convoy App users are not in this backend); hide the line.

## 5. Changes to existing endpoints (02/11/2026)

| Endpoint | Before | Now |
| --- | --- | --- |
| `POST /companies` | Company only | Needs `admin { name, email, password }` (the company's first admin) |
| `GET /companies` (Convoy Admin) | Company fields | Also `admin`, `schools_count`, `users_count`, `is_current` |
