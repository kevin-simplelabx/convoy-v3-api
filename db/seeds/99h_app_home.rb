# Convoy App Home, Activity, Alerts (Phase 8). The writers already ran in 99c–99g (invites, request status, booking confirmed /
# changed, shuttle changes); this adds what needs a live moment, so every seeded person has a full inbox and Home:
# - a St. Stephen's notice to parents ("Early Dismissal", banner, in force for 3 days) and a Google MBC shuttle notice to riders,
#   copied into the inboxes by the real job (ConvoyApp::Alerts::Sweep);
# - the Tan Family's bills issued in 99e as bill alerts (Rachel is the Billing Contact);
# - Ethan's School Bus day yesterday (boarded, alighted) and a running-late alert this morning (Home banner until tonight) for
#   Rachel and David, the older ones read.
# Idempotent: notices by message, alerts by dedupe key.
rachel = AppIdentity.find_by!(kind: "mobile", value: ConvoyApp.normalize("mobile", "+65 9188 2045")).app_account
household = rachel.household or raise "Run 99b_app_household.rb first"
ethan = household.dependants.find_by!(name: "Ethan Tan")
adults = ConvoyApp::Alerts.adults_of([ household.id ])[household.id]

with_company("SD") do
  admin = User.find_by!(email: "ops@simpledrive.sg")
  school = School.find_by!(name: "St. Stephen's School")
  wed = Date.current + 1
  wed += 1 until wed.wednesday?
  text = "Early Dismissal on #{wed.strftime('%a %-d %b')}. School ends 11:30; the afternoon bus leaves at 11:40."
  Notice.find_by(message: text) ||
    Notices::Save.call(notice: Notice.new(audience: "school", school:, to_parents: true, to_riders: false, banner: true, push: true),
                       attributes: { message: text }, user: admin, start: "now", period_minutes: 3 * 24 * 60)

  mbc = Trip.kept.find_by!(label: "seed-mbc-shuttle")
  shuttle_text = "Alexandra Road pick-up moves to the bus bay opposite Blk 1 from next Monday (road works)."
  Notice.find_by(message: shuttle_text) ||
    Notices::Save.call(notice: Notice.new(audience: "trip", trip: mbc, to_riders: true, banner: true),
                       attributes: { message: shuttle_text }, user: admin, start: "now", period_minutes: 2 * 24 * 60)

  family = Family.find_by!(school:, household_id: household.id)
  ConvoyApp::Alerts::Bills.call(SchoolBill.where(family:, status: "issued").to_a)

  rider = FamilyRider.find_by!(dependant_id: ethan.id)
  am = SchoolRouteRider.joins(school_route: :plan).where(rid: rider.rid, school_plans: { school_id: school.id, session: "am" }).includes(:stop, school_route: :plan).first
  if am
    route = am.school_route
    yesterday = Date.current - 1
    morning = Time.current.beginning_of_day + 7.hours
    plate = route.vehicle_changes.order(:effective_from).last&.vehicle&.plate || "SBA3546K"
    rows = [
      { kind: "school_boarded", title: "Ethan Tan boarded", body: "Boarded Bus #{plate} at #{am.stop.name}.", created_at: yesterday.in_time_zone + 6.hours + 32.minutes,
        read_at: yesterday.in_time_zone + 7.hours, target: "live", target_id: ethan.id, dedupe_key: "seed:school:boarded:#{yesterday}" },
      { kind: "school_alighted", title: "Ethan Tan alighted", body: "Arrived at #{school.name}.", created_at: yesterday.in_time_zone + 7.hours + 18.minutes,
        read_at: yesterday.in_time_zone + 8.hours, dedupe_key: "seed:school:alighted:#{yesterday}" },
      { kind: "school_late", title: "Bus #{plate} running 5 min late", body: "New pick-up ETA #{(morning - 25.minutes).strftime('%H:%M')} at #{am.stop.name}.",
        created_at: [ morning - 50.minutes, Time.current ].min, banner_until: Time.current.end_of_day, target: "live", target_id: ethan.id,
        dedupe_key: "seed:school:late:#{Date.current}" }
    ]
    ConvoyApp::Alerts.write(adults.flat_map do |id|
      rows.map { it.merge(app_account_id: id, company_id: school.company_id, dependant_id: ethan.id, read_at: it[:read_at], target: it[:target], target_id: it[:target_id]) }
    end)
  end
end

# Priya's and Rachel's bookings (99g): confirmed trips and changes waiting for them (the writers run on those events; repeated
# here so a database seeded before Phase 8 has them too).
priya = AppIdentity.find_by!(kind: "mobile", value: ConvoyApp.normalize("mobile", "+65 9166 7720")).app_account
(ConvoyApp::Bookings.accounts(priya) + ConvoyApp::Bookings.accounts(rachel)).each do |acc|
  ConvoyApp::Bookings.within(acc) do
    ConvoyApp::Bookings.visible(acc).includes(:company, :client, :created_by_client_user, trips: :day).find_each do |b|
      b.trips.select(&:approved?).each { ConvoyApp::Alerts::Bookings.call(booking: b, kind: "confirmed", trip: it) }
      changed = b.trips.select(&:awaiting_ack?)
      ConvoyApp::Alerts::Bookings.call(booking: b, kind: "changed", at: changed.map(&:updated_at).max) if changed.any?
    end
  end
end

ConvoyApp::Alerts::Sweep.call
counts = AppNotification.group(:app_account_id).count
AppAccount.where(id: counts.keys).find_each do |a|
  puts "Convoy App Alerts: #{a.display_name} has #{counts[a.id]} alerts (#{a.notifications.unread.count} unread)"
end
