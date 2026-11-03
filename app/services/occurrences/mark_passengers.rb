# Attendance on a run with names (School Bus, School Run), from the Driver app or the Scheduler's Passenger List.
# marks: [{ key, state, method, lat, lng, at }]; state boarded | alighted | not_boarded | not_boarding, or expected to clear
# the mark. A child must be on the run's list. Boarding keeps its first time; alighting boards too when not ticked.
module Occurrences
  class MarkPassengers < ApplicationService
    STATES = (OccurrencePassenger::STATES + %w[expected]).freeze

    def initialize(occ:, marks:, by:, source:)
      @occ = occ
      @marks = Array(marks).map { it.to_h.symbolize_keys }
      @by = by
      @source = source
    end

    def call
      names = roster
      rows = @occ.passenger_marks.where(passenger_key: @marks.map { it[:key].to_s }).index_by(&:passenger_key)
      OccurrencePassenger.transaction do
        @marks.each do |m|
          key = m[:key].to_s
          raise Error.new("#{key} is not on this trip", code: "not_on_trip", details: { key: }) unless names.key?(key)
          raise Error, "Mark boarded, alighted, not_boarded, not_boarding or expected" unless STATES.include?(m[:state].to_s)

          mark(rows[key] || @occ.passenger_marks.build(company_id: @occ.company_id, passenger_key: key), m, names[key])
        end
      end
      @occ.passenger_marks.reset
    end

    private

    def mark(row, m, name)
      state = m[:state].to_s
      return row.destroy! if state == "expected" && row.persisted?
      return if state == "expected"

      at = m[:at] || Time.current
      method = m[:method].presence || "tick"
      row.assign_attributes(name:, state:, marked_by: @by, source: @source)
      case state
      when "boarded"
        row.assign_attributes(boarded_at: row.boarded_at || at, board_method: row.board_method || method, alighted_at: nil, alight_method: nil)
        row.assign_attributes(board_lat: m[:lat], board_lng: m[:lng]) if m[:lat] && row.board_lat.nil?
      when "alighted"
        row.assign_attributes(boarded_at: row.boarded_at || at, board_method: row.board_method || method, alighted_at: at, alight_method: method,
                              alight_lat: m[:lat], alight_lng: m[:lng])
      else row.assign_attributes(boarded_at: nil, board_method: nil, board_lat: nil, board_lng: nil, alighted_at: nil, alight_method: nil)
      end
      row.save!
    end

    # key => name of every child on the run's list.
    def roster
      if @occ.school_route
        rids = @occ.school_route.stops.flat_map { |s| s.riders.map(&:rid) }
        info = SchoolRider.of_school_on(@occ.school_route.plan.school, @occ.date).where(rid: rids).pluck(:rid, :name).to_h
        rids.to_h { [ it, info[it] || it ] }
      elsif @occ.trip&.school_run?
        SchoolRuns::Passengers.call(@occ)[:stops].flat_map { |s| s[:students] }.to_h { [ it[:key], it[:name] ] }
      else {}
      end
    end
  end
end
