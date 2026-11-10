# Client Portal › Home: the tiles (Upcoming Trips in the next 30 days with the next one, Changes to Review, Waiting for
# You, Shuttle Runs Today, School Buses Today, Sites), the next upcoming trips, today's shuttle runs with where they are,
# and the notices to riders in force. Everything is limited to what the person may see.
module Portal
  class Home < ApplicationService
    DAYS_AHEAD = 30
    LIST = 6

    def initialize(client_user:, now: Time.current)
      @user = client_user
      @client = client_user.client
      @now = now
      @today = now.to_date
    end

    def call
      trips = upcoming_trips
      shuttles = shuttle_runs
      school = school_runs
      sites = @user.limit_to_sites(@client.sites, :id).to_a
      waiting = waiting_for_you
      {
        tiles: {
          upcoming_trips: { count: trips.size, next: trips.first && { date: trips.first.date, time: trips.first.start_time_hm } },
          changes_to_review: trips.count(&:awaiting_ack?),
          waiting_for_you: (waiting if @user.can?(:approve) || waiting.positive?),
          shuttle_runs_today: (shuttles && { count: shuttles.size, on_road: shuttles.count { RunState.on_road?(it[:state]) }, active_routes: active_routes }),
          school_buses_today: (school && { count: school.size, on_road: school.count { RunState.on_road?(RunState.call(it, @now)) } }),
          sites: (sites.any? && { count: sites.size, own_entity: sites.count(&:own_billing?) }) || nil
        },
        upcoming: trips.first(LIST).map { trip_row(it) },
        shuttles_today: shuttles,
        notices: Notices.call(client_user: @user, now: @now).select { it[:state] == "in_force" }
      }
    end

    private

    def bookings = Pundit.policy_scope!(@user, [ :portal, Booking ])

    def upcoming_trips
      BookingTrip.where(booking: bookings).joins(:day).where(booking_days: { date: @today..(@today + DAYS_AHEAD) })
                 .where.not(status: %w[rejected cancelled]).includes(:day, :points, booking: :client_site)
                 .order("booking_days.date", :start_time).to_a
    end

    def trip_row(t)
      status = BookingStatus.trip(t)
      { id: t.id, booking_id: t.booking_id, booking_number: t.booking.number, site: t.booking.client_site&.name, date: t.date,
        kind: t.kind, kind_name: t.kind_name, start_time: t.start_time_hm, return_time: t.return_time_hm, hours: t.hours&.to_f, pax: t.pax,
        from: t.out_points.first&.name, to: t.out_points.last&.name, status:, status_label: BookingStatus::LABELS.fetch(status) }
    end

    def waiting_for_you
      bookings.where(id: BookingApproval.where(status: "wait").select(:booking_id)).includes(approval: Approval::INCLUDES)
              .count { Approval.new(it.approval).can_decide?(@user) }
    end

    # Today's runs of the client's corporate shuttles on the person's sites (nil when the client has no shuttles).
    def shuttle_runs
      trips = Notices.trips_for(@user).where(kind: "corporate_shuttle")
      return unless Trip.kept.exists?(client_id: @client.id, kind: "corporate_shuttle")

      TripOccurrence.visible.where(date: @today, trip_id: trips.select(:id)).where.not(status: "cancelled")
                    .includes(:stop_events, trip: :client_site).chronological.map do |o|
        state = RunState.call(o, @now)
        { id: o.id, date: o.date, trip_id: o.trip_id, title: o.trip.title, label: o.trip_label, starts_at: o.starts_at, ends_at: o.ends_at,
          site: o.trip.client_site&.name, state:, state_label: RunState::LABELS.fetch(state) }
      end
    end

    # Shuttle routes running today's date range (started, not ended) on the person's sites: "N active routes" when none is on the road.
    def active_routes
      Notices.trips_for(@user).where(kind: "corporate_shuttle").where(starts_on: ..@today).where("ends_on IS NULL OR ends_on >= ?", @today).count
    end

    # Today's School Bus runs of the schools linked to the client or the person's sites (nil when none is linked).
    def school_runs
      ids = ([ @client.school&.id ] + @user.limit_to_sites(@client.sites.where.not(school_id: nil), :id).pluck(:school_id)).compact
      return if ids.empty?

      TripOccurrence.visible.where(date: @today).where.not(status: "cancelled").joins(school_route: :plan)
                    .where(school_plans: { school_id: ids }).includes(:stop_events).to_a
    end
  end
end
