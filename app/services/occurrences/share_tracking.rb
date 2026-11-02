# Share Tracking Link (trip drawer): a public link for one run with a snapshot of the trip (stops with pins and times,
# the bus, the driver's first name). One link per run, refreshed on every share; closes 24 hours after the run ends.
module Occurrences
  class ShareTracking < ApplicationService
    def initialize(occurrence, user)
      @occ = occurrence
      @user = user
    end

    def call
      link = TrackingLink.find_or_initialize_by(trip_id: @occ.trip_id, run_date: @occ.date, trip_run_id: @occ.trip_run_id, slot_no: @occ.slot_no)
      link.regenerate_token if link.persisted?
      link.update!(snapshot:, expires_at: @occ.ends_at + TrackingLink::OPEN_AFTER_END, created_by: @user)
      link
    end

    private

    def snapshot
      trip = @occ.trip
      {
        company: trip.company.name, date: @occ.date, start_time: @occ.start_time_hm, end_time: @occ.end_time_hm,
        starts_at: @occ.starts_at, ends_at: @occ.ends_at, trip_label: @occ.trip_label, title: trip.title, kind: trip.kind_name,
        stops: stops(trip), bus: bus, driver: driver_first_name
      }
    end

    # Stops in travel order with the run's times (a shuttle's timetable; else the start at the first stop and the end at the last).
    def stops(trip)
      list = trip.stops_in(@occ.trip_run&.direction || 1)
      times = @occ.trip_run ? @occ.trip_run.stop_minutes.map { |m| m && m + (@occ.start_time - @occ.trip_run.start_time) } : []
      list.each_with_index.map do |s, i|
        t = times[i] || (i.zero? ? @occ.start_time : (i == list.size - 1 ? @occ.end_time : nil))
        { name: s.name, time: Clock.hm(t), use: s.use, lat: s.lat&.to_f, lng: s.lng&.to_f }
      end
    end

    def bus
      v = @occ.vehicle or return nil
      { plate: v.plate, seats: v.seats, picture: v.decorate.default_picture }
    end

    def driver_first_name
      name = @occ.driver&.name || @occ.operator_driver&.name || @occ.driver_name
      name&.split&.first
    end
  end
end
