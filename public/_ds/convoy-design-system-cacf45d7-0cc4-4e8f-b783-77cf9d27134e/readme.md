# Convoy Design System

**Convoy** is an operating system for private transport fleet management. It is a multi-tenant web
console: a fleet operator (or a corporate client's transport team) plans routes, schedules shuttle
trips against vehicles and drivers, watches the fleet move in real time, replays completed trips, and
reports on ridership, utilisation and on-time performance.

The product is B2B2B. A Convoy operator logs in and works **on behalf of a tenant** — the tenant's
own logo and name sit in the top bar next to the Convoy rail (in the source material the tenant is
"SIMPLEDRIVE", and the client whose shuttles are being run is "Google Asia Pte Ltd"). Operations are
Singapore-based: SGD, `+65` phone numbers, Singapore public-holiday calendars, SBA/SJA/SLK vehicle
plates, Jurong West / Boon Lay / Woodlands / Bedok route geography.

Brand voice: **playful but professional.** In practice that means plain, confident, unfussy
language in the UI — and the playfulness lives in the product's *personality* features ("Create
Route with Convoy AI") rather than in jokey microcopy.

---

## Sources this system was built from

Everything here was reverse-engineered from a mounted, read-only folder of **five product
screenshots** (path: `Design/`, exported at 2× from a 1440 × 880 design frame, except `Live View.png`
which is a 1× export of the same frame):

| Source file | Surface it shows |
| --- | --- |
| `Design/Live View.png` | Live fleet map, vehicle detail popover, right-hand status panel |
| `Design/Assign Trip (1).png` | Scheduler — day/week gantt of vehicles × trips, unassigned tray |
| `Design/Trip History.png` | Trip list + trip detail: route map, schedule record, speed history, trip log |
| `Design/Reports.png` | Report builder — filters, KPI cards, sparklines, tabbed data tables |
| `Design/Create New Shuttle Trip - Trip Information.png` | 3-step route creation wizard (very long form) |

Copies of the five screenshots are kept in `sources/` in this project so the values here stay
auditable. Every measurement below was taken from 1:1 crops of those files.

**No code, Figma file, font binaries, icon assets, or written brand guidelines were provided.**
Where something had to be inferred rather than read, it is flagged as ⚠️ in this document. There is
no marketing site, mobile app, or slide template in the sources, so this system contains **one UI
kit** (the fleet console) and **no slide templates**.

### ⚠️ Open substitutions — please confirm or replace

1. **Typeface → Montserrat.** The product uses a wide geometric sans with a double-storey `a`,
   circular bowls, flat-topped `t` and straight-tailed `y`. Montserrat matched it closest of the
   candidates tested (vs. Mulish, Plus Jakarta Sans, Nunito Sans, Hanken Grotesk, Figtree, Poppins,
   Be Vietnam Pro) and the `CONVOY` wordmark matches Montserrat ExtraBold almost exactly. **If the
   real font is a licensed face (Gilroy, Circular, Museo Sans and similar all sit in this
   neighbourhood), send the font files and I will swap them in.**
2. **Icons → Material Symbols Rounded (filled), from the Google Fonts CDN.** The rail glyphs map
   one-to-one onto Material names (`dashboard`, `assignment`, `desktop_windows`, `directions_bus`,
   `apartment`, `school`, `work`, `insert_chart`, `calculate`, `policy`, `notification_important`),
   so this is very likely the product's actual set rather than a substitution — but no icon files
   were provided, so it is an inference.
3. **Logo — none ships with this system.** No vector or raster logo file was provided, and nothing
   was drawn or reconstructed. Per the user's direction, **the brand mark is set in plain type**
   wherever a logo would go: `CONVOY` in Montserrat ExtraBold at `--teal-800` (or white on teal),
   and `CV` in the same weight for the rail's compact slot. `NavRail` takes `wordmark`, `NavFlyout`
   takes `wordmark` — both render text, not images. **Send the SVG when you have it and these two
   props become the only places to change.**
4. **Map tiles** in the UI kit are crops of the Google Maps imagery visible in the source
   screenshots (`assets/map-*.png`), used as background plates so screens read correctly. The crops
   are taken from regions free of the product's own floating panels, so the live overlays the kit
   renders are not duplicated by baked-in pixels. Swap for the real map SDK in production.

5. **Fixed design width.** The console is authored at its native 1440 × 880 desktop size and scaled
   to fit whatever viewport it is opened in — it is a recreation of a desktop operations tool, not a
   responsive layout. The source material contains no tablet or mobile breakpoint.

---

## CONTENT FUNDAMENTALS

How Convoy writes. All examples below are verbatim from the source screens.

**Register: operational plain-speak.** Nouns are the domain's own nouns, never softened —
`Trip ID`, `Geofence Radius`, `Capacity Required`, `Overall Utilisation in Period`, `Average On Time
Performance`, `Alighted`, `Boarded`, `Skipped`. The reader is a professional who knows what a
shuttle point is; nothing is explained that doesn't need explaining.

**Casing.**
- **Page titles are UPPERCASE** with letter-spacing: `TRIP HISTORY`, `REPORTS`.
- **Breadcrumbs and wizard steps are UPPERCASE**: `ROUTES › CREATE NEW SHUTTLE TRIP`,
  `ROUTE INFORMATION · SHUTTLE SCHEDULE · REVIEW`.
- **Everything else is Title Case** for labels and headings (`Trip Information`, `Point of Contact`,
  `Crew Information`, `Speed History`, `Reset Filters`, `Add Second Guest`) and **sentence case for
  helper text and log lines** (`Label to display on the vehicle`, `move the marker to adjust the
  exact position`, `Drag and drop to upload or Browse`).
- Toggle values shout: `NO` / `YES`, `Day` / `Week`.

**Person.** Almost none. The UI is written in the **imperative or as bare labels** — `Apply`,
`Export`, `Add Point`, `Save Draft`, `Continue`, `Reset Filters`, `Browse`, `Check Location Sharing
Status`. No "we", and "you"/"your" is essentially absent — even the hints are impersonal:
*"Require the driver to use the main contractor app"*, not *"Make your drivers use…"*.

**Status language is short and mechanical, and it always names the state, never the system's
feelings:** `On the way`, `Arrived`, `Completed`, `Offline`, `Available`, `On Trip`, `On time`,
`Skipped`. Log lines are past-tense sentences with the actor first and a full stop only when the
sentence is compound: *"5 passengers boarded at Boon Lay Ave"*, *"Bus SBA3546 skipped Jurong West
Central. No passenger required to dropoff."*

**Numbers and units are explicit and locale-correct.** Dates `22/05/2025` and `Dec 12, 2023`; date
ranges `May 15 - May 30`; times 24-hour `08:30`, `17:35`; percentages to 2 dp `21.49%`, `98.30%`;
speed `45km/h` (no space); seats as a stacked number + caption (`29` / `Seat`); phone `+65 9932
9922`; identifiers carry their prefix (`TID260921`, `VID9922222`, `BID9129034920`, `#0042434-1`).
Empty values are written `N/A`.

**Where the playfulness lives.** Not in the copy of the operational screens — those stay dry on
purpose, because someone is reading them at 6:30am with a bus running late. The brand's lighter
side shows up in **named product moments**: the `Create Route with Convoy AI` button, the
`Scheduler Legends` helper, the punchy `CONVOY` wordmark itself. Rule of thumb: **be playful in
names and empty states, precise in labels, values and errors.**

**Emoji: never.** None appear anywhere in the sources, and none should be added. Unicode symbols are
also avoided — arrows, chevrons, dots and flags are all icon glyphs or images, not characters.
The one repeated typographic device is a pipe separator in composite identity strings:
`Google | WEN | Shuttle Bus`, `#VID9922222 | 29 seats`, `Google Shuttle | WEN | Google`.

**Micro-conventions worth copying**
- Optional fields are marked by the word `Optional` in grey, right-aligned on the label row — never
  by an asterisk on required ones.
- Info affordances are a small teal ⓘ next to the label; the tooltip is one short sentence, no
  full stop.
- Counts ride inside the control that filters them: `Client 2`, `Unassigned Trips 8`, `22 Vehicles`.
- Buttons say the verb and (when it moves you) show direction: `Continue ›`, `‹ Back`.

---

## VISUAL FOUNDATIONS

### Colour

One brand hue — **teal** — carried at two strengths, on a strictly neutral grey field, with four
status colours that are only ever used for status.

- `--teal-800 #004F59` is the brand: the wordmark, the nav rail, primary buttons, selected borders.
- `--teal-600 #008C95` is the accent: chart strokes, status icons, the `Available` state, links
  (`--teal-500 #209AA2` for inline text links).
- `--ink-025 #F4F4F4` is the page background **and** the fill of every input — fields are recessed
  grey rectangles on white cards, not bordered boxes.
- `--ink-800 #212121` is all body text and all headings. Pure black never appears; `--ink-900
  #161616` is reserved for the one dark surface in the product (the Live View status panel).
- Status: green `#00C853` (completed/arrived/on-time), orange `#FF8400` (in progress/on the way),
  red `#FF3D17` (destructive, notification badge, "not required"), teal `#008C95` (informational).
  Each has a 5 %-ish tint for backgrounds: `#E6FAEE`, `#FFEFDF`, `#FFECE8`, `#E5F3F4`.
- A separate six-stop **speed ramp** (`#4285F4 → #5CADFF → #83C950 → #EF7C02 → #E50000 → #9D1313`)
  is used only for speed-coloured route polylines and its legend. It is map data, not brand colour.
- Two background colours per screen, maximum: `#F4F4F4` page, `#FFFFFF` cards. No gradients
  anywhere. No tinted greys.

### Type

Montserrat, four weights in practice: 400 body, 600 emphasis, 700 labels/headings, 800 wordmark
only. The scale is small and tight — 11 / 12 / 13 / 14 / 15 / 16 / 18 / 22 / 28 / 34. Field labels
are 13px/700; body and inputs 15px/400; table cells 14px; captions 11–12px in `--ink-400`.
Numbers are the only thing allowed to be big: report KPIs at 34px/700, seat counts at 18px/700 over
an 11px caption. Uppercase titles take `letter-spacing: 0.04em`; nothing else is tracked.
Line-height 1.45 for prose, 1.15–1.3 for numbers and table rows.

### Layout

A fixed three-part shell: the **88px dark-teal icon rail** — Convoy's first-level navigation,
present in that form on every screen, with the active item as a white rounded tile carrying a teal
glyph — a **65px white top bar** (tenant logo + name at left,
notification bell with a red count badge and the user block at right), and a scrolling content
region on `#F4F4F4` with a **24px gutter**. When a section has sub-navigation the rail narrows to
44px and turns white, and a 216px white flyout panel carries the section's items — the `CONVOY`
wordmark replaces the `CV` monogram in that state.

When a section has sub-navigation, a 216px white flyout panel carries the section's items **beside
the dark rail** (the rail does not change), and the `CONVOY` wordmark heads the flyout.

Content is card-based: white cards, 8px radius, 20–24px padding, a 1px `#E0E0E0` hairline under the
card's title row. Cards sit in a single column at full content width, or in a 3-up KPI row.
Long forms are one card per section (`Trip Information`, `Point of Contact`, `Direction 1`…) with a
**sticky action bar at the bottom right** (`Cancel` · `Save Draft` · `Continue ›`). Map screens go
full-bleed: the map fills the region and every control floats on top of it.

### Surfaces, borders, shadows

Separation is done with **hairlines first**: `1px solid #E0E0E0`. Shadows are almost invisible and
only appear when something genuinely floats — `0 1px 2px rgba(22,22,22,.04)` on cards,
`0 4px 16px rgba(22,22,22,.10)` on dropdowns and autocomplete panels, and a slightly heavier
`0 2px 10px rgba(22,22,22,.16)` on map overlays (the vehicle popover, the speed legend capsule, the
trip summary strip) because they sit on photography-like map tiles. No inner shadows anywhere. No
"protection gradient" scrims over maps — Convoy uses **solid white capsules with a radius** to make
text legible on map tiles instead, which is a strong and repeatable motif.

### Corner radii

8px is the system's answer to nearly everything: inputs, selects, buttons, cards, day pills,
scheduler blocks, filter chips, KPI tiles. 4px for small status badges, 3px for checkboxes, 6px for
nav flyout rows and menu items, 12px for popovers and dropdown menus, 16px for large map cards, and
full pills **only** for tag chips and numeric count chips. Avatars and timeline dots are circles.

### Controls, states

- **Selection is a 2px teal border plus a `#E5EDEE` fill** — day-of-week pills, filter chips,
  the `NO/YES` toggle's active half, nav flyout rows. This is the single most recognisable Convoy
  control pattern.
- **Primary button**: `#004F59` fill, white 700 text, 8px radius, 44px tall, optional trailing icon.
  **Secondary**: white fill, 2px `#004F59` border, teal 700 text. **Tertiary**: white fill, 1px
  `#E0E0E0` border, `#212121` 700 text.
- **Hover** darkens by one step (`#004F59 → #20656E`) or, on neutral surfaces, fills with
  `#F4F4F4` — never an opacity change, never a lift.
- **Press** deepens the fill one more step to `#003840`; nothing scales or shrinks.
- **Focus** is a 3px `rgba(0,140,149,.22)` ring.
- **Disabled** greys to `#ACACAC` text on `#F4F4F4`, no opacity tricks.
- Inputs have **no border at rest** — grey fill only; placeholders `#909090`; a right-aligned unit
  suffix (`m`, `Occurences`, `Passengers`) inside the field, in `#212121`.

### Motion

Deliberately dull: 140–200ms fades and colour transitions on `cubic-bezier(.2,0,.2,1)`. Popovers
fade and appear in place (no slide, no scale). Nothing bounces, springs, parallaxes, or animates on
scroll. The only continuously-moving thing in the product is real fleet data — the "now" line on the
scheduler and vehicle markers on the map.

### Transparency and blur

Essentially unused. There is no frosted glass and no `backdrop-filter` in the sources. Translucency
appears in exactly two places: the geofence radius disc on maps (a ~20 %-opacity teal circle) and
the hatched fill on a cancelled scheduler block. Everything else is opaque.

### Imagery

Photographic imagery is **evidence, not decoration**: small circular crops of the actual vehicle
(white Toyota HiAce, minibuses) and driver head-shots, at 40–48px, on white. They're neutral,
daylight, uncorrected — no duotone, no grain, no warm/cool grade. Map tiles are Google's standard
light "roadmap" style; they set the visual temperature of the product (cool greys, pale greens and
yellows) and are the largest coloured area on any screen. There are **no illustrations, no patterns,
no textures and no hand-drawn elements anywhere** in the sources — do not invent them.

---

## ICONOGRAPHY

**System:** Material Symbols Rounded, **filled** (`FILL 1`), loaded from the Google Fonts CDN in
`tokens/fonts.css` and used via `.cv-icon` (see `tokens/base.css`) or the `<Icon>` component.
Every rail glyph in the sources maps to a Material name, so this is a reconstruction of the
product's own set rather than a stylistic substitution — but see ⚠️ 2 above.

- **Size:** 20px is the default; 18px inside dense rows and scheduler blocks; 24px in the rail and
  for map/action icons; 28px for the timeline's state dots.
- **Weight/fill:** filled glyphs for navigation and status, outline (`FILL 0`) for the rare
  secondary affordance (the ⓘ info circle, the bookmark on a saved point).
- **Colour:** `#B5B5B5` for inactive rail glyphs, white for active ones; `#008C95` teal for
  informational icons inside content (calendar, clock, bus, on-time moon in the trip cards);
  `#212121` for neutral controls; `#00C853` / `#FF8400` / `#FF3D17` when the icon *is* the status.
  Icons are never multi-coloured and never have their own background chip, except the round
  timeline markers.
- **Rail inventory (top → bottom, as read from the screenshots):** `dashboard` · `assignment`
  (Trips & Bookings) · `desktop_windows` (Monitoring) · `directions_bus` (Fleet) · `apartment`
  (Clients/Sites) · `school` (Training) · `work` (Jobs) · `insert_chart` (Reports) ·
  `business_center` · `calculate` (Billing) · `policy` · `notification_important` · `settings` ·
  `menu`.
- **Emoji: never.** **Unicode glyphs as icons: never** — even chevrons and arrows are icon glyphs.
- Vehicle and driver **photographs** are used where a photo carries information; icons are never
  used to stand in for a specific vehicle or person.
- ⚠️ The small Google Maps "open in Maps" badge and the Singapore flag in the phone field are
  third-party marks and are not included in `assets/`.

---

## Index

| Path | What's in it |
| --- | --- |
| `styles.css` | Global CSS entry — `@import`s only. Link this one file. |
| `tokens/` | `fonts` · `colors` · `typography` · `spacing` · `radius` · `elevation` · `motion` · `semantic` · `base` |
| `assets/` | Extracted logos, driver avatars, vehicle thumbnails, map plates |
| `components/` | React primitives, grouped by concern — see the table below |
| `ui_kits/fleet_console/` | The five-screen interactive recreation of the Convoy console |
| `guidelines/` | Foundation specimen cards (Colours, Type, Spacing, Brand, Iconography) |
| `sources/` | The original screenshots + measurement crops |
| `SKILL.md` | Agent-Skill wrapper so this folder can be used from Claude Code |

### Components

| Group | Components |
| --- | --- |
| `components/actions/` | `Button`, `IconButton` |
| `components/forms/` | `FieldLabel`, `Input`, `Select`, `Textarea`, `DateField`, `SearchInput`, `Checkbox`, `Radio`, `Switch`, `YesNoToggle`, `SegmentedControl`, `TogglePill`, `TagInput`, `ColorField`, `FileDrop`, `PhoneField` |
| `components/navigation/` | `NavRail`, `NavFlyout`, `TopBar`, `Breadcrumb`, `Stepper`, `Tabs`, `ViewToggle` |
| `components/data/` | `Card`, `StatCard`, `DataTable`, `KeyValueList`, `Timeline`, `LogList`, `SpeedLegend`, `Sparkline` |
| `components/feedback/` | `StatusBadge`, `StatusSegments`, `Tooltip`, `Chip`, `CountChip`, `Avatar`, `FilterChip`, `MetaPill` |
| `components/fleet/` | `SchedulerBlock`, `TripListCard`, `VehicleRow`, `MapOverlayCard` |
| `components/core/` | `Icon` |

**Intentional additions** (not literal components in the sources, added because consumers need them):
- `Icon` — a thin wrapper over the Material Symbols glyph set, so icon size/fill/colour stay
  consistent instead of being re-implemented per screen.
- `CountChip` — the numeric chip that appears inside filter chips and counters in the sources was
  factored out so it can be reused.
- `MetaPill` — the grey `label + value` row from the Reports header, factored out for reuse.

Everything else in the table has a direct counterpart in one of the five source screens.
