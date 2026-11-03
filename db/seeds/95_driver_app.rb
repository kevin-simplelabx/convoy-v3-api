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

# Switch Vehicle: Eric Pang and Frankie Ho swap buses tomorrow from 12:00 (both see the switch card), and Eric's
# handover inspection of his bus yesterday morning (six photos, the back one marked up).
with_company("SD") do
  eric = Driver.find_by(phone: "+6592104100")
  frankie = Driver.find_by(phone: "+6592474471")
  eric_bus = eric&.vehicle_on(Date.current)
  frankie_bus = frankie&.vehicle_on(Date.current)
  if eric_bus && frankie_bus
    tomorrow = Date.current + 1
    eric_bus.driver_schedules.find_or_create_by!(starts_on: tomorrow, start_time: 720) { it.driver = frankie }
    frankie_bus.driver_schedules.find_or_create_by!(starts_on: tomorrow, start_time: 720) { it.driver = eric }
    # the bell line, for a database seeded before the switch rang it
    [ [ frankie_bus, eric ], [ eric_bus, frankie ] ].each do |bus, driver|
      entry = bus.driver_schedules.find_by(starts_on: tomorrow, start_time: 720)
      DriverApp::RunNotifications.vehicle_switch(entry) unless DriverNotification.exists?(driver:, kind: "vehicle_switch", vehicle: bus)
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
