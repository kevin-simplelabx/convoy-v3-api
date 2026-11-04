# Bookings (from the Convoy OS sample bkSeed): Google over three days (Two Way, One Way, Disposal, Airport) ready for
# approval, DBS waiting for the client to acknowledge a change, Marina Bay Sands rejected, Tan Family ready for approval;
# then the approval flow: Google approved (Scheduler trips, Unassigned) with an open cancellation request, Google
# completed last week, a DBS booking taken by phone, and the bell's events. Client Portal bookings: at the end.
# Dates follow today; keyed by PO number.
with_company("SD") do
  ops = User.find_by!(email: "ops@simpledrive.sg")
  types = VehicleType.enabled_for(ActsAsTenant.current_tenant).order(:seats).to_a
  v13 = types.find { |t| t.seats == 13 } || types.first
  v23 = types.find { |t| t.seats == 23 } || types.second || types.first
  today = Date.current
  pt = ->(name, use, lat, lng, note = nil) { { name:, use:, lat:, lng:, note: } }
  veh = ->(*list) { list.map { |type, count| { vehicle_type_id: type.id, count: } } }

  record = lambda do |client_name, po_number, coordinator, days, status: nil, extra: {}, &after|
    client = Client.kept.find_by!(name: client_name)
    next if Booking.exists?(client:, po_number:)

    booking = Bookings::Save.call(booking: Booking.new, actor: ops, params: {
      client_id: client.id, po_number:, days:, **coordinator, **extra
    })
    after&.call(booking)
    next unless status

    booking.trips.update_all(status:)
    booking.update!(estimate_amount: 0) if status == "rejected"
  end

  record.("Google Asia Pacific", "PO-GA-2026-131",
          { coordinator_name: "Jason Lee", coordinator_org: "Google Asia Pacific", coordinator_email: "jason.lee@google.example", coordinator_phone: "+65 8789 1011" }, [
            { date: today + 6, trips: [
              { kind: "two_way", start_time: "08:00", return_time: "19:00", pax: 30, contact_name: "Benjamin Loo", contact_phone: "+65 8789 2212",
                distance_km: 9.8, points: [ pt.("Boon Lay Shopping Centre", "pu", 1.3483, 103.7059), pt.("Jurong East", "both", 1.3331, 103.7422),
                                            pt.("Jurong West", "do", 1.3404, 103.7090) ],
                standby: { location: "Boon Lay Bus Interchange", minutes: 15 }, vehicles: veh.([ v13, 1 ], [ v23, 1 ]) },
              { kind: "one_way", start_time: "13:30", pax: 18, contact_name: "Benjamin Loo", contact_phone: "+65 8789 2212", distance_km: 24.5,
                points: [ pt.("One-North", "pu", 1.2995, 103.7873), pt.("Changi Business Park", "do", 1.3341, 103.9625) ], vehicles: veh.([ v23, 1 ]) }
            ] },
            { date: today + 7, trips: [
              { kind: "disposal", start_time: "09:00", hours: 5, pax: 20, note: "Client site visits, driver to stay with the group",
                points: [ pt.("One-North", "pu", 1.2995, 103.7873) ], vehicles: veh.([ v23, 1 ]) }
            ] },
            { date: today + 8, trips: [
              { kind: "airport", airport_direction: "departure", flight_number: "SQ638", terminal: "T3", start_time: "06:30", pax: 6,
                luggage_on: true, luggage_large: 6, luggage_cabin: 2, distance_km: 20.1,
                points: [ pt.("Pan Pacific Hotel", "pu", 1.2913, 103.8586), pt.("Changi Airport T3", "do", 1.3557, 103.9864) ], vehicles: veh.([ v13, 1 ]) }
            ] }
          ])

  record.("DBS Bank", "PO-DBS-0428",
          { coordinator_name: "Jason Lim", coordinator_org: "DBS Bank", coordinator_email: "facilities@dbs.example", coordinator_phone: "+65 6511 1111" }, [
            { date: today + 4, trips: [
              { kind: "two_way", start_time: "08:30", return_time: "17:30", pax: 22, contact_name: "Jason Lim", contact_phone: "+65 9001 2233", distance_km: 14.2,
                points: [ pt.("Boon Lay Shopping Centre", "pu", 1.3483, 103.7059), pt.("Science Centre Singapore", "both", 1.3332, 103.7357),
                          pt.("Pioneer Mall", "do", 1.3417, 103.6974) ], vehicles: veh.([ v23, 1 ]) }
            ] }
          ], status: "awaiting_ack", extra: { cost_centre: "FAC-SG" })

  record.("Marina Bay Sands", "PO-MBS-77",
          { coordinator_name: "Rebecca Chua", coordinator_org: "Marina Bay Sands", coordinator_email: "events@mbs.example", coordinator_phone: "+65 6688 8888" }, [
            { date: today + 3, trips: [
              { kind: "one_way", start_time: "22:30", pax: 40, distance_km: 6.2, note: "Gala dinner guests",
                points: [ pt.("Marina Bay Sands Expo", "pu", 1.2834, 103.8607), pt.("Raffles Hotel", "do", 1.2949, 103.8545) ], vehicles: veh.([ v23, 2 ]) }
            ] }
          ], status: "rejected")

  record.("Tan Family", "TAN-WEDDING",
          { coordinator_name: "Tan Wei Ming", coordinator_email: "weiming.tan@gmail.com", coordinator_phone: "+65 9123 4567" }, [
            { date: today + 9, trips: [
              { kind: "airport", airport_direction: "arrival", flight_number: "CX715", terminal: "T4", wait_minutes: 60, meet_and_greet: true,
                signboard_name: "Tan Family", start_time: "15:40", pax: 8, luggage_on: true, luggage_large: 8, distance_km: 22.4,
                points: [ pt.("Changi Airport T4", "pu", 1.3383, 103.9832), pt.("Shangri-La Hotel", "do", 1.3109, 103.8268) ], vehicles: veh.([ v13, 1 ]) }
            ] }
          ])

  # DBS: what changed on the trip waiting for acknowledgement.
  dbs_trip = Booking.find_by!(po_number: "PO-DBS-0428").trips.first
  dbs_trip.changes_made.create!(changed_by: ops, items: [ "Pick-up time: 08:00 to 08:30", "Passengers: 18 to 22" ]) if dbs_trip.changes_made.none?

  google = { coordinator_name: "Jason Lee", coordinator_org: "Google Asia Pacific", coordinator_email: "jason.lee@google.example", coordinator_phone: "+65 8789 1011" }
  record.("Google Asia Pacific", "PO-GA-2026-118", google, [
            { date: today + 2, trips: [
              { kind: "one_way", start_time: "08:15", pax: 12, distance_km: 18.4,
                points: [ pt.("Mapletree Business City", "pu", 1.2747, 103.7990), pt.("Changi Business Park", "do", 1.3341, 103.9625) ], vehicles: veh.([ v13, 1 ]) },
              { kind: "two_way", start_time: "09:00", return_time: "17:00", pax: 20, distance_km: 12.0,
                points: [ pt.("Mapletree Business City", "pu", 1.2747, 103.7990), pt.("Singapore Expo", "do", 1.3349, 103.9584) ], vehicles: veh.([ v23, 1 ]) }
            ] }
          ]) do |booking|
    one, two = booking.trips.order(:position).to_a
    Bookings::Approve.call(trip: one, user: ops, trip_value: 1)
    Bookings::Approve.call(trip: two.reload, user: ops, trip_value: 1, return_trip_value: 1)
    Bookings::CancelRequest.record(booking:, trip: one.reload, reason: "Team offsite moved to next week", by_name: "Jason Lee", actor: ops, at: 2.hours.ago)
  end

  record.("Google Asia Pacific", "PO-GA-2026-097", google, [
            { date: today - 5, trips: [
              { kind: "one_way", start_time: "18:30", pax: 9, distance_km: 7.5,
                points: [ pt.("Google Asia Pacific, MBC", "pu", 1.2747, 103.7990), pt.("Marina Bay Sands Expo", "do", 1.2834, 103.8607) ], vehicles: veh.([ v13, 1 ]) }
            ] }
          ]) do |booking|
    Bookings::Approve.call(trip: booking.trips.first, user: ops, trip_value: 1)
  end

  record.("DBS Bank", "PO-DBS-0502",
          { coordinator_name: "Grace Ong", coordinator_org: "DBS Bank", coordinator_email: "grace.ong@dbs.example", coordinator_phone: "+65 9233 4411" }, [
            { date: today + 5, trips: [
              { kind: "one_way", start_time: "07:45", pax: 15, distance_km: 21.0,
                points: [ pt.("Tampines Central", "pu", 1.3533, 103.9452), pt.("Marina Bay Financial Centre", "do", 1.2789, 103.8536) ], vehicles: veh.([ v23, 1 ]) }
            ] }
          ], extra: { cost_centre: "OPS-SG" })
  # Before the Client Portal this booking was a stand-in for one awaiting the client's own approval (no approval kept).
  legacy = Booking.find_by(po_number: "PO-DBS-0502")
  if legacy && legacy.approval.nil? && legacy.trips.any?(&:awaiting_client?)
    legacy.trips.where(status: "awaiting_client").update_all(status: "pending") # rubocop:disable Rails/SkipsModelValidations
    legacy.update!(source: "console")
  end
end

# Client Portal: St. Stephen's School books a Sentosa excursion in the portal (Priya Raman, a Member). The school has no
# approval flow, so it goes straight to us (bell: New booking).
with_company("SD") do
  sss = Client.kept.find_by!(name: "St. Stephen's School")
  priya = sss.users.kept.find_by(email: "priya.raman@google.com")
  if priya && !sss.bookings.exists?(po_number: "SSS-EXC-01")
    types = VehicleType.enabled_for(ActsAsTenant.current_tenant).order(:seats).to_a
    bus = types.find { |t| t.seats >= 40 } || types.last
    date = Date.current + 9
    Portal::SubmitBooking.call(client_user: priya, params: {
      coordinator_name: "Priya Raman", coordinator_email: "priya.raman@google.com", coordinator_phone: "+65 9123 7788", po_number: "SSS-EXC-01",
      notes: "Primary 4 learning journey", days: [ { date: date.iso8601, trips: [
        { kind: "two_way", start_time: "08:30", return_time: "14:00", pax: 38, contact_name: "Mrs Lee", contact_phone: "+65 6241 1243",
          points: [ { name: "St. Stephen's School", use: "pu", lat: 1.3156, lng: 103.9262 },
                    { name: "Sentosa, Siloso Beach", use: "do", lat: 1.2550, lng: 103.8100 } ],
          vehicles: [ { vehicle_type_id: bus.id, count: (38.0 / bus.seats).ceil } ] }
      ] } ]
    })
  end
end

# Client Portal bookings at Google, through its approval flows (47_client_records): Marcus Lim (Events & People, MBC) waits
# for MBC's Site Admins; Sarah Ng's airport transfer at Pasir Panjang was approved by Aisha Rahman (Pasir Panjang's own
# flow) and sent to us, then we changed the pick-up time (Changes to Review); Marcus's short-notice booking was declined
# by his team's manager, Linh Tran.
with_company("SD") do
  ops = User.find_by!(email: "ops@simpledrive.sg")
  google = Client.kept.find_by!(name: "Google Asia Pacific")
  user = ->(email) { google.users.kept.find_by!(email:) }
  mbc = google.sites.find_by!(name: "Mapletree Business City")
  pp = google.sites.find_by!(name: "Google Asia Pacific (Pasir Panjang)")
  types = VehicleType.enabled_for(ActsAsTenant.current_tenant).order(:seats).to_a
  bookable = google.bookable_vehicle_types.pluck(:vehicle_type_id)
  v13 = types.find { |t| bookable.include?(t.id) } || types.first
  submit = lambda do |po_number, by, site, date, trip|
    next google.bookings.find_by(po_number:) if google.bookings.exists?(po_number:)

    Portal::SubmitBooking.call(client_user: user.(by), params: {
      client_site_id: site.id, coordinator_name: user.(by).name, coordinator_email: by, po_number:,
      days: [ { date: date.iso8601, trips: [ trip.merge(vehicles: [ { vehicle_type_id: v13.id, count: 1 } ]) ] } ]
    })
  end
  pt = ->(name, use, lat, lng) { { name:, use:, lat:, lng: } }

  submit.("PO-GP-1001", "marcus.lim@google.com", mbc, Date.current + 8,
          { kind: "one_way", start_time: "18:00", pax: 12, points: [ pt.("Mapletree Business City", "pu", 1.2747, 103.7993), pt.("Gardens by the Bay", "do", 1.2816, 103.8636) ] })

  airport = submit.("PO-GP-1002", "sarah.ng@google.com", pp, Date.current + 4,
                    { kind: "airport", start_time: "07:30", pax: 6, airport_direction: "arrival", flight_number: "SQ 321", terminal: "T3", wait_minutes: 60,
                      points: [ pt.("Changi Airport T3", "pu", 1.3554, 103.9867), pt.("Google Asia Pacific (Pasir Panjang)", "do", 1.2768, 103.7952) ] })
  if airport.approval&.waiting?
    Portal::Approval.for(airport).approve!(user.("aisha.rahman@google.com"), note: "Visitors from Mountain View")
    airport.reload
    day = airport.days.first
    Bookings::Save.call(booking: airport, actor: ops, lock_version: airport.lock_version, params: {
      client_id: google.id, client_site_id: pp.id, coordinator_name: airport.coordinator_name, coordinator_email: airport.coordinator_email, po_number: airport.po_number,
      days: [ { id: day.id, date: day.date.iso8601, trips: [ BookingTripBlueprint.render_as_hash(day.trips.first)
        .slice(:kind, :pax, :airport_direction, :flight_number, :terminal, :wait_minutes, :points)
        .merge(id: day.trips.first.id, start_time: "08:00", vehicles: [ { vehicle_type_id: v13.id, count: 1 } ]) ] } ]
    })
  end

  late = submit.("PO-GP-1003", "marcus.lim@google.com", mbc, Date.current + 1,
                 { kind: "one_way", start_time: "09:00", pax: 8, points: [ pt.("Mapletree Business City", "pu", 1.2747, 103.7993), pt.("Suntec City", "do", 1.2935, 103.8572) ] })
  Portal::Approval.for(late).decline!(user.("linh.tran@google.com"), note: "Please use the 08:30 shuttle tomorrow") if late.approval&.waiting?
end
