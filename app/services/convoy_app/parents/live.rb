# Convoy App › Live Tracking (morning bus only, as the HTML): one of the Family's morning buses on the children's next bus day.
# Privacy (decision 2026-11-04): the stop list is four rows at most, the 2 stops before the child's as "Stop N" (no name, no
# place), the child's own stop by name, then the school; only the Family's own children are named; the bus position and the
# line ahead (bus → child's stop → school, never other stops) are sent only from 10 minutes before the bus reaches the
# child's stop until the run ends (state near). Before that a waiting card (state far) with the ETA and crew; ended after.
# ETA = SchoolLive (planned time + lateness from the stops reached and the GPS ETA to the next stop). Live over the
# WebSocket: TrackChannel screen school_live (ConvoyApp::Watch), the position only in state near.
#   Live.call(member:, bus: "<key>" | nil, now:)
module ConvoyApp
  module Parents
    class Live < ApplicationService
      NEAR = 10.minutes
      INCLUDES = [ :driver, :operator_driver, :stop_events, :passenger_marks, { vehicle: :live_position },
                   { school_route: [ :attendant, { plan: :school }, { stops: %i[riders stop_point] }, { vehicle_changes: :vehicle },
                                     { replacements: :vehicle } ] } ].freeze

      def initialize(member:, bus: nil, now: Time.current)
        @household = member.household
        @key = bus.to_s
        @now = now
      end

      def call
        buses = MorningBuses.call(@household).select { it.route && (it.kids.any? || it.off.any?) }
        return { state: "none", buses: [], bus: nil } if buses.empty?

        bus = buses.find { it.key == @key } || buses.find { it.kids.any? } || buses.first
        detail = Parents.within(bus.company) { Detail.new(bus, @now).call }
        detail.merge(buses: buses.map { chip(it) })
      end

      private

      def chip(bus)
        Parents.within(bus.company) do
          { key: bus.key, date: bus.date, names: bus.kids.map { it[:dependant].name }, first_names: bus.names, plate: Detail.vehicle(bus)&.plate,
            warn: Detail.changed?(bus) }
        end
      end

      # One bus, inside its company.
      class Detail
        def self.route(bus) = SchoolRoute.includes(vehicle_changes: :vehicle, replacements: :vehicle).find(bus.route.id)

        def self.occurrence(bus)
          bus.occurrence_id && TripOccurrence.where(id: bus.occurrence_id, date: bus.date).includes(*INCLUDES).first
        end

        # The bus that day: the run's, else a replacement, else the regular one.
        def self.vehicle(bus, occ: occurrence(bus), route: route(bus))
          occ&.vehicle || route.replacement_on(bus.date)&.vehicle || regular(route, bus.date)
        end

        def self.regular(route, date) = route.vehicle_changes.select { it.effective_from <= date }.last&.vehicle

        def self.changed?(bus, occ: occurrence(bus), route: route(bus))
          v = vehicle(bus, occ:, route:)
          r = regular(route, bus.date)
          (v && r && v.id != r.id) || occ&.original_driver_id.present?
        end

        def initialize(bus, now)
          @bus = bus
          @now = now
          @occ = self.class.occurrence(bus)
          @route = @occ&.school_route || SchoolRoute.includes(:attendant, { plan: :school }, { stops: %i[riders stop_point] }, { vehicle_changes: :vehicle },
                                                               { replacements: :vehicle }).find(bus.route.id)
          @school = @route.plan.school
          @run = @occ && bus.today? ? SchoolLive::Run.new(@occ, school: @school, names: {}, absences: {}, now:) : nil
          @stops = @route.stops.to_a
          @index = bus.kids.filter_map { |k| @stops.index { it.id == k[:stop]&.id } }.min ||
                   bus.off.filter_map { |k| @stops.index { it.id == k[:stop]&.id } }.min || 0
        end

        def call
          stop = @stops[@index]
          v = self.class.vehicle(@bus, occ: @occ, route: @route)
          state = self.state
          { state:, bus: { key: @bus.key, occurrence_id: @occ&.id, date: @bus.date, today: @bus.today?, title: @route.title, sub: [ v&.plate, @route.title, "Pick-up" ].compact.join(" · "),
                           company: Parents.company_json(@bus.company), status:, late_minutes: @run&.running? ? @run.late_minutes : 0,
                           vehicle: v && { plate: v.plate, seats: v.seats, model: [ v.make, v.model ].compact_blank.join(" ").presence, size: @route.bus_size(v) },
                           riders: @bus.kids.map { kid(it[:dependant]) }, not_required: @bus.off.map { kid(it[:dependant]) },
                           eta: eta(stop), stops: rows, my_stop: my_stop(stop), crew:, change: change(v),
                           position: state == "near" ? @run.position : nil, path: state == "near" ? path(stop) : nil } }
        end

        # far: waiting card; near: the map (from 10 min before the child's stop until the run ends); ended.
        def state
          return "ended" if @run&.done?
          return "far" unless @run&.running?

          me = @run.stops[@index]
          return "near" if me[:reached]

          at = @run.expected_at(me)
          at && at - @now <= NEAR ? "near" : "far"
        end

        private

        def kid(dep) = { dependant_id: dep.id, name: dep.name, first_name: dep.first_name }

        def status
          return { label: @bus.date.strftime("%a %-d %b"), tone: "neutral" } unless @bus.today?
          return { label: "Ended", tone: "success" } if @run&.done?
          return { label: "Started", tone: "warning" } if @run&.stops&.any? { it[:reached] }
          return { label: "On the way", tone: "warning" } if @occ&.started_at

          { label: "Scheduled", tone: "neutral" }
        end

        def planned_at(s) = s.scheduled_time && (@bus.date.in_time_zone + s.scheduled_time.minutes)

        def eta(stop)
          return nil if @run&.done?

          me = @run&.stops&.dig(@index)
          scheduled = planned_at(stop)
          return { label: "Picked up at #{stop.name}", at: Alerts.hm(me[:arrived_at]), scheduled: Alerts.hm(scheduled), stops_away: 0, picked_up: true } if me&.dig(:reached)

          at = me ? @run.expected_at(me) : scheduled
          next_index = @run ? (@run.next_stop&.dig(:index) || @stops.size) : 0
          away = [ @index - next_index, 0 ].max
          late = @run&.running? ? @run.late_minutes : 0
          text = [ "Scheduled #{Alerts.hm(scheduled)}", "#{away} #{away == 1 ? 'stop' : 'stops'} away", (late.positive? ? "running #{late} min late" : nil) ].compact.join(" · ")
          { label: "ETA at #{stop.name}", at: Alerts.hm(at), scheduled: Alerts.hm(scheduled), stops_away: away, minutes: at && [ ((at - @now) / 60.0).ceil, 0 ].max,
            text:, picked_up: false }
        end

        # Stop N, Stop N, the child's stop, the school.
        def rows
          names = (@bus.kids + @bus.off).select { |k| k[:stop]&.id == @stops[@index]&.id }.map { it[:dependant].first_name }
          before = [ @index - 2, 0 ].max...@index
          list = before.map { |i| row(i, name: "Stop #{i + 1}", meta: nil, mine: false) }
          list << row(@index, name: @stops[@index].name, meta: "#{names.join(' and ').presence || 'No one'} #{names.size == 1 ? 'boards' : 'board'} here", mine: true)
          list << { name: @school.name, meta: "Arrive", time: Alerts.hm(@run ? @run.end_at : @occ&.ends_at || planned_end), state: @run&.done? ? "departed" : "upcoming",
                    mine: false, school: true }
        end

        def planned_end = @route.end_time && (@bus.date.in_time_zone + @route.end_time.minutes)

        def row(i, name:, meta:, mine:)
          s = @run&.stops&.dig(i)
          state = if s.nil? then "upcoming"
          elsif s[:left] || @run.done? then "departed"
          elsif s[:reached] then "at_stop"
          elsif @run.next_stop&.dig(:index) == i then "next"
          else "upcoming"
          end
          time = s&.dig(:arrived_at) || (s ? @run.expected_at(s) : planned_at(@stops[i]))
          { name:, meta:, time: Alerts.hm(time), state:, mine:, school: false }
        end

        def my_stop(stop)
          point = stop.stop_point
          { name: stop.name, note: point&.description, lat: stop.lat&.to_f, lng: stop.lng&.to_f, photo: point&.decorate&.photo_info,
            street_view_url: point&.street_view_url }
        end

        def crew
          driver = @occ&.driver || @occ&.operator_driver
          list = []
          list << { role: "Driver", name: driver.name, phone: driver.phone, relief: @occ.original_driver_id.present? } if driver
          list << { role: "Bus Attendant", name: @route.attendant.name, phone: @route.attendant.phone, relief: false } if @route.attendant
          list
        end

        # "Not the usual bus or crew": the bus or the driver differs from the regular one.
        def change(vehicle)
          regular = self.class.regular(@route, @bus.date)
          bus = vehicle && regular && vehicle.id != regular.id
          relief = @occ&.original_driver_id.present? && (@occ.driver || @occ.operator_driver)
          return nil unless bus || relief

          parts = []
          parts << "a different bus, #{vehicle.plate} instead of #{regular.plate}" if bus
          if relief
            was = Driver.find_by(id: @occ.original_driver_id)&.name
            parts << "a relief driver, #{(@occ.driver || @occ.operator_driver).name}#{" covering for #{was}" if was}"
          end
          { title: "Not the usual bus or crew", text: "Today #{parts.join(', and ')}. Pick-up time is the same." }
        end

        # The line ahead: bus → the child's stop (until reached) → school. No other stop is sent.
        def path(stop)
          pos = @run.position or return nil
          me = @run.stops[@index]
          [ [ pos[:lat].to_f, pos[:lng].to_f ], (me[:reached] ? nil : [ stop.lat&.to_f, stop.lng&.to_f ]), [ @school.lat&.to_f, @school.lng&.to_f ] ]
            .compact.reject { it.include?(nil) }
        end
      end
    end
  end
end
