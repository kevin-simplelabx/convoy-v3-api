# Trip History telematics sample: GPS pings every 10 s, stop events and the driving summary for the latest runs of a
# few trips (straight lines between the stops, a little jitter). One run arrives late, one goes above the speed limit.
# The driver app / telematics send these later. Runs that have a summary already are skipped.
with_company("SD") do
  Time.use_zone(ActsAsTenant.current_tenant.timezone) do
    labels = %w[seed-mbc-shuttle seed-cross-site seed-recurring-staff seed-school-run]
    runs = TripOccurrence.completed.where(date: (Date.current - 14)..Date.yesterday, trip: Trip.kept.where(label: labels))
                         .where.not(vehicle_id: nil).includes(:trip_summary, :vehicle, trip: :stops, trip_run: :times)
                         .order(date: :desc, start_time: :desc).to_a.group_by(&:trip_id).values.flat_map { |list| list.first(3) }

    runs.each_with_index do |occ, n|
      next if occ.trip_summary

      stops = TripHistory.planned_stops(occ).select { |s| s[:lat] && s[:lng] }
      next if stops.size < 2

      late = n == 1 ? 9 : n % 3
      fast = n == 2
      total = [ (occ.end_time - occ.start_time) * 60, 600 ].max
      leg = total / (stops.size - 1)
      t0 = occ.starts_at + late.minutes
      points = []
      events = []
      boarded = 0
      stops.each_with_index do |s, i|
        arrive = t0 + (i * leg).seconds
        dwell = i == stops.size - 1 ? 60 : 60 + (i * 20)
        on = i == stops.size - 1 ? 0 : [ occ.pax / [ stops.size - 1, 1 ].max, 1 ].max
        boarded += on
        events << { position: s[:position], arrived_at: arrive, departed_at: arrive + dwell.seconds, boarded: on,
                    alighted: i == stops.size - 1 ? boarded : 0 }
        next if i == stops.size - 1

        nxt = stops[i + 1]
        steps = [ (leg - dwell) / 10, 1 ].max
        dwell_steps = dwell / 10
        dwell_steps.times { |k| points << { at: arrive + (k * 10).seconds, lat: s[:lat].to_f, lng: s[:lng].to_f, speed_kmh: 0, heading: 0 } }
        km = Math.sqrt(((nxt[:lat].to_f - s[:lat].to_f)**2) + ((nxt[:lng].to_f - s[:lng].to_f)**2)) * 111
        base = (km / (steps * 10 / 3600.0)).clamp(15, 75)
        steps.times do |k|
          f = (k + 1).to_f / steps
          wobble = Math.sin((k + n) / 3.0) * 6
          speed = fast && k.between?(steps / 2, (steps / 2) + 8) ? 88 : (base + wobble).clamp(5, 79)
          points << { at: arrive + (dwell + (k * 10)).seconds, lat: s[:lat].to_f + ((nxt[:lat].to_f - s[:lat].to_f) * f) + (Math.sin(k) * 0.0001),
                      lng: s[:lng].to_f + ((nxt[:lng].to_f - s[:lng].to_f) * f), speed_kmh: speed.round(1), heading: 90 }
        end
      end
      Telematics::Record.call(occ:, positions: points, stop_events: events, odometer_start_km: 48_000 + (occ.vehicle_id * 1371 % 90_000) + (n * 40))
    end
  end
end
