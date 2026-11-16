# Convoy App › Track Buses (HTML bkTrack): every bus of a booking's trips running today, one map. Per bus: number, plate,
# driver (phone on the day only), state "At pick-up since 07:44" (arrived at the first stop, not left) or "On the way ·
# 1.8 km · about 07:56" (on the road: distance and ETA to the next stop), where it is (only while on the road), the
# planned route. Badge "All here" / "x of n here". Only for bookings with a trip on the road today. Inside `within`.
module ConvoyApp
  module Bookings
    class Track
      # { state: here | on_the_way | ended | nil, state_text, since, eta_at, km } of one run now.
      def self.state(occ, now)
        run = ::Portal::RunState.call(occ, now)
        first = occ.stop_events.find { it.position.zero? }
        if first&.arrived_at && !first.departed_at && run != "ended"
          return { state: "here", state_text: "At pick-up since #{first.arrived_at.in_time_zone.strftime('%H:%M')}", since: first.arrived_at, eta_at: nil, km: nil }
        end
        return { state: run == "ended" ? "ended" : nil, state_text: nil, since: nil, eta_at: nil, km: nil } unless ::Portal::RunState.on_road?(run)

        stop = next_stop(occ)
        live = occ.vehicle&.live_position
        if live && stop&.dig(:lat)
          from = [ live.lat.to_f, live.lng.to_f ]
          to = [ stop[:lat].to_f, stop[:lng].to_f ]
          km = (Geo.metres(from, to) / 1000.0).round(1)
          eta = now + LiveMap.eta_minutes(from, to).minutes
          { state: "on_the_way", state_text: "On the way · #{km} km · about #{eta.strftime('%H:%M')}", since: nil, eta_at: eta, km: }
        else
          { state: "on_the_way", state_text: "On the way", since: nil, eta_at: nil, km: nil }
        end
      end

      def self.next_stop(occ)
        events = occ.stop_events.index_by(&:position)
        Occurrences::Stops.planned(occ).find { !(events[it[:position]]&.departed_at || events[it[:position]]&.skipped) }
      end

      def initialize(account, booking, runs, now: Time.current)
        @account = account
        @b = booking
        @runs = runs
        @now = now
        @today = now.to_date
      end

      def call
        trips = @b.trips.select { it.approved? && it.date == @today && @runs.for(it).any? }.sort_by(&:start_time)
        raise ActiveRecord::RecordNotFound if trips.none? { @runs.live?(it) }

        { id: @b.id, number: @b.number, title: @b.title || @b.number, company: { name: @account.tc, ops_phone: @account.company.ops_phone },
          trips: trips.map { trip(it) } }
      end

      private

      def trip(t)
        out = t.out_points
        runs = @runs.for(t).reject(&:cancelled?)
        buses = runs.each_with_index.map { |o, i| bus(o, i + 1) }
        mine = buses.reject { it[:way] == "back" }
        here = mine.count { it[:state] == "here" }
        { booking_trip_id: t.id, kind_label: t.kind_name, live: @runs.live?(t),
          depart: { time: t.start_time_hm, name: out.first&.name }, arrive: { name: out.last&.name },
          return_text: t.two_way? ? "Return leaves #{out.last&.name} at #{t.return_time_hm}" : nil,
          badge: here == mine.size && here.positive? ? "All here" : "#{here} of #{mine.size} here", buses:,
          route: Occurrences::Stops.planned(runs.first).filter_map { [ it[:lat].to_f, it[:lng].to_f ] if it[:lat] && it[:lng] } }
      end

      def bus(o, n)
        info = o.decorate.driver_info
        on_road = ::Portal::RunState.on_road?(::Portal::RunState.call(o, @now))
        live = on_road && o.vehicle&.live_position
        { n:, occurrence_id: o.id, way: o.trip.is_return ? "back" : "there", plate: o.vehicle&.plate,
          desc: o.vehicle && [ o.vehicle.make, o.vehicle.model ].compact.join(" ").presence,
          driver: info && { name: info[:name], photo: info[:photo], phone: info[:phone] },
          position: live ? { lat: live.lat.to_f, lng: live.lng.to_f, heading: live.heading, recorded_at: live.recorded_at } : nil }
          .merge(self.class.state(o, @now))
      end
    end
  end
end
