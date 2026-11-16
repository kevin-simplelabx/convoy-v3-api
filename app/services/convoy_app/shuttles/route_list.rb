# Convoy App › Shuttles: the employer's routes (pinned first), the tag chips, My Usual Shuttle and the employer switch.
# A route's tags = the client's site names on its stops + the trip's route_tags. Each card says Now / Next / Done for today from
# today's runs (company time zone): a run on the road is Now, else the next one to start, Done when all have ended or were
# cancelled, none when nothing runs today.
#   RouteList.call(account:, employer_id: nil, tag: nil, now: Time.current)
module ConvoyApp
  module Shuttles
    class RouteList < ApplicationService
      ALL = "All".freeze
      PINNED = "Pinned".freeze

      def initialize(account:, employer_id: nil, tag: nil, now: Time.current)
        @account = account
        @employer_id = employer_id
        @tag = tag.presence || ALL
        @now = now
      end

      def call
        employers = Shuttles.employers(@account)
        employer = @employer_id.present? ? employers.find { it.id == @employer_id.to_i } || raise(ActiveRecord::RecordNotFound) : employers.first
        return { employers: [], employer: nil, usual: nil, tags: [], tag: @tag, routes: [] } unless employer

        Shuttles.within(employer) do
          today = Time.zone.today
          trips = Shuttles.trips(employer, today).to_a.select { Shuttles.directions(it).any? }
          pins = ShuttlePin.where(app_account_id: @account.id).pluck(:trip_id)
          usual = UsualOf.for(@account, employer.client)
          today_runs = runs_today(trips, today)
          cards = trips.map { card(it, pins.include?(it.id), usual, today_runs[it.id] || []) }
          { employers: employers.map(&:json), employer: employer.json, usual: usual_json(usual, trips), tags: chips(cards), tag: @tag,
            routes: filter(cards).sort_by { [ it[:pinned] ? 0 : 1, it[:name].downcase, it[:id] ] } }
        end
      end

      private

      def chips(cards) = [ ALL, PINNED ] + cards.flat_map { it[:tags] }.uniq.sort_by(&:downcase)

      def filter(cards)
        case @tag
        when ALL then cards
        when PINNED then cards.select { it[:pinned] }
        else cards.select { |c| c[:tags].any? { it.casecmp?(@tag) } }
        end
      end

      def runs_today(trips, today)
        TripOccurrence.where(trip_id: trips.map(&:id), date: today).visible.includes(:stop_events).order(:starts_at).to_a.group_by(&:trip_id)
      end

      def card(trip, pinned, usual, runs)
        { id: trip.id, name: trip.title, label: trip.label, tags: Shuttles.tags(trip), pinned:, no_fixed_bus: trip.no_fixed_bus,
          directions: Shuttles.directions(trip).map { summary(trip, it) }, now: now_text(runs),
          usual: usual.trip_id == trip.id ? usual_line(trip, usual) : nil }
      end

      # "Morning 06:20 to 09:00 · 3 timings".
      def summary(trip, direction)
        runs = trip.runs.select { it.direction == direction }
        { direction:, name: DIRECTIONS.fetch(direction), timings: runs.size, first: Shuttles.hm(runs.map(&:start_time).min), last: Shuttles.hm(runs.map(&:start_time).max) }
      end

      def now_text(runs)
        return { state: "none" } if runs.empty?

        live = runs.find { Portal::RunState.on_road?(Portal::RunState.call(it, @now)) }
        return { state: "now", time: live.start_time_hm } if live

        coming = runs.find { !it.cancelled? && Portal::RunState.call(it, @now) == "scheduled" }
        coming ? { state: "next", time: coming.start_time_hm } : { state: "done" }
      end

      def usual_line(trip, usual)
        run = trip.runs.find { it.id == usual.run_id }
        stop = trip.stops.find { it.id == usual.stop_id }
        { time: Shuttles.hm(run.start_time), stop: stop&.name }
      end

      def usual_json(usual, trips)
        trip = trips.find { it.id == usual.trip_id }
        return unless usual.present? && trip

        { trip_id: trip.id, route: trip.title, direction: usual.direction, run_id: usual.run_id, stop_id: usual.stop_id, **usual_line(trip, usual) }
      end
    end
  end
end
