# Reports > Shuttle Report sample: stop events (arrivals, departures, boardings; no GPS) for the MBC Campus Shuttle runs
# of the last three months that have none, so the report has real rows. Mostly on time, some early, a few late, a
# rare early departure; riders vary by run and day (seeded by the run, so seeds give the same numbers).
with_company("SD") do
  Time.use_zone(ActsAsTenant.current_tenant.timezone) do
    trip = Trip.kept.find_by(label: "seed-mbc-shuttle")
    next unless trip

    runs = TripOccurrence.completed.where(trip:, date: (Date.current << 3)..Date.yesterday).where.not(vehicle_id: nil)
                         .includes(:vehicle, :stop_events, :school_route, trip_run: :times, trip: :stops)
    runs.each do |occ|
      next if occ.stop_events.any?

      stops = TripHistory.planned_stops(occ)
      next if stops.size < 2

      rng = Random.new(occ.id)
      seats = occ.vehicle&.seats || 23
      riders = (seats * (0.25 + (rng.rand * 0.6))).round
      roll = rng.rand
      shift = [ -7, rng.rand(-4..2), rng.rand(4..10) ][roll < 0.1 ? 0 : (roll < 0.85 ? 1 : 2)]
      share = stops[0...-1].map { 0.4 + rng.rand }
      left = riders
      stops.each_with_index do |s, i|
        last = i == stops.size - 1
        boarded = last ? 0 : (i == stops.size - 2 ? left : [ (riders * share[i] / share.sum).round, left ].min)
        left -= boarded
        minute = (s[:planned_minute] || occ.start_time) + shift + i
        at = occ.starts_at + (minute - occ.start_time).minutes
        departed = last ? nil : (rng.rand < 0.05 ? at + 1.minute : [ at + 1.minute, occ.starts_at + ((s[:planned_minute] || occ.start_time) - occ.start_time).minutes ].max)
        occ.stop_events.create!(company_id: occ.company_id, position: s[:position], arrived_at: at, departed_at: departed, boarded:, alighted: last ? riders : 0)
      end
      TripHistory::Punctuality.call(occ)
    end
  end
end
