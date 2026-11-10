# Client Portal bookings (moved out of 46_bookings: they need the clients and portal users of 47_client_records, so a clean seed works in one run).
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
