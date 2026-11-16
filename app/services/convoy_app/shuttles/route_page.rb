# Convoy App › Shuttles › a route (the page the list opens): a 14-day strip (no service / changed times / changes), the day's
# banners, the timings of one direction with their state, bus and driver, what changed (another bus, relief driver, cancelled,
# No Fixed Bus), the stops with times, My Stop and the bell, and where the bus is while it runs. Any date from today to today +
# 92 days can be asked (View Schedule picks one); occurrences are real up to the 120-day horizon, there are no virtual runs.
#   RoutePage.call(account:, employer:, trip_id:, date: nil, direction: nil, run_id: nil, now: Time.current)
module ConvoyApp
  module Shuttles
    class RoutePage < ApplicationService
      def initialize(account:, employer:, trip_id:, date: nil, direction: nil, run_id: nil, now: Time.current)
        @account = account
        @employer = employer
        @trip_id = trip_id
        @date = date
        @direction = direction
        @run_id = run_id
        @now = now
      end

      def call
        Shuttles.within(@employer) do
          @today = Time.zone.today
          @trip = Shuttles.trip!(@employer, @trip_id, @today)
          dirs = Shuttles.directions(@trip)
          raise ActiveRecord::RecordNotFound if dirs.empty?

          @usual = UsualOf.for(@account, @employer.client)
          @date = date_param
          @direction = pick_direction(dirs)
          @days = Days.new(@trip, @today, [ @date, @today + STRIP_DAYS - 1 ].max)
          build
        end
      end

      # Shared with Schedule: the pieces both pages show.
      def self.route_json(trip, pinned:, usual:)
        { id: trip.id, name: trip.title, label: trip.label, tags: Shuttles.tags(trip), no_fixed_bus: trip.no_fixed_bus, pinned:,
          directions: Shuttles.direction_list(trip), usual: usual.trip_id == trip.id }
      end

      private

      def date_param
        date = @date.present? ? Date.iso8601(@date.to_s) : @today
        raise Error, "Pick a day from today to #{@today + SCHEDULE_DAYS}" unless date.between?(@today, @today + SCHEDULE_DAYS)

        date
      rescue Date::Error
        raise Error, "Pick a day from today to #{@today + SCHEDULE_DAYS}"
      end

      def pick_direction(dirs)
        wanted = @direction.presence&.to_i
        return wanted if wanted && dirs.include?(wanted)
        raise Error, "This route has no #{Shuttles::DIRECTIONS[wanted].to_s.downcase} direction" if wanted

        @usual.trip_id == @trip.id && dirs.include?(@usual.direction) ? @usual.direction : dirs.first
      end

      def build
        day = @days.day(@date)
        timings = day.state == "no_service" ? [] : Timings.new(@trip, @date, days: @days, now: @now).list(@direction)
        chosen = pick_timing(timings)
        pinned = ShuttlePin.exists?(app_account_id: @account.id, trip_id: @trip.id)
        {
          employer: @employer.json, route: self.class.route_json(@trip, pinned:, usual: @usual),
          today: @today, date: @date, direction: @direction, direction_name: DIRECTIONS.fetch(@direction),
          day: day_json(day), strip: @days.strip.map { strip_json(it) }, next_change: next_change,
          usual: usual_json, timings: timings.map { timing_json(it) }, selected_run_id: chosen&.run&.id,
          timing: chosen && detail(chosen, timings), stops: chosen ? nil : closed_stops
        }
      end

      # given run, else the one on the road, else the next, else the first (HTML shTmPick).
      def pick_timing(timings)
        timings.find { it.run.id == @run_id.to_i } || timings.find { %w[started on_the_way].include?(it.state) } ||
          timings.find { it.state == "scheduled" } || timings.first
      end

      def day_json(day)
        { state: day.state, reason: day.reason, resumes_on: day.resumes_on,
          shifts: day.shifts.map { { direction: it[:direction], name: DIRECTIONS[it[:direction]], minutes: it[:minutes] } } }
      end

      def strip_json(day)
        day_json(day).merge(date: day.date, weekday: day.date.wday, changes: day.changes)
      end

      def next_change
        found = @days.strip(@today + 1, NEXT_CHANGE_DAYS).find { it.state != "service" }
        found && day_json(found).merge(date: found.date)
      end

      def usual_json
        return unless @usual.present? && @usual.trip_id == @trip.id

        run = @trip.runs.find { it.id == @usual.run_id }
        stop = @trip.stops.find { it.id == @usual.stop_id }
        { run_id: @usual.run_id, direction: @usual.direction, time: Shuttles.hm(run.start_time), stop: stop && { id: stop.id, name: stop.name } }
      end

      def timing_json(t)
        first = t.occurrences.first
        { run_id: t.run.id, time: first.start_time_hm, shift_minutes: first.start_time - t.run.start_time, state: t.state,
          state_label: Portal::RunState::LABELS[t.state] || "Cancelled", live: Portal::RunState.on_road?(t.state), past: t.state == "ended",
          usual: @usual.run?(t.run), change: t.change, buses: t.occurrences.size }
      end

      def closed_stops
        @trip.stops_in(@direction).map { { stop_id: it.id, name: it.name_in(@direction), time: nil } }
      end

      def detail(timing, timings)
        occs = timing.occurrences
        lead = occs.find { !it.cancelled? } || occs.first
        planned = Occurrences::Stops.planned(lead)
        stops_list = lead.trip.stops_in(@direction)
        events = lead.stop_events.index_by(&:position)
        live = Portal::RunState.on_road?(timing.state)
        nxt = planned.find { !(events[it[:position]]&.departed_at || events[it[:position]]&.skipped) } if live
        position = live ? lead.vehicle&.live_position : nil
        late = late_minutes(lead, position, nxt)
        {
          run_id: timing.run.id, time: lead.start_time_hm, state: timing.state, state_label: Portal::RunState::LABELS[timing.state] || "Cancelled",
          late_minutes: late, status: status(timing, lead, planned, events, nxt, position, timings),
          buses: buses(timing), stops: stops_json(timing, lead, planned, stops_list, events, nxt),
          line: planned.filter_map { [ it[:lat].to_f, it[:lng].to_f ] if it[:lat] && it[:lng] },
          position: position && { lat: position.lat.to_f, lng: position.lng.to_f, speed_kmh: position.speed_kmh&.round, heading: position.heading, recorded_at: position.recorded_at }
        }
      end

      # The next stop's ETA from the live bus against its planned time (never negative; the app shows it from a few minutes).
      def late_minutes(occ, position, nxt)
        return unless position && nxt && nxt[:lat] && nxt[:lng]

        planned = LiveMap.at_minute(occ, nxt[:planned_minute])
        eta = @now + LiveMap.eta_minutes([ position.lat.to_f, position.lng.to_f ], [ nxt[:lat].to_f, nxt[:lng].to_f ]).minutes
        [ ((eta - planned) / 60).round, 0 ].max
      end

      def status(timing, lead, planned, events, nxt, position, timings)
        first = planned.first
        last = planned.last
        out = { key: timing.state, departs_at: LiveMap.at_minute(lead, first[:planned_minute]) }
        out[:next_stop] = { name: nxt[:name], planned_at: LiveMap.at_minute(lead, nxt[:planned_minute]) } if nxt
        if nxt && position && nxt[:lat] && nxt[:lng]
          out[:next_stop][:eta_at] = @now + LiveMap.eta_minutes([ position.lat.to_f, position.lng.to_f ], [ nxt[:lat].to_f, nxt[:lng].to_f ]).minutes
        end
        out[:arrived] = { stop: last[:name], at: events[last[:position]]&.arrived_at || lead.ended_at } if timing.state == "ended"
        out[:next_bus] = next_bus(timing, timings) if timing.state == "cancelled"
        out
      end

      # The next timing after a cancelled one that still runs: "Next bus 08:40 from <stop>".
      def next_bus(timing, timings)
        after = timings.select { it.run.id != timing.run.id && !%w[cancelled ended].include?(it.state) && it.occurrences.first.start_time > timing.occurrences.first.start_time }
        nxt = after.min_by { it.occurrences.first.start_time } or return
        { run_id: nxt.run.id, time: nxt.occurrences.first.start_time_hm, from: @trip.stops_in(@direction).first.name_in(@direction) }
      end

      def buses(timing)
        regulars = Vehicle.where(id: timing.changes.filter_map { it&.dig(:regular_vehicle_id) }).index_by(&:id)
        relief = relief_names(timing.occurrences)
        alerts = alert_lookup(timing)
        timing.occurrences.zip(timing.changes).map { |occ, change| bus_json(occ, change, regulars, relief, alerts) }
      end

      def bus_json(occ, change, regulars, relief, alerts)
        v = occ.vehicle
        info = occ.decorate.driver_info
        { occurrence_id: occ.id, slot_no: occ.slot_no, part: occ.part, plate: v&.plate, description: v && [ v.make, v.model ].compact.join(" ").presence,
          seats: v&.seats, photo: v&.decorate&.photo_info, no_fixed_bus: @trip.no_fixed_bus,
          driver: info && { name: info[:name], photo: info[:photo], relief: change&.dig(:kind) == "driver", regular_name: relief[occ.id] },
          change: change && change_json(change, occ, regulars, alerts) }
      end

      def change_json(change, occ, regulars, alerts)
        case change[:kind]
        when "cancelled" then { kind: "cancelled", at: change[:at], by: @employer.company.name }
        when "driver" then { kind: "driver", set_at: change[:set_at] }
        else
          regular = regulars[change[:regular_vehicle_id]]
          { kind: "bus", set_at: change[:set_at], **alerts[occ.id].to_h,
            usual_bus: regular && { plate: regular.plate, description: [ regular.make, regular.model ].compact.join(" ").presence, seats: regular.seats } }
        end
      end

      # The regular driver's name for a relief driver.
      def relief_names(occs)
        own = Driver.where(id: occs.filter_map(&:original_driver_id)).index_by(&:id)
        operator = OperatorDriver.where(id: occs.filter_map(&:original_operator_driver_id)).index_by(&:id)
        occs.to_h { |o| [ o.id, (own[o.original_driver_id] || operator[o.original_operator_driver_id])&.name ] }
      end

      # For a bus change: where the rider boards, when they are (or were) told, 1 hour before the bus reaches that stop.
      def alert_lookup(timing)
        stop = rider_stop(timing.occurrences.first) or return {}
        keys = timing.occurrences.to_h { [ it.id, Alerts.key("bus", it) ] }
        sent = AppNotification.where(app_account_id: @account.id, dedupe_key: keys.values).pluck(:dedupe_key, :created_at).to_h
        timing.occurrences.to_h do |occ|
          [ occ.id, { alert: { stop: stop[:name], alert_at: LiveMap.at_minute(occ, stop[:minute]) - Alerts::BUS_LEAD, alerted_at: sent[keys[occ.id]] } } ]
        end
      end

      # The stop riders are told about: the usual boarding stop of this route and direction, else the first belled stop, else the
      # first boarding stop.
      def rider_stop(occ)
        planned = Occurrences::Stops.planned(occ)
        stops = occ.trip.stops_in(@direction)
        bells = bells_by_stop
        pick = (stops.index { @usual.stop_in?(@trip, @direction) && it.id == @usual.stop_id } ||
                stops.index { bells[it.id] == true } || planned.index { it[:use].in?(%w[pu both]) }) or return
        { name: planned[pick][:name], minute: planned[pick][:planned_minute] }
      end

      def bells_by_stop
        @bells ||= ShuttleStopBell.where(app_account_id: @account.id, trip_id: @trip.id, direction: @direction).pluck(:trip_stop_id, :on).to_h
      end

      def stops_json(timing, lead, planned, stops_list, events, nxt)
        bells = bells_by_stop
        mine = @usual.run?(timing.run)
        ended = timing.state == "ended"
        planned.each_with_index.map do |s, i|
          stop = stops_list[i]
          e = events[s[:position]]
          default_bell = @usual.stop_in?(@trip, @direction) && stop.id == @usual.stop_id
          { position: s[:position], stop_id: stop.id, name: s[:name], address: stop.address, planned_time: s[:planned_time],
            planned_at: LiveMap.at_minute(lead, s[:planned_minute]), boarding: s[:use].in?(%w[pu both]), alighting: s[:use].in?(%w[do both]),
            my_stop: mine && default_bell, bell: bells.fetch(stop.id, default_bell), done: ended || !!(e&.departed_at || e&.skipped),
            next: !!(nxt && nxt[:position] == s[:position]), arrived_at: e&.arrived_at, street_view_url: stop.street_view_url,
            lat: s[:lat]&.to_f, lng: s[:lng]&.to_f }
        end
      end
    end
  end
end
