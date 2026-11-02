# After a shuttle is saved: writes each run's stop times, turns the form's group keys into Runs That Move Together
# groups, and stores the price table. Called by Trips::Save inside its transaction.
module Trips
  class Timetable < ApplicationService
    def initialize(trip)
      @trip = trip
    end

    def call
      write_times
      write_groups
      write_price_table
    end

    private

    def runs = @trip.runs.reload

    def write_times
      @trip.kept_runs.select(&:times_input).each do |run|
        stops = @trip.stops_in(run.direction)
        run.times.delete_all
        rows = stops.zip(run.times_input).filter_map do |stop, time|
          { company_id: @trip.company_id, trip_run_id: run.id, trip_stop_id: stop.id, time: } if time
        end
        TripRunTime.insert_all!(rows.map { |r| r.merge(created_at: Time.current, updated_at: Time.current) }) if rows.any?
      end
    end

    # Rebuilt when the form sent group keys: one group per key, slots without a key leave their group.
    def write_groups
      slots = @trip.kept_runs.flat_map { |r| r.slots.reject(&:marked_for_destruction?) }
      return if slots.none? { |s| !s.group_key.nil? }

      TripRunSlot.where(id: slots.map(&:id)).update_all(trip_run_group_id: nil)
      @trip.run_groups.destroy_all
      slots.group_by { |s| s.group_key.presence }.except(nil).each_value do |members|
        next if members.size < 2

        group = @trip.run_groups.create!
        TripRunSlot.where(id: members.map(&:id)).update_all(trip_run_group_id: group.id)
      end
    end

    def write_price_table
      input = @trip.price_cells_input
      return if input.nil?

      by_key = runs.index_by(&:key)
      @trip.price_cells.delete_all
      Array(input).each do |cell|
        amount = cell[:amount].presence or next

        @trip.price_cells.create!(**row(cell[:row].to_s, by_key), slot_no: col(cell[:col].to_s), amount:)
      end
    end

    def row(key, by_key)
      case key
      when "all" then { direction: nil, trip_run: nil }
      when /\Ad([12])\z/ then { direction: ::Regexp.last_match(1).to_i, trip_run: nil }
      when /\Ad[12]r\d+\z/ then { direction: nil, trip_run: by_key.fetch(key) { raise Error, "Price table: no run #{key}" } }
      else raise Error, "Price table: unknown row #{key}"
      end
    end

    def col(key)
      return nil if key == "all"

      n = key.to_i
      raise Error, "Price table: no vehicle #{key}" unless n.between?(1, @trip.vehicles_count)

      n
    end
  end
end
