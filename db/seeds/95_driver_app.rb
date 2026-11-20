# What the Convoy Driver app recorded on runs that are over: a disposal's start and end odometer, two runs the
# coordinator directed, a 30-minute extension the client signed for and the overtime after it (so Trip History shows the
# actuals, and the bus's next disposal pre-fills its start odometer).
with_company("SD") do
  TripOccurrence.where(kind: "disposal", status: "completed").where.not(vehicle_id: nil).includes(:trip, :disposal).find_each do |occ|
    next if occ.disposal

    start = occ.started_at || occ.starts_at
    booked = (occ.trip.hours.to_f * 60).round
    ended = start + (booked + 30 + 20).minutes # extended 30 min, then 20 min over: 15 billed
    d = occ.create_disposal!(company_id: occ.company_id, booked_minutes: booked, block_starts_at: occ.starts_at, started_at: start,
                             late_minutes: [ ((start - occ.starts_at) / 60).floor, 0 ].max, start_odometer: 45_210, extension_minutes: 30,
                             ended_at: ended, end_odometer: 45_252, released_by: "Alex Hwang · coordinator", km: 42)
    d.runs.create!(started_at: start + 10.minutes, ended_at: start + 35.minutes, from_road: "Marina Boulevard", to_road: "Shenton Way", pax: 12)
    d.runs.create!(started_at: start + 4.hours, ended_at: start + 4.hours + 40.minutes, from_road: "Shenton Way", to_road: "Bayfront Avenue", pax: 11)
    d.extensions.create!(at: start + (booked - 20).minutes, from_minutes: 0, to_minutes: 30, signed_by: "Alex Hwang", operations_told: true)
    figures = d.figures
    d.update!(used_minutes: figures[:used_minutes], overtime_minutes: figures[:overtime_minutes])
    occ.update_columns(driver_end: "completed", end_on_board: 0) # rubocop:disable Rails/SkipsModelValidations
  end
end

# Switch Vehicle: Eric Pang and Frankie Ho swap buses tomorrow from 12:00 (both see the switch card) and go back to
# their own bus the day after (00:00), so Eric's runs stay on PD997M on later days. Eric's handover inspection of his
# bus yesterday morning (six photos, the back one marked up, one photo to highlight).
with_company("SD") do
  eric = Driver.find_by(phone: "+6592104100")
  frankie = Driver.find_by(phone: "+6592474471")
  eric_bus = Vehicle.kept.find_by(plate: "PD997M")
  frankie_bus = Vehicle.kept.find_by(plate: "PC7939R")
  if eric && frankie && eric_bus && frankie_bus
    today = Date.current
    tomorrow = today + 1
    put = lambda do |bus, on, minute, driver|
      entry = bus.driver_schedules.find_or_initialize_by(starts_on: on, start_time: minute)
      entry.update!(driver:) unless entry.driver_id == driver.id
    end
    # Each on their own bus when today starts (a database seeded before this rule kept the last switch for good).
    { eric_bus => eric, frankie_bus => frankie }.each do |bus, driver|
      held = bus.driver_schedules.select { it.started_by?(today, 0) }.max_by(&:sort_key)
      put.(bus, today, 0, driver) unless held&.driver_id == driver.id
    end
    put.(eric_bus, tomorrow, 720, frankie)
    put.(frankie_bus, tomorrow, 720, eric)
    put.(eric_bus, tomorrow + 1, 0, eric)
    put.(frankie_bus, tomorrow + 1, 0, frankie)
    # Runs take the new drivers now (the schedule's own job runs in the background).
    [ eric_bus, frankie_bus ].each { Occurrences::RefreshDrivers.call(vehicle_id: it.id, from: today) }
    # the bell line, for a switch entry changed rather than created (only a new entry rings it)
    [ [ frankie_bus, eric ], [ eric_bus, frankie ] ].each do |bus, driver|
      entry = bus.driver_schedules.find_by(starts_on: tomorrow, start_time: 720)
      next if DriverNotification.exists?(driver:, kind: "vehicle_switch", vehicle: bus, created_at: today.beginning_of_day..)

      DriverApp::RunNotifications.vehicle_switch(entry)
    end

    account = DriverAccount.find_by(phone: eric.phone)
    at = (Date.current - 1).in_time_zone.change(hour: 6, min: 20)
    unless VehicleHandover.exists?(driver: eric, at:)
      h = VehicleHandover.create!(company_id: eric.company_id, vehicle: eric_bus, driver_account: account, driver: eric, client_id: SecureRandom.uuid,
                                  at:, declared_at: at, note: "Small scratch on the rear bumper")
      VehicleHandover::SIDES.each_with_index do |side, i|
        h.photos.create!(side:, photo: SeedFiles.open("fleet", "bus-#{(i % 4) + 1}.png"),
                         marks: side == "back" ? [ { kind: "circle", x: 120, y: 200, r: 30 } ] : [])
      end
    end
    h = VehicleHandover.find_by(driver: eric, at:)
    if h && h.photos.none?(&:highlight?)
      h.photos.create!(side: VehicleHandover::HIGHLIGHT, photo: SeedFiles.open("fleet", "bus-4.png"),
                       marks: [ { kind: "circle", x: 260, y: 140, rx: 40, ry: 28, color: "#E53935" } ])
    end
  end
end

# Driver app sample accounts have runs every day from rules the daily occurrence job extends (not dated rows): Eric
# Pang's disposal every morning on PD997M (08:00–11:30) and an afternoon transfer on Frankie Ho's PC7939R, which Eric
# drives tomorrow after the switch above. School runs (Ah Beng, Lee Kok Wah, Siti Nurhaliza) follow the MOE calendar.
with_company("SD") do
  admin = User.find_by!(email: "ops@simpledrive.sg")
  type = VehicleType.find_by!(key: "van")
  {
    "seed-driver-disposal" => {
      kind: "disposal", client_id: Client.kept.find_by!(name: "DBS Bank").id, title: "DBS Roadshow Disposal", start_time: "08:00", hours: 3.5,
      end_time: nil, hourly_rate: true, price: 75, pax: 6, plate: "PD997M",
      stops_attributes: [ { position: 0, name: "DBS Asia Central", address: "12 Marina Boulevard, Singapore 018982", lat: 1.2795, lng: 103.8540, use: "pu" } ]
    },
    "seed-driver-transfer" => {
      kind: "ad_hoc", client_id: Client.kept.find_by!(name: "Google Asia Pacific").id, title: "MBC to Changi T3 Staff Transfer", start_time: "14:00",
      end_time: "14:50", price: 120, pax: 8, plate: "PC7939R",
      stops_attributes: [
        { position: 0, name: "Mapletree Business City", address: "70 Pasir Panjang Road, Singapore 117371", lat: 1.2747, lng: 103.7993, use: "pu" },
        { position: 1, name: "Changi Airport T3", address: "65 Airport Boulevard, Singapore 819663", lat: 1.3554, lng: 103.9862, use: "do" }
      ]
    }
  }.each do |label, attrs|
    next if Trip.kept.exists?(label:)

    bus = Vehicle.kept.find_by!(plate: attrs.delete(:plate))
    Trips::Save.call(trip: Trip.new(label:), user: admin, attributes: attrs.merge(
      starts_on: Date.current, days: Trip::WEEKDAYS.to_a, end_mode: "never", vehicle_requirements_attributes: [ { vehicle_type_id: type.id, count: 1 } ],
      vehicle_slots_attributes: [ { slot_no: 1, vehicle_id: bus.id } ]
    ))
  end
end

# Kumar s/o Rajan's next run is driven by Shao Dong (Driver Away): Kumar sees it as Replaced. A replacement is dated,
# so each seed gives his next run one unless it already has it.
with_company("SD") do
  kumar = Driver.find_by(phone: "+6590012233")
  cover = Driver.kept.active.find_by(name: "Shao Dong")
  if kumar && cover
    upcoming = TripOccurrence.where(date: Date.current..(Date.current + 7)).where(starts_at: Time.current..).where.not(status: %w[removed cancelled])
    run = upcoming.where(driver_id: kumar.id).or(upcoming.where(original_driver_id: kumar.id)).order(:starts_at).first
    if run && run.driver_id == kumar.id
      Replacements::Save.call(replacement: Replacement.new, occurrence: run, user: User.find_by!(email: "ops@simpledrive.sg"),
                              attributes: { kind: "drv", scope: "run", driver_id: cover.id, reason: "Seed sample: Kumar on leave" })
    end
  end
end

# Notices from SimpleDrive Operations to every driver (the bell): a route change to acknowledge, and the new depot map.
with_company("SD") do
  [
    { kind: "ack", title: "Route change from Friday: Siglap Road side gate closed",
      summary: "St. Stephen's School closes the side gate for works. Drop off at the main gate on Siglap View. Please acknowledge.",
      body: "From Friday the Siglap Road side gate is closed for about three weeks. Route 3 ends at the main gate on Siglap View instead: " \
            "turn in at the second gate, drop at bay 2, exit via Siglap Road. The attendant walks the children in from bay 2. Timing stays " \
            "the same; expect two extra minutes at the gate on the first days.",
      image_caption: "Main gate and bay 2 (photo from the school)", link_label: "Open the new gate map", link_url: "https://simpledrive.sg/maps/sss-gate",
      starts_at: 1.day.ago.change(hour: 8, min: 10) },
    { kind: "view", title: "New depot map and parking bays", summary: "Buses 20 to 48 park in the new row behind the wash bay from Monday.",
      body: "The depot has a new row of bays behind the wash bay. Buses 20 to 48 park there from Monday; the old row near the office becomes " \
            "the visitor area. Your bay number is on the windscreen sticker. Reverse in, keys to the office as usual.",
      image_caption: "Depot plan with the new row marked", link_label: "Depot map (PDF)", link_url: "https://simpledrive.sg/depot",
      starts_at: 2.days.ago.change(hour: 16, min: 30) }
  ].each do |attrs|
    notice = DriverNotice.find_or_initialize_by(title: attrs[:title])
    next if notice.persisted?

    notice.update!(**attrs, from_name: "SimpleDrive Operations", image: SeedFiles.open("fleet", "bus-1.png"))
    DriverNotices::Publish.call(notice:)
  end
end

# How Siti Nurhaliza ended yesterday's runs in the Driver app (Trip Details shows the record): the School Bus run left
# its first point with a child not boarded, skipped the next point and was completed with feedback; a shuttle force
# ended after its first point (Accident); the next shuttle was skipped before the start. Sent through DriverApp::Drive
# with fixed client_ids, so a second seed is replayed, not done again.
with_company("SD") do
  siti = Driver.find_by(phone: "+6590034455")
  account = siti && DriverAccount.for_phone!(siti.phone).tap(&:link_memberships!)
  yesterday = Date.current - 1
  # A database seeded before AM 1 was Siti's (45_school_bus moves it to her bus from the seed day): yesterday's AM 1,
  # never driven in the app, becomes hers.
  am1 = School.find_by(name: "St. Stephen's School")&.plans&.find_by(session: "am", in_use: true)&.routes&.find_by(number: 1)
  am1_run = am1 && TripOccurrence.where.not(status: %w[removed skipped cancelled]).find_by(school_route: am1, date: yesterday)
  if siti && am1_run && am1_run.driver_id != siti.id && am1_run.started_at.nil? && !DriverAppAction.exists?(occurrence_id: am1_run.id)
    am1_run.update_columns(driver_id: siti.id, vehicle_id: Vehicle.kept.find_by!(plate: "PC8841T").id) # rubocop:disable Rails/SkipsModelValidations
  end
  runs = siti ? TripOccurrence.where(driver: siti, date: yesterday).where.not(status: %w[removed skipped]).includes(:stop_events).order(:start_time, :id).to_a : []
  # Runs this seed drove before (replayed by client_id), or runs never driven in the app (other seeds' telematics stop
  # events are cleared below before the run is driven).
  mine = DriverAppAction.where(driver_account: account, occurrence_id: runs.map(&:id)).distinct.pluck(:occurrence_id)
  runs = runs.select { mine.include?(it.id) || (it.started_at.nil? && it.stop_events.none? { |e| e.source == "driver_app" } && !it.cancelled?) }
  drive = lambda do |occ, step, action, at, **params|
    occ.reload
    # The driver did this yesterday, before the job completed the run (92_trip_history runs it): a run completed without
    # a start refuses every action, so a run driven for the first time is reopened, without the stop events another
    # seed made up for it (94_shuttle_report on a database seeded before it left yesterday out).
    if mine.exclude?(occ.id) && DriverApp::Runs.not_driven?(occ)
      OccurrenceStopEvent.where(occurrence_id: occ.id, occurrence_date: occ.date).delete_all
      occ.update_columns(status: "scheduled", max_delay_minutes: nil) # rubocop:disable Rails/SkipsModelValidations
    end
    DriverApp::Drive.call(account:, member: siti, occ:, action:,
                          params: { client_id: Digest::UUID.uuid_v5(Digest::UUID::OID_NAMESPACE, "seed-driver-end-#{occ.id}-#{step}"), at: at.iso8601, **params })
  end
  puts "  Siti's ended runs: no School Bus run yesterday (#{yesterday})" unless runs.any?(&:school_route)
  puts "  Siti's ended runs: fewer than 2 shuttles yesterday (#{yesterday})" if runs.count { it.kind == "corporate_shuttle" } < 2

  if (bus = runs.find(&:school_route))
    t = bus.starts_at
    points = Occurrences::Stops.detailed(bus).reject { it[:waypoint] }
    kids = Occurrences::Passengers.call(bus, points:).select { it[:state] == "expected" }
    drive.(bus, "start", :start, t - 5.minutes)
    points[0..-2].each_with_index do |p, i|
      at = t + (i * 8).minutes
      if i == 1
        drive.(bus, "skip-#{i}", :skip_stop, at, position: p[:position], reason: "Passengers are late")
        next
      end
      drive.(bus, "arrive-#{i}", :arrive, at, position: p[:position])
      here = kids.select { it[:pickup_position] == p[:position] }
      here = here.drop(1) if i.zero? # one child not at the point: the driver leaves anyway
      drive.(bus, "board-#{i}", :attendance, at + 1.minute, marks: here.map { { id: it[:id], state: "boarded", method: "tick" } }) if here.any?
      drive.(bus, "leave-#{i}", :leave, at + 3.minutes, position: p[:position], force: true)
    end
    drive.(bus, "arrive-last", :arrive, bus.ends_at - 2.minutes, position: points.last[:position])
    drive.(bus, "complete", :complete, bus.ends_at, feedback: "Waited at the first point, one child did not come down")
  end

  shuttles = runs.select { it.kind == "corporate_shuttle" }
  if (forced = shuttles.first)
    t = forced.starts_at
    first = Occurrences::Stops.detailed(forced).reject { it[:waypoint] }.first
    drive.(forced, "start", :start, t - 5.minutes)
    drive.(forced, "arrive-0", :arrive, t, position: first[:position])
    drive.(forced, "leave-0", :leave, t + 2.minutes, position: first[:position], boarded: 9, alighted: 0)
    drive.(forced, "force-end", :force_end, t + 12.minutes, reason: "Accident", called_operations: true,
                                                              feedback: "Minor collision at the junction, nobody hurt. Passengers walked to the office")
  end
  if (skipped = shuttles.second)
    drive.(skipped, "skip", :skip, skipped.starts_at - 20.minutes, reason: "Traffic Congestion")
  end
end

# Vehicle History (the buses driven each day) counts runs started in the app. Siti's and Tony Tan's runs of the five
# days before yesterday, completed by the job without a start, are marked as driven: started 5 minutes early, ended at
# the last arrival (94_shuttle_report's stop events) or the planned end.
with_company("SD") do
  [ Driver.find_by(phone: "+6590034455"), OperatorDriver.find_by(phone: "+6595807810") ].compact.each do |member|
    col = member.is_a?(OperatorDriver) ? :operator_driver_id : :driver_id
    TripOccurrence.where(col => member.id, date: (Date.current - 6)...(Date.current - 1), status: "completed", started_at: nil, ended_at: nil)
                  .includes(:stop_events).each do |occ|
      ended = [ occ.ends_at, *occ.stop_events.filter_map(&:arrived_at) ].max
      occ.update_columns(started_at: occ.starts_at - 5.minutes, ended_at: ended, driver_end: occ.driver_end || "completed", end_on_board: 0) # rubocop:disable Rails/SkipsModelValidations
    end
  end
end
