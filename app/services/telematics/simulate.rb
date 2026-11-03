# Sample live data for the Live Map until the driver app and trackers send real pings (seed, `bin/rails live_map:simulate`;
# never in production, except staging with SAMPLE_DATA=1). Gives every bus of the current company a device, then writes
# "now": a bus on a run gets GPS points from the run's start to now along its stops (straight lines) and the stops it has
# passed; other buses report from where their last run ended or the next one starts; two buses with nothing to do today
# went offline 1 and 5 days ago.
# Ops Control cases: drivers of today's runs are logged in to the app (every 4th with a run soon is not), runs in progress
# were started by the driver (every 4th started 6 min late, every 5th lost GPS 5 min ago), and for a run starting within
# 20 min every 3rd bus is on its way (started) while the others wait at the first pick-up, not started.
# Running it again redoes the runs in progress from their start, so it is safe to repeat.
module Telematics
  class Simulate < ApplicationService
    EVERY = 20 # seconds between sample points
    DEPOT = [ 1.3521, 103.8198 ].freeze
    PHONES = [ "Google Pixel 7", "Samsung Galaxy A54", "Google Pixel 6a" ].freeze
    TRACKER = "OTW GPS T-8 tracker".freeze

    def initialize(now: Time.current)
      @now = now
    end

    def call
      raise Error, "Sample live data is not for production" if Rails.env.production? && ENV["SAMPLE_DATA"] != "1"

      vehicles = Vehicle.kept.includes(:tracking_devices).order(:plate).to_a
      runs = LiveMap.runs_around(vehicles.map(&:id), @now).group_by(&:vehicle_id)
      idle = vehicles.reject { |v| runs[v.id]&.any? { |o| o.date == @now.to_date } }
      offline = idle.last(2).map(&:id)
      sign_in_drivers(runs.values.flatten)
      vehicles.each_with_index do |v, i|
        device = device_for(v, i)
        list = runs[v.id] || []
        if (occ = LiveMap.run_now(list, @now)) then drive(occ, device, i)
        elsif (k = offline.index(v.id)) then went_offline(device, i, k)
        else park(v, device, list, i)
        end
      end
    end

    private

    def device_for(v, i)
      v.tracking_devices.first || TrackingDevice.create!(
        vehicle: v, kind: i % 3 == 1 ? "driver_app" : "gps_tracker", name: i % 3 == 1 ? PHONES[i % PHONES.size] : TRACKER,
        identifier: "SEED-#{v.plate}", report_interval_seconds: i % 3 == 1 ? 15 : 10
      )
    end

    # Today's drivers in the app: signed in this morning, except every 4th whose next run starts within 30 min (last seen
    # yesterday evening).
    def sign_in_drivers(runs)
      today = runs.select { |o| o.date == @now.to_date }
      keys = today.filter_map { |o| o.driver_id ? [ :driver_id, o.driver_id ] : (o.operator_driver_id && [ :operator_driver_id, o.operator_driver_id ]) }.uniq
      return if keys.empty?

      keys.map { |col, id| DriverAppSession.where(col => id) }.reduce(:or).where(signed_in_at: @now.beginning_of_day..).delete_all
      yesterday = @now.beginning_of_day - 1.day
      keys.each_with_index do |(col, id), n|
        DriverAppSession.find_or_create_by!(col => id, signed_in_at: yesterday + 5.75.hours) { it.signed_out_at = yesterday + 18.5.hours }
        soon = today.find { |o| o.public_send(col) == id && o.starts_at > @now && o.starts_at <= @now + 30.minutes }
        next if soon && n % 4 == 1

        DriverAppSession.create!(col => id, signed_in_at: [ @now.beginning_of_day + 5.75.hours, @now - 1.hour ].min, last_seen_at: @now)
      end
    end

    # A run in progress: points every EVERY seconds from its start to now, and the stops reached so far.
    def drive(occ, device, i)
      stops = TripHistory.planned_stops(occ).select { |s| s[:lat] && s[:lng] }
      return park(occ.vehicle, device, [], i) if stops.size < 2
      return approach(occ, device, stops.first, i) if @now < occ.starts_at

      late = i % 4 == 2 ? 6.minutes : 0
      gps_lost = i % 5 == 3
      Occurrences::DriverProgress.call(occ, :start, at: occ.starts_at + late - 2.minutes) unless occ.started_at
      total = occ.ends_at - occ.starts_at
      leg = total / (stops.size - 1)
      dwell = [ 40, leg / 4 ].min
      Occurrences::Partitions.ensure!(occ.date, occ.date)
      occ.positions.delete_all
      occ.stop_events.delete_all
      points = []
      t0 = occ.starts_at + late
      t = t0
      upto = gps_lost ? @now - 5.minutes : @now
      while t < upto
        k = [ ((t - t0) / leg).floor, stops.size - 2 ].min
        into = t - t0 - (k * leg)
        a = stops[k]
        b = stops[k + 1]
        f = into < dwell ? 0.0 : ((into - dwell) / (leg - dwell)).clamp(0, 1)
        speed = f.zero? ? 0 : (28 + ((i * 7 + k * 13) % 23) + (Math.sin(t.to_i / 60.0) * 5)).round(1)
        points << { occurrence_id: occ.id, occurrence_date: occ.date, company_id: occ.company_id, recorded_at: t,
                    lat: lerp(a[:lat], b[:lat], f), lng: lerp(a[:lng], b[:lng], f), speed_kmh: speed, heading: heading(a, b) }
        t += EVERY
      end
      OccurrencePosition.insert_all!(points) if points.any?
      stops.each_with_index do |s, k|
        arrive = t0 + (k * leg)
        break if arrive > @now

        depart = arrive + dwell
        last = k == stops.size - 1
        occ.stop_events.create!(position: s[:position], stop_name: s[:name], arrived_at: arrive, departed_at: depart <= @now && !last ? depart : nil,
                                boarded: last ? 0 : [ occ.pax / (stops.size - 1), 1 ].max, alighted: 0)
      end
      last = points.last || { lat: stops.first[:lat].to_f, lng: stops.first[:lng].to_f, speed_kmh: 0, heading: 0 }
      ping(device, gps_lost ? upto : @now - 3.seconds, last[:lat], last[:lng], last[:speed_kmh], last[:heading], i)
    end

    # Started early, driving to the first pick-up: a little further away the longer it is to the pick-up time.
    def approach(occ, device, first, i)
      Occurrences::DriverProgress.call(occ, :start, at: @now - 4.minutes) unless occ.started_at
      off = (((occ.starts_at - @now) / 1200.0).clamp(0.1, 1.5) * 0.02).round(5)
      ping(device, @now - 3.seconds, first[:lat].to_f + off, first[:lng].to_f + off, 35, 225, i)
    end

    # Not on a run: reporting from where the last run ended, or the next run's first stop, or the depot. Every 3rd bus with
    # a run within 20 min has started it and is on its way.
    def park(v, device, list, i)
      done = list.reverse.find { |o| o.ends_at <= @now }
      nxt = list.find { |o| o.starts_at > @now }
      if nxt && i % 3 == 0 && nxt.starts_at <= @now + 20.minutes && (first = TripHistory.planned_stops(nxt).find { |s| s[:lat] })
        return approach(nxt, device, first, i)
      end

      spot = (done && TripHistory.planned_stops(done).reverse.find { |s| s[:lat] }) || (nxt && TripHistory.planned_stops(nxt).find { |s| s[:lat] })
      ll = spot ? [ spot[:lat].to_f, spot[:lng].to_f ] : [ DEPOT[0] + ((v.id % 7) * 0.012) - 0.04, DEPOT[1] + ((v.id % 5) * 0.02) - 0.05 ]
      ping(device, @now - (5 + (i % 40)).seconds, ll[0], ll[1], 0, 0, i)
    end

    def went_offline(device, i, k)
      at = (@now.to_date - (k.zero? ? 1 : 5)).in_time_zone.change(hour: k.zero? ? 18 : 17, min: k.zero? ? 42 : 5)
      VehicleLivePosition.where(vehicle_id: device.vehicle_id).delete_all
      ping(device, at, DEPOT[0] + (k * 0.03), DEPOT[1] - (k * 0.05), 0, 0, i)
    end

    def ping(device, at, lat, lng, speed, heading, i)
      Ping.call(device:, at:, lat:, lng:, speed_kmh: speed, heading:, battery_pct: 62 + ((i * 17) % 35),
                gps_signal: %w[good good fair good poor][i % 5], gsm_bars: 2 + (i % 3))
    end

    def lerp(a, b, f) = (a.to_f + ((b.to_f - a.to_f) * f)).round(6)

    def heading(a, b)
      (Math.atan2(b[:lng].to_f - a[:lng].to_f, b[:lat].to_f - a[:lat].to_f) * 180 / Math::PI).round % 360
    end
  end
end
