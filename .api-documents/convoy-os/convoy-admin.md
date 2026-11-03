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
name", `details.email` "Email is already used by another user".

## 2. Message Terms

| Action | Call |
| --- | --- |
| List (sorted by kind, then term) | `GET /message_terms` → `meta { kinds, count }` |
| Add | `POST /message_terms { message_term: { term, means, kind } }` |
| Edit | `PATCH /message_terms/:id` |
| Delete | `DELETE /message_terms/:id` |

Term: `{ id, term, means, kind, kind_label, created_by, created_at }`; `kind`: `veh` Vehicle, `svc` Service, `place` Place, `oth` Other.
Several spellings can share a term ("Alphard, Vellfire"). `422` `details.term` "Term is already on the list".

## 3. Discover

Convoy's own space in the Convoy App (Home banners and the Discover tab). Views, taps and sales are counted by the app.

| Action | Call |
| --- | --- |
| Advertisers card | `GET /discover/advertisers` |
| Add / Edit Advertiser | `POST /discover/advertisers`, `PATCH /discover/advertisers/:id` `{ advertiser: {...} }` |
| Remove Advertiser | `DELETE /discover/advertisers/:id` (`422` while it has placements not ended) |
| Tabs Live / Scheduled / Draft / Ended, search, KPIs | `GET /discover/placements?tab=live&q=` |
| New Placement / Edit (multipart with a picture) | `POST /discover/placements`, `PATCH /discover/placements/:id` `{ placement: {...} }` |
| Open | `GET /discover/placements/:id` |
| Pause / Resume / End now / Duplicate | `POST /discover/placements/:id/pause` · `/resume` · `/end` · `/duplicate` |
| Delete draft | `DELETE /discover/placements/:id` |

Advertiser: `{ id, name, kind (tc Transport Partner, attr Attraction, prog Programme Provider, brand Brand), kind_label, premier,
country, listing_fee (S$ a month), commission_pct, email, live_count }`. Premier Partner: shown as "From <partner>", not Sponsored.

Placement (body = response):

| Group | Fields |
| --- | --- |
| What it is | `kind`: `trip` Bookable Trip, `prog` Programme or Event, `ad` Advert or Offer, `news` From Convoy (no advertiser); `discover_advertiser_id` |
| Banner | `kicker`, `title`, `subtitle`, `background` (#hex), `image` (file; `remove_image`), `cta` (button label) |
| What people get | trip: `price` (adult), `child_price`, `seats`, `event_on`, `pickup_points`; prog: `price`, `event_on`, `bus_included`; ad: `link`, `promo_code`; `run_by_company_id` (runs the bus), `sold_to_public` |
| Where and who | `show_home`, `show_discover`, `push_once`, `slot` (`std` / `feat` Featured), `audiences[]` (`parents`, `staff`, `bookers`, `public`), `area` (`all`, `east`, `west`, `north`, `ne`, `central`), `school_level` (`any`, `pre`, `primary`, `secondary`) |
| When | `starts_on`, `ends_on`; `status` `draft` (save as draft) or `live` (publish), `paused` |
| Money | `listing_fee`, `commission_pct` (from the advertiser unless sent), `commission` (price × sold × %), `views`, `taps`, `sold` |

`state` (response) = `draft`, `scheduled` (published, not started), `live`, `paused` or `ended` (ended now or past `ends_on`).
`meta { tab, counts, kpis { live, scheduled, views, taps, tap_rate, sold, revenue, listing_fees, commission }, kinds, audiences, areas, levels }`.
`422` (`message`): "Pick the advertiser", "Enter the title", "Check the dates: the end is before the start", "Show it on Home, the
Discover tab or both", "Pick who sees it"; when publishing also "Enter the price", "Pick the transport company that runs the bus",
"Add a link or a promo code". Delete: "Only drafts can be deleted. End it instead". Duplicate → a draft "<title> (copy)".

## 4. Company Leads

| Action | Call |
| --- | --- |
| Tabs Open / Signed Up / Not Interested | `GET /leads?tab=open\\|signed\\|lost` |
| Status, Note | `PATCH /leads/:domain { status, note }` (e.g. `/leads/acme.com.sg`) |

Row (one per work email domain, most asks first): `{ domain, company (the name most typed), status, status_label, note, updated_by,
updated_at, last_asked_at, contacts_given, named, asks [{ asked_at, company, contact, who { name, via } | null, source }] }`.
`status`: `new` New, `contacted` Contacted, `demo` Demo Booked, `signed` Signed Up, `lost` Not Interested. Sub line
"N people asked", "Last asked <date>", "N contacts given · N agreed to be named"; "Updated by <name> on <date>" / "Not worked on yet".
Asks come from the Convoy App (Organisations > Suggest Convoy).

## 5. Changes to existing endpoints (02/11/2026)

| Endpoint | Before | Now |
| --- | --- | --- |
| `POST /companies` | Company only | Needs `admin { name, email, password }` (the company's first admin) |
| `GET /companies` (Convoy Admin) | Company fields | Also `admin`, `schools_count`, `users_count`, `is_current` |
