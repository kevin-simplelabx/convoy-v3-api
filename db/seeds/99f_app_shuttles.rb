# Convoy App Shuttles (Phase 6): Rachel Tan (rachel.tan@google.com, 99a / 99c) accepts Google Asia Pacific's staff shuttle, so she
# sees the seeded routes of 41_shuttles.rb (MBC Campus Shuttle with tags Campus / Staff / the MBC site, and the Cross-site Shuttle):
# - My Usual Shuttle = MBC Campus Shuttle, morning 07:45, boarding at Alexandra Road; MBC pinned; its alerts on by default;
# - changes on the next weekday: a relief driver on the 07:45 (bus 1), another bus on the 08:15 (bus 2), and the Cross-site
#   14:00 run the day after cancelled, so the 14-day strip, the change cards and the alert job have something to show.
# Idempotent: the link is accepted once, the usual and pin are set to values, the changes are skipped when they were made.
work = AppIdentity.find_by!(kind: "email", value: "rachel.tan@google.com")
account = work.app_account
ConvoyApp::Links::Match.call(account:)

rider = ActsAsTenant.without_tenant { ClientRider.find_by!(app_account_id: account.id) }
ConvoyApp::Links::Answer.call(account:, kind: "shuttle", id: rider.id, accept: true) if rider.invited?

employer = ConvoyApp::Shuttles.employer!(account, rider.id)

with_company("SD") do
  admin = User.find_by!(email: "ops@simpledrive.sg")
  google = Client.kept.find_by!(name: "Google Asia Pacific")
  mbc = Trip.kept.find_by!(label: "seed-mbc-shuttle")
  cross = Trip.kept.find_by!(label: "seed-cross-site")

  run = mbc.runs.find { it.direction == 1 && it.start_time == Clock.minutes("07:45") }
  stop = mbc.stops.find { it.name == "Alexandra Road (Opp Blk 1)" }
  ConvoyApp::Shuttles::Usual.save(account:, employer:, trip_id: mbc.id, run_id: run.id, stop_id: stop.id)
  ConvoyApp::Shuttles::Marks.pin(account:, employer:, trip_id: mbc.id, pinned: true)

  unless Replacement.exists?(reason: "Seed sample app shuttle")
    day = Date.current + 1
    day += 1 while day.saturday? || day.sunday?
    bus = ->(plate) { Vehicle.kept.find_by!(plate:) }
    occ = ->(trip, date, time, slot) do
      TripOccurrence.visible.find_by!(trip:, date:, trip_run_id: trip.runs.find { it.direction == 1 && it.start_time == Clock.minutes(time) }.id, slot_no: slot, part: 1)
    end
    save = ->(attrs, o) { Replacements::Save.call(replacement: Replacement.new, attributes: attrs.merge(reason: "Seed sample app shuttle"), user: admin, occurrence: o) }

    save.({ kind: "drv", driver_id: Driver.find_by!(name: "Daniel Wong").id }, occ.(mbc, day, "07:45", 1))
    save.({ kind: "veh", vehicle_id: bus.("PD5126A").id }, occ.(mbc, day, "08:15", 2))

    after = day + 1
    after += 1 while after.saturday? || after.sunday?
    Occurrences::Edit.new(occ.(cross, after, "14:00", 1), admin).cancel!
  end
end

ConvoyApp::Shuttles::Alerts.call
puts "Convoy App Shuttles: #{account.display_name} rides with #{employer.client.name} (#{AppNotification.where(app_account_id: account.id).count} alerts in the inbox)"
