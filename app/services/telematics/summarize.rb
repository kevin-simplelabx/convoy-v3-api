# A run's driving summary from its GPS pings and stop events: distance, time on the road, odometer, idling away from
# stops, top and average speed, time above the company's speed limit, harsh braking / acceleration, pings, fuel.
# Fuel is estimated from the distance (diesel: 0.32 L/km over 30 seats, else 0.14) unless the device sent it.
module Telematics
  class Summarize < ApplicationService
    MOVING_KMH = 2
    HARSH_KMH_PER_SECOND = 1.8 # speed change faster than this between pings counts as harsh braking or acceleration
    EARTH_KM = 6371.0

    def initialize(occ, odometer_start_km: nil, fuel_used: nil, fuel_unit: nil)
      @occ = occ
      @odometer = odometer_start_km
      @fuel = fuel_used
      @fuel_unit = fuel_unit
    end

    def call
      pts = @occ.positions.order(:recorded_at).pluck(:recorded_at, :lat, :lng, :speed_kmh).map { |t, la, ln, v| [ t, la, ln, v.to_f ] }
      summary = @occ.trip_summary || @occ.build_trip_summary
      return summary.tap(&:save!) if pts.empty?

      limit = @occ.company.speed_limit_kmh
      interval = interval_of(pts)
      km = pts.each_cons(2).sum { |a, b| distance(a, b) }
      moving = pts.map(&:last).select { |v| v > MOVING_KMH }
      dwell = @occ.stop_events.filter_map { |e| e.arrived_at && (e.arrived_at..(e.departed_at || e.arrived_at)) }
      idle = pts.drop(1).count { |t, _, _, v| v < MOVING_KMH && dwell.none? { |r| r.cover?(t) } }
      harsh = pts.each_cons(2).count { |a, b| (b[3] - a[3]).abs / [ (b[0] - a[0]).to_f, 1 ].max > HARSH_KMH_PER_SECOND }
      summary.update!(
        started_at: pts.first[0], ended_at: pts.last[0], distance_km: km.round(2),
        odometer_start_km: @odometer, odometer_end_km: @odometer && (@odometer + km).round,
        idle_seconds: idle * interval, max_speed_kmh: pts.map(&:last).max.round(1),
        avg_moving_speed_kmh: moving.any? ? (moving.sum / moving.size).round(1) : 0, speed_limit_kmh: limit,
        overspeed_seconds: pts.count { |p| p[3] > limit } * interval, harsh_events: harsh, ping_count: pts.size,
        ping_interval_seconds: interval, fuel_used: @fuel || (km * ((@occ.vehicle&.seats || 0) > 30 ? 0.32 : 0.14)).round(2),
        fuel_unit: @fuel_unit || "L", fuel_estimated: @fuel.nil?
      )
      summary
    end

    private

    def interval_of(pts)
      gaps = pts.each_cons(2).map { |a, b| (b[0] - a[0]).round }.sort
      gaps.empty? ? 0 : gaps[gaps.size / 2]
    end

    def distance(a, b)
      r = Math::PI / 180
      dlat = (b[1] - a[1]) * r
      dlng = (b[2] - a[2]) * r
      h = (Math.sin(dlat / 2)**2) + (Math.cos(a[1] * r) * Math.cos(b[1] * r) * (Math.sin(dlng / 2)**2))
      2 * EARTH_KM * Math.asin(Math.sqrt(h))
    end
  end
end
