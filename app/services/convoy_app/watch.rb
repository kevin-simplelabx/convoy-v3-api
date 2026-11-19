# What a Convoy App live screen shows, for its WebSocket subscription (TrackChannel): the runs on it (run_changed) and the
# runs whose bus position it shows (position). Read with the same call as the screen's REST endpoint, so the same access
# rules apply; nil when the person may not see it (404 there).
#   screen         params                                             REST
#   home           —                                                  GET /app/home (Up Next cards)
#   school_live    bus                                                GET /app/school/live (position only in state near)
#   shuttle_route  employer_id, route_id, date, direction, run_id     GET /app/shuttles/:employer_id/routes/:route_id
#   booking_track  booking_id                                         GET /app/bookings/:booking_id/track
#   Watch.call(account:, screen:, params:) → { runs: [occurrence ids], positions: [occurrence ids] } | nil
module ConvoyApp
  module Watch
    SCREENS = %w[home school_live shuttle_route booking_track].freeze

    module_function

    def call(account:, screen:, params:)
      p = params.to_h.with_indifferent_access
      case screen.to_s
      when "home" then home(account)
      when "school_live" then school_live(account, p)
      when "shuttle_route" then shuttle_route(account, p)
      when "booking_track" then booking_track(account, p)
      end
    rescue ActiveRecord::RecordNotFound
      nil
    end

    def home(account)
      cards = Home.call(account:)[:up_next]
      { runs: cards.flat_map { it[:occurrence_ids] || [] }.uniq, positions: [] }
    end

    def school_live(account, p)
      member = HouseholdMember.active.joins(:household).merge(Household.kept).find_by(app_account_id: account.id)
      return unless member

      bus = Parents::Live.call(member:, bus: p[:bus])[:bus]
      runs = [ bus&.dig(:occurrence_id) ].compact
      { runs:, positions: bus&.dig(:position) ? runs : [] }
    end

    def shuttle_route(account, p)
      employer = Shuttles.employer!(account, p[:employer_id])
      page = Shuttles::RoutePage.call(account:, employer:, trip_id: p[:route_id], date: p[:date], direction: p[:direction], run_id: p[:run_id])
      timing = page[:timing]
      runs = page[:timings].flat_map { it[:occurrence_ids] } + (timing ? timing[:buses].map { it[:occurrence_id] } : [])
      { runs: runs.uniq, positions: timing&.dig(:position) ? [ timing[:occurrence_id] ] : [] }
    end

    def booking_track(account, p)
      acc, booking = Bookings.find!(account, p[:booking_id])
      buses = Bookings.within(acc) do
        booking = ::Booking.includes(*Bookings::Present::INCLUDES).find(booking.id)
        Bookings::Track.new(acc, booking, Bookings::Runs.load([ booking ])).call
      end[:trips].flat_map { it[:buses] }
      { runs: buses.map { it[:occurrence_id] }.uniq, positions: buses.select { it[:position] }.map { it[:occurrence_id] }.uniq }
    end
  end
end
