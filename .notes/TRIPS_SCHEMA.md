# Trip Schema Design

## Approach: Hybrid (Template + Occurrences + Segments)

Based on RFC 5545 (iCal) — same pattern used by Google Calendar.

### Core idea

- `trips` — one row per **segment** of a series (not one row per occurrence)
- `trip_occurrences` — one row per occurrence that **deviates** from the template (assignment override, cancellation)
- Occurrences with no override row → inherit everything from the template

---

## Schema

```ruby
create_table :trips do |t|
  t.string  :id,          null: false, primary_key: true
  t.string  :series_id                    # groups segments of the same logical series
  t.bigint  :company_id,  null: false

  # Recurrence
  t.integer :days,        array: true, default: []  # 0=Sun … 6=Sat
  t.date    :date,        null: false               # segment start date
  t.date    :until_date                             # nil = open-ended
  t.string  :end_mode,    default: "never"          # never | date | count
  t.integer :occ_count                              # used when end_mode = count

  # Default vehicle (can be overridden per occurrence)
  t.bigint  :vehicle_id

  # Trip content — all stop data lives here, not expanded per occurrence
  t.jsonb   :stops,       default: []   # [{id, name, lat, lng, photos, instructions, ...}]
  t.string  :kind                       # Ad Hoc / Charter | Corporate Shuttle | etc.
  t.string  :title
  t.string  :start_time
  t.string  :end_time
  t.string  :customer
  t.string  :contact_name
  t.string  :contact_phone
  t.text    :notes
  t.boolean :skip_ph,     default: true
  t.jsonb   :extra,       default: {}   # catch-all for future fields

  t.string  :by_user
  t.boolean :sample,      default: false
  t.timestamps
end

add_index :trips, :series_id
add_index :trips, [:company_id, :date]
add_index :trips, :vehicle_id

create_table :trip_occurrences do |t|
  t.string  :trip_id,     null: false   # FK → trips
  t.date    :occ_date,    null: false
  t.bigint  :vehicle_id                 # nil = use template default
  t.boolean :cancelled,   default: false
  t.string  :cancelled_by
  t.jsonb   :extra,       default: {}   # stop override for this date only (rare)
  t.timestamps
end

add_index :trip_occurrences, [:trip_id, :occ_date], unique: true
add_index :trip_occurrences, [:vehicle_id, :occ_date]
```

---

## How each requirement is handled

### 1. Change stop/contact/start time — apply from a date range

Use **segment splitting**, not occurrence overrides.

When user says "apply from date X":
1. Set `until_date = X - 1` on the current segment
2. Create a new segment row with `date = X`, same `series_id`, new stop/contact/time data

```
series_id=s1  date=2026-01-01  until=2026-10-31  stops=[A,B,C]  start=07:30
series_id=s1  date=2026-11-01  until=null        stops=[A,B,D]  start=07:45  ← new stops from Nov
```

User sees one logical trip; app manages the segments transparently.

### 2. Trip with no end date

`until_date = NULL`, `end_mode = "never"`. The template row stays forever.
Never expanded to occurrence rows — generated on-the-fly only when needed for a specific date range.

### 3. Query "what trips are this week?"

```ruby
# Step 1: fetch templates that overlap this week
templates = Trip
  .where(company_id: cid)
  .where("date <= ?", week_end)
  .where("until_date IS NULL OR until_date >= ?", week_start)

# Step 2: expand in app (7 days max — cheap)
occurrences = templates.flat_map do |t|
  (week_start..week_end).filter_map do |date|
    next unless t.days.include?(date.wday)
    next unless date >= t.date
    next if t.until_date && date > t.until_date
    { trip: t, date: date }
  end
end

# Step 3: merge overrides
overrides = TripOccurrence
  .where(trip_id: templates.map(&:id), occ_date: week_start..week_end)
  .index_by { |o| [o.trip_id, o.occ_date] }

occurrences.reject! { |o| overrides[[o[:trip].id, o[:date]]]&.cancelled }
occurrences.each do |o|
  ov = overrides[[o[:trip].id, o[:date]]]
  o[:vehicle_id] = ov&.vehicle_id || o[:trip].vehicle_id
end
```

### 4. Query "how many trips did vehicle X have this month?"

```ruby
month = Date.new(2026, 10, 1)..Date.new(2026, 10, 31)

# Occurrences explicitly assigned to this vehicle
from_overrides = TripOccurrence
  .where(vehicle_id: vid, occ_date: month, cancelled: false)
  .count

# Templates where this vehicle is the default — count days not overridden
templates = Trip.where(vehicle_id: vid).where("date <= ?", month.last)
                .where("until_date IS NULL OR until_date >= ?", month.first)

overridden_days = TripOccurrence
  .where(trip_id: templates.map(&:id), occ_date: month)
  .pluck(:trip_id, :occ_date)
  .to_set

from_templates = templates.sum do |t|
  month.count do |date|
    t.days.include?(date.wday) &&
      date >= t.date &&
      (t.until_date.nil? || date <= t.until_date) &&
      !overridden_days.include?([t.id, date])
  end
end

total = from_overrides + from_templates
```

### 5. Query "today's trips for driver X"

Driver is assigned to a vehicle. Find the vehicle, then query for today.

```ruby
vehicle = Vehicle.find_by(driver_id: driver_id, company_id: cid)
# same as query #3 but for 1 day and filtered to vehicle
```

---

## Point-in-time data (snapshot on dispatch)

Admin có thể thay đổi vehicle/driver bất cứ lúc nào. Nếu chỉ lưu FK thì report sẽ sai — query lấy current state thay vì state lúc trip xảy ra.

**Pattern: Slowly Changing Dimension Type 4** — master table giữ current state, `trip_occurrences` giữ historical snapshot.

### Khi nào snapshot

Không snapshot khi schedule (driver có thể bị swap ngay trước giờ chạy). Snapshot khi **dispatch** (T-30 phút) hoặc khi **driver bấm start trip**.

### trip_occurrences mở rộng

```ruby
create_table :trip_occurrences do |t|
  t.string  :trip_id,       null: false   # FK → trips
  t.date    :occ_date,      null: false

  # FK — để query/join nhanh
  t.bigint  :vehicle_id
  t.bigint  :driver_id

  # Snapshot tại thời điểm dispatch/start — không đổi dù admin sửa sau
  t.string  :vehicle_plate
  t.string  :driver_name
  t.string  :driver_phone
  t.string  :operator_name  # nếu là xe thuê ngoài

  # Lifecycle
  t.string   :status,       default: "scheduled"  # scheduled | started | completed | cancelled
  t.datetime :started_at
  t.datetime :ended_at
  t.string   :cancelled_by

  t.boolean :cancelled,     default: false
  t.jsonb   :extra,         default: {}
  t.timestamps
end
```

### Tại sao giữ cả FK lẫn snapshot

- FK (`vehicle_id`, `driver_id`): query "xe này tháng này bao nhiêu trips" — dùng index, nhanh
- Snapshot (`vehicle_plate`, `driver_name`...): report hiển thị — luôn chính xác dù master đã thay đổi

---

## cancel, drv, rep — current JSONB structure

### `sched.cancel`
Map, key = trip occurrence key:
```json
{ "t_abc|2026-10-14": { "by": "Kevin", "at": "2026-10-14" } }
```

### `sched.drv`
Override driver name/phone cho 1 trip cụ thể:
```json
{ "t_abc|2026-10-14": { "name": "Ahmad", "phone": "91234567", "by": "Kevin" } }
```

### `sched.rep`
Array, 2 dạng:
- **Trip-scoped** (`key` có giá trị): ảnh hưởng 1 occurrence cụ thể
- **Date range-scoped** (`key` null, `from`/`to` trên `vid0`): ảnh hưởng tất cả trips của xe trong khoảng ngày

4 loại: `drv` (driver swap), `veh` (vehicle down), `crew` (crew swap), `hand` (handover giữa chừng).

`cancel` và `drv` → merge vào `trip_occurrences` dễ dàng.
`rep` cần bảng riêng vì date-range scope ảnh hưởng nhiều occurrences cùng lúc.

```ruby
create_table :trip_replacements do |t|
  t.string  :id,        null: false, primary_key: true
  t.bigint  :company_id, null: false
  t.string  :kind                    # drv | veh | crew | hand
  t.string  :occurrence_key          # nil = date range scope
  t.string  :vid0                    # original vehicle
  t.string  :vid                     # replacement vehicle
  t.string  :driver_id
  t.string  :driver_name
  t.string  :driver_phone
  t.date    :from
  t.date    :to
  t.string  :pay                     # orig | new | both | split
  t.integer :pct                     # split %
  t.string  :handover_stop
  t.string  :handover_time
  t.text    :reason
  t.string  :by_user
  t.jsonb   :notify,    default: {}
  t.timestamps
end
```

---

## Shuttle run grouping

Mỗi shuttle run (timing) là 1 `trips` row riêng cùng `series_id`. Admin có thể group một số runs lại — khi drag 1 run sang xe khác trong Scheduler, các run cùng group tự đi theo.

Dùng `run_group_id` column (Cách A):

```ruby
t.string :run_group_id   # nil = không group; cùng value = move together
```

```
id=t1  series_id=s1  run_group_id=rg_a  start=07:00
id=t2  series_id=s1  run_group_id=rg_a  start=07:30  ← cùng group với t1
id=t3  series_id=s1  run_group_id=nil   start=08:00
```

Khi split series (thay đổi stops từ ngày X) → copy `run_group_id` sang segment mới.

### Application logic khi implement

**Drag 1 run → tạo nhiều occurrence rows**

Khi user drag run A (có `run_group_id`) sang xe V cho ngày D, phải tạo occurrence cho tất cả runs cùng group — không chỉ run được drag:

```ruby
runs = Trip.where(run_group_id: trip.run_group_id, series_id: trip.series_id)
runs.each do |run|
  TripOccurrence.upsert(trip_id: run.id, occ_date: date, vehicle_id: vehicle_id)
end
```

**Thay đổi grouping áp dụng từ ngày X**

Grouping sống ở `trips` (template level) → apply cho toàn bộ series. Nếu user muốn bỏ group từ ngày X trở đi, phải split series — tạo segment mới không có `run_group_id`. Đây là hệ quả tự nhiên của hybrid approach, cần document rõ trong UX.

---

## Migration path from current settings JSONB

Current state: all scheduler data lives in `companies.settings.sched` (trips, occ, cancel, drv, rep).

Steps when ready to migrate:
1. Add `series_id` to existing `trips` table + create `trip_occurrences` table
2. Add `saveTrip` / `deleteTrip` / `listTrips` methods to `standalone-api.js`
3. FE calls `/api/v1/trips` instead of bundling trips inside `saveSettings`
4. Write a one-time rake task to move `settings.sched.trips` → `trips` table and `settings.sched.occ` → `trip_occurrences`
5. Remove `sched.trips` and `sched.occ` from settings; keep only `sched.cancel`, `sched.drv`, `sched.rep` until those get their own tables too
